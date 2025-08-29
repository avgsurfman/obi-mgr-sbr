// OBI Slave v1
// Fetches or writes data to its SRAM.
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
module obi_master#(
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
   input logic busy_i;

   //// Channel signals
   /// A channel
   // TODO: Change this to use OBI interfaces
   input logic obi_req_i,
   output  logic obi_gnt_o,
   input logic [ADDR_WIDTH-1:0] obi_addr_i,
   
   input logic obi_we_i,
   input logic [DATA_WIDTH/8-1:0] obi_be_i,
   input logic [DATA_WIDTH-1:0] obi_wdata_i,
   
   /* stubs - optional signals
   output logic [AUSER_WIDTH-1:0] obi_auser_o,
   output logic [WUSER_WIDTH-1:0] obi_wuser_o,
   output logic [ID_WIDTH-1:0] obi_aid_o,
   output logic [5:0] obi_atop_o,
   output logic [1:0] obi_memtype_o,
   output logic [2:0] obi_prot_o,
   // Odd Parity signals
   output logic obi_reqpar_o,
   input logic obi_gntpar_i,
   output logic [ACHK_WIDTH-1:0] achk,
   */
   
   /// R Channel signals 
   output logic obi_rvalid_o,
   input logic obi_rready_i,  
   output logic [DATA_WIDTH-1:0] obi_rdata_o,
   output logic obi_err_o
   /* stubs - optional signals
   input logic [RUSER_WIDTH-1:0] obi_ruser_i,
   input logic [ID_WIDTH-1:0] obi_rid_i,
   input logic obi_exokay_i,
   // Odd Parity signals
   output logic obi_rvalidpar_o,
   output logic obi_rreadypar_o,
   input logic [RCHK_WIDTH-1:0] obi_rchk_i */

);

/// Necessary regs and wires

logic [DATA_WIDTH-1:0] addr_q, addr_q;
logic [DATA_WIDTH-1:0] wdata_q, addr_q;



/// Memory

logic [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];

/// Tied off signals (R-26)


/// State definitions

typedef enum logic [1:0] {
    RESET     = 2'b11,
    IDLE      = 2'b00,
    READ  = 2'b10,
    WRITE  = 2'b01,
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

always_comb
    case(state)
        RESET:
            obi_rvalid_o = 0;
            nextstate = state;
        IDLE:
           if(!obi_we_i && obi_req_i) begin
                nextstate = READ;
                //Capture incoming data on next clk edge
           end
           else if(obi_we_i && obi_req_i) begin
                nextstate = WRITE;
                //Capture incoming data on next clk edge  
           end
           else nextstate = IDLE;
       READ:
           if(obi_rready_i) nextstate = IDLE;
           else nextstate = READ;
       WRITE:
           if(obi_rready_i) nextstate = IDLE;
           else nextstate = WRITE;
    endcase


endmodule;
