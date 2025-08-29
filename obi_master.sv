// OBI Master v1 (v2 in progress)
// Performs a single read/write to a subordinate/slave.
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
   input logic req_i, 
   input logic we_i,
   input logic [ADDR_WIDTH-1:0] addr_i,
   output logic [DATA_WIDTH-1:0] rsp_o,
   // Data -> Master
   input  logic [DATA_WIDTH-1:0] wdata_i,

   //// Channel signals
   /// A channel
   // TODO: Change this to use OBI interfaces
   output logic obi_req_o,
   input  logic obi_gnt_i,
   output logic [ADDR_WIDTH-1:0] obi_addr_o,
   output logic obi_we_o,
   output logic [DATA_WIDTH/8-1:0] obi_be_o,
   // Master -> OBI
   output logic [DATA_WIDTH-1:0] obi_wdata_o,
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
   input logic obi_rvalid_i,
   output logic obi_rready_o,  
   input logic [DATA_WIDTH-1:0] obi_rdata_i,
   input logic obi_err_i
   /* stubs - optional signals
   input logic [RUSER_WIDTH-1:0] obi_ruser_i,
   input logic [ID_WIDTH-1:0] obi_rid_i,
   input logic obi_exokay_i,
   // Odd Parity signals
   output logic obi_rvalidpar_o,
   output logic obi_rreadypar_o,
   input logic [RCHK_WIDTH-1:0] obi_rchk_i */

);

/// Error counter;

logic [7:0] err_cnt;

/// Necessary regs & wires

logic [ADDR_WIDTH-1:0] addr_q;
logic [DATA_WIDTH-1:0] rdata_q, rdata_d;
logic [DATA_WIDTH-1:0] wdata_q;

/// Tied off signals (R-26)

assign obi_be_o = 4'b1111; 
//assign obi_auser_o = 'b0;
//assign obi_aid_o = 'b0;
//assign obi_wuser_o = 'b0;
//assign obi_prot_o = 3'b111;
//assign obi_memtype_o = 2'b0;
//assign obi_atop_o = 'b0;

/// State definitions

typedef enum logic [2:0] {
    RESET     = 3'b001,
    IDLE      = 3'b000,
    READ_REQ  = 3'b010,
    READ_GNT  = 3'b011,
    WRITE_REQ = 3'b100,
    WRITE_GNT = 3'b101
} statetype;

statetype state, nextstate;

/// Reset and next-state logic
always_ff @(posedge clk_i or negedge reset_ni) begin
    if (!reset_ni) begin
        state <= RESET;
        rdata_q <= '0;
    end
    else begin
        state <= nextstate;
        // Sampled and sent on clk'
        addr_q <= addr_i;
        wdata_q <= wdata_i; 
        rdata_q <= rdata_d; 
    end
end

always_comb begin 
    // default state
    rdata_d = '0;
    case(state)
        RESET: 
           nextstate = IDLE;
        IDLE:
           if (!we_i && req_i) nextstate = READ_REQ;
           else if (we_i && req_i) nextstate = WRITE_REQ;
           else nextstate = IDLE;
        READ_REQ:
           if (obi_gnt_i) nextstate = READ_GNT;
           else nextstate = READ_REQ;
        READ_GNT:
           if(obi_rvalid_i) begin
               nextstate = IDLE;
               rdata_d = obi_rdata_i;
           end
           else nextstate = READ_GNT;
        WRITE_REQ:
           if (obi_gnt_i) nextstate = WRITE_GNT;
           else nextstate = WRITE_REQ;
        WRITE_GNT:
           nextstate = IDLE;
        default:
           nextstate = RESET;
    endcase
end
/// Output logic

/// TODO: Add a FIFO Queue for outstanding transactions
/// TODO: Integrate optional A-Atomic bus if selected in opt config
/// ETHZ common cells and OBI Main Repo

assign obi_req_o = (state == READ_REQ) || (state == WRITE_REQ);
assign obi_we_o = (state == WRITE_REQ);
assign obi_rready_o = (state == IDLE) || ( state == READ_GNT) || ( state == WRITE_GNT);
//wdata, rdata and addr signals are synced to clock'.
assign obi_wdata_o = wdata_q;
assign obi_addr_o = addr_q;
assign rsp_o = rdata_q;

endmodule
