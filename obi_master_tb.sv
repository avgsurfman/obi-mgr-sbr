`include "obi_master.sv"
`timescale 1ns / 1ps

module obi_master_tb();


localparam ADDR_WIDTH = 32;
localparam DATA_WIDTH = 32;

logic clk_i;
logic reset_ni;

//// Controller signals
logic req_i; 
logic we_i;
logic [ADDR_WIDTH-1:0] addr_i;
logic [DATA_WIDTH-1:0] rsp_o;
// Data -> Master
logic [DATA_WIDTH-1:0] wdata_i;

logic req, gnt;
logic [ADDR_WIDTH-1:0] addr;
logic we;
logic [DATA_WIDTH/8-1:0] be;
logic [DATA_WIDTH-1:0] wdata;

//// A Channel signals
logic obi_req_o;
logic obi_gnt_i;
logic [ADDR_WIDTH-1:0] obi_addr_o;
logic obi_we_o;
logic [DATA_WIDTH/8-1:0] obi_be_o;
logic [DATA_WIDTH-1:0] obi_wdata_o; 
 
//// R Channel signals 
logic obi_rvalid_i;
logic obi_rready_o;  
logic [DATA_WIDTH-1:0] obi_rdata_i;
logic obi_err_i;

always begin
  clk_i = 0; #5; clk_i = 1; #5;
end

obi_master #(
    .ADDR_WIDTH (32), 
    .DATA_WIDTH (32),
    .AUSER_WIDTH (0),
    .WUSER_WIDTH (0),
    .RUSER_WIDTH (0),
    .ID_WIDTH (0),
    .ACHK_WIDTH (0),
    .RCHK_WIDTH (0),
    .COMB_GNT (0)
) dut (
   .clk_i (clk_i),
   .reset_ni (reset_ni),
   .req_i (req_i),
   .we_i (we_i),
   .addr_i (addr_i),
   .rsp_o (rsp_o),
   .wdata_i (wdata_i),
   //// A-channel signals
   .obi_req_o (obi_req_o),
   .obi_gnt_i (obi_gnt_i),
   .obi_addr_o (obi_addr_o),
   .obi_we_o (obi_we_o),
   .obi_be_o (obi_be_o),
   .obi_wdata_o (obi_wdata_o),
   
    //// R-Channel signals 
   .obi_rvalid_i (obi_rvalid_i),
   .obi_rready_o (obi_rready_o),
   .obi_rdata_i (obi_rdata_i),
   .obi_err_i (obi_err_i)
);

// Initialize signals


endmodule
