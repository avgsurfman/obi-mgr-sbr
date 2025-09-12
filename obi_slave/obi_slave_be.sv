// OBI Byte-enabled Slave v2
// Fetches or writes data to its SRAM. 
// This slave has byte-aligned memory and allows to set
// byteenable (obi_be_i) to fetch half-words or single bytes.
// CC Franciszek Moszczuk and IHP Microelectronics GmbH.
// Licensed under Apache 2.0 License.
//    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣶⣶⣶⣿⡆
//    ⣶⣶⣶⣶⣶⣶⣶⣶⣶⡎⠉⠉⠉⢹⣇
//    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣀⣀⣤⡜⠋
//    ⣿⣿⡟⠻⡟⣼⣿⣿⣿⣿⣿⣿⣿⡇⠀
//    ⣿⣿⢳⣶⢱⢟⡛⣟⣩⣭⣽⡻⣿⡇⠀
//    ⣿⡏⣾⡏⢪⣾⡇⡿⠿⢟⣫⠵⣛⡅⠀
//    ⣿⣷⣙⠷⢿⣟⣓⣯⢨⣷⣾⣿⣿⡇⠀
//    ⣿⣿⣿⣿⣿⣿⣿⣟⣼⣿⣿⣿⣿⡇⠀
module obi_slave_be#(
   /// Adress Width Parameter. Can be either 32-bit or 64-bit.
   parameter int unsigned ADDR_WIDTH = 32, 
   /// Data Width Parameter. Can be either 32-bit or 64-bit.
   parameter int unsigned DATA_WIDTH = 32,
   /// Optional parameters for additional inputs in Adress phase. Currently stubs.
   parameter int unsigned AUSER_WIDTH = 0,
   parameter int unsigned WUSER_WIDTH = 0,
   parameter int unsigned RUSER_WIDTH = 0,
   parameter int unsigned ID_WIDTH = 0,
   parameter int unsigned ACHK_WIDTH = 0,
   parameter int unsigned RCHK_WIDTH = 0,
   parameter bit COMB_GNT = 0
) (//// Global signals.
   input logic clk_i,
   input logic reset_ni,

   //// Controller signals
   //input logic busy_i;

   //// Channel signals
   /// A channel
   // TODO: Change this to use OBI interfaces
   input logic obi_req_i,
   output  logic obi_gnt_o,
   input logic [ADDR_WIDTH-1:0] obi_addr_i,
   
   input logic obi_we_i,
   input logic [DATA_WIDTH/8-1:0] obi_be_i,
   input logic [DATA_WIDTH-1:0] obi_wdata_i,
   
   /// stubs - optional signals
   //Input logic [AUSER_WIDTH-1:0] obi_auser_i,
   //Input logic [WUSER_WIDTH-1:0] obi_wuser_i,
   //Input logic [ID_WIDTH-1:0] obi_aid_i,
   //Input logic [5:0] obi_atop_i,
   //Input logic [1:0] obi_memtype_i,
   //Input logic [2:0] obi_prot_i,
   /// Odd Parity signals
   //input logic obi_reqpar_i,
   //output logic obi_gntpar_o,
   //input logic [ACHK_WIDTH-1:0] achk_i,
   
   /// R Channel signals 
   output logic obi_rvalid_o,
   input logic obi_rready_i,  
   output logic [DATA_WIDTH-1:0] obi_rdata_o,
   output logic obi_err_o
   /// stubs - optional signals
   //output logic [RUSER_WIDTH-1:0] obi_ruser_i,
   //output logic [ID_WIDTH-1:0] obi_rid_i,
   //output logic obi_exokay_i,
   // Odd Parity signals
   //input logic obi_rvalidpar_i,
   //input logic obi_rreadypar_i,
   //output logic [RCHK_WIDTH-1:0] obi_rchk_i

);

localparam MEM_WIDTH=6; 

/// Necessary regs and wires

logic [ADDR_WIDTH-1:0] addr_q;
logic mem_we;
logic out_of_range;

/// Memory
// 64 words (32-bit), the following should resolve
// to your technology of choice (e.g. RM_IHPSG13_2P_64x32_c2)
//logic [ADDR_WIDTH-1:0] mem [2**MEM_WIDTH-1:0];
//multipacked array go
logic [1:0][1:0][7:0] mem[2**MEM_WIDTH-1:0];

always_ff@(posedge clk_i) begin 
    // Unfortunately implicit bit truncation will crash your simulation,
    // hence the 7 constant. Beware.
 
    if(mem_we) mem[obi_addr_i[7:2]] <= obi_wdata_i;
    /*case(obi_be_i)
    4'b1111: mem[obi_addr_i[ADDR_WIDTH:2]] <= obi_wdata_i; // lw
    4'b1110: mem[obi_addr_i[7:2] [{obi_addr_i[1]}]
    4'b0111: mem[obi_addr_i[7:2] ]
    4'b1100: mem[obi_addr_i[ADDR_WIDTH:2]] [a[1]] //lh
    4'b0110: mem[]
    4'b0011:
    4:b1000
    4:b0100
    4:b0010
    4:00001
    4'b0000*/
end

/// Chip-enable registers

always_ff@(posedge clk_i or negedge reset_ni) begin
    if(!reset_ni) begin
        addr_q <= '0;
    end
    else if(obi_req_i) begin
        addr_q <= obi_addr_i; 
    end
end

/// Tied off signals (R-26)


/// State definitions

typedef enum logic [1:0] {
    RESET     = 2'b11,
    IDLE      = 2'b00,
    READ  = 2'b10,
    WRITE  = 2'b01
} statetype;

statetype state, nextstate;

always_ff@(posedge clk_i or negedge reset_ni) begin
    if(!reset_ni) begin
        state <= RESET;
    end
    else begin
        state <= nextstate;
    end
end

always_comb begin
    obi_rdata_o = 'b0;
    obi_err_o = 1'b0;
    mem_we = 'b0;
    case(state)
        RESET:
           nextstate = IDLE;
        IDLE:
           if(!obi_we_i && obi_req_i) begin
                nextstate = READ;
                //Capture incoming data on next clk edge
           end
           else if(obi_we_i && obi_req_i) begin
                nextstate = WRITE;
                //Capture incoming data on next clk edge  
                mem_we = 1'b1; 
           end
           else nextstate = IDLE;
       READ: begin
           obi_rdata_o = mem[obi_addr_i[ADDR_WIDTH-1:0]];
           if (obi_rready_i) nextstate = IDLE;
           else nextstate = READ;
           end
       WRITE: begin
           if(obi_rready_i) begin
               nextstate = IDLE;
               mem_we = 1'b0;
           end
           else nextstate = WRITE;
       end
    endcase
end
    assign obi_gnt_o = (state == IDLE);
    assign obi_rvalid_o = (state != IDLE); 
endmodule
