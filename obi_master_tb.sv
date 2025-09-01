`include "obi_master.sv"
`timescale 1ns / 1ps

module obi_master_tb();

localparam ADDR_WIDTH = 32;
localparam DATA_WIDTH = 32;

logic clk_i;
logic reset_ni;

/// Test vectors

//logic [DATA_WIDTH*]

//Inputs: addr_i _req_gnt_rvalid


//initial begin
//    $readmemh()
//

//// Controller signals
logic req_i; 
logic we_i;
logic [ADDR_WIDTH-1:0] addr_i;
logic [DATA_WIDTH-1:0] rsp_o;
// Data -> Master
logic [DATA_WIDTH-1:0] wdata_i;

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
   .obi_err_i (1'b0)
);

// Initialize signals
initial begin
    $dumpfile("obi_master.vcd");
    $dumpvars(0, dut);
    $display("Starting the testbench...");
    $display("Test 0: Power-on (Transition to IDLE state)");
    reset_ni = 1;
    req_i = 0; 
    we_i = 0;
    addr_i = 'b0; 
    wdata_i = 'b0;
    obi_gnt_i = 'b0;
    obi_rvalid_i = 'b0;
    // not supported by iverilog
    //@posedge (clk_i);
    #5;
    reset_ni = 0; 
    #5;
    reset_ni = 1; 
    #10;
    //assert that state is 000
    assert(dut.state == 3'b000) else begin
        $error("Failed to reset! Actual value: %h", dut.state);
        $stop;
    end
    $display("Test 1: Get arb data.");
    //set req high 
    req_i = 1; 
    addr_i = 'hDEADBEEF;
    // Wait for a gnt request.
    #5; //rising clock edge
    obi_gnt_i = 1;
    #11;
    //check on posedge
    assert(obi_req_o == 1'b0) else begin
        $error("Failed to Acknowledge GNT! Actual value: %h", dut.state);
        $stop;
    end
    #10;
    obi_gnt_i = 0;
    obi_rvalid_i = 1;
    obi_rdata_i = 'h1A73BEEF;
    #10;
    assert(rsp_o == 'h1A73BEEF) else $error("Failed to receive the read signal.");
    $display("Test 2. Write arb data.");
    we_i = 1;
    req_i = 1;
    //addr_i = 
    //#10;
     
    $display("All tests passed successfully");
    $stop; 

end


endmodule
