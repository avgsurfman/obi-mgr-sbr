// obi_slave_be
// OBI Byte-enabled Slave v2.5
// Fetches or writes data to its SRAM. 
// This slave has word-aligned memory. Supports single byte writes.
// Set byteenable (obi_be_i) to load/store half-words or single bytes.
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

`include "mem_waligned.sv"

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
logic [DATA_WIDTH-1:0] rdata_q;
logic [DATA_WIDTH-1:0] wdata_q;
logic [DATA_WIDTH/8-1:0] be_q;
logic mem_we;

/// Memory
// 64 words (32-bit), see mem_waligned.sv for details

mem_waligned_32 #(
    .MEM_WIDTH (6)
) mem ( 
    .clk (clk_i), 
    .reset (reset_ni), 
    .we(mem_we),   // FSM-signal
    .be(be_q), // all 3 sampled on clk' 
    .a (addr_q),   
    .wd(wdata_q),
    .rd(rdata_q),
    .err(obi_err_o) 
); 

/// Chip-enable registers

logic chip_en;

assign chip_en = obi_req_i | obi_gnt_o;

always_ff@(posedge clk_i or negedge reset_ni) begin
    if(!reset_ni) begin
        addr_q <= '0;
    end
    else if(chip_en) begin
        addr_q <= obi_addr_i; 
    end
end

always_ff@(posedge clk_i or negedge reset_ni) begin
    if(!reset_ni) begin
        wdata_q <= '0;
    end
    else if(chip_en) begin
        wdata_q <= obi_wdata_i; 
    end
end


always_ff@(posedge clk_i or negedge reset_ni) begin
    if(!reset_ni) begin
        be_q <= '0;
    end
    else if(chip_en) begin
        be_q <= obi_be_i; 
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

/// Three block Moore FSM

always_ff@(posedge clk_i or negedge reset_ni) begin
    if(!reset_ni) begin
        state <= RESET;
    end
    else begin
        state <= nextstate;
    end
end

always_comb begin : nextstate_comb
    obi_rdata_o = 0;
    mem_we = 'b0;
    case(state)
        RESET:
           nextstate = IDLE;
        IDLE:
           if(!obi_we_i && obi_req_i) begin
                nextstate = READ;
                //Capture incoming data on the next clk edge
           end
           else if(obi_we_i && obi_req_i) begin
                nextstate = WRITE;
                //Capture incoming data on the next clk edge  
                mem_we = 1'b1; 
           end
           else nextstate = IDLE;
       READ: begin
           obi_rdata_o = rdata_q;
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
