`include "obi_slave_be.sv"
`ifndef VERILATOR
`timescale 1ns / 1ps
`endif

module obi_slave_tb();

localparam ADDR_WIDTH = 32;
localparam DATA_WIDTH = 32;

logic clk_i;
logic reset_ni;


//// Controller signals


//// A Channel signals
logic obi_req_i;
logic obi_gnt_o;
logic [ADDR_WIDTH-1:0] obi_addr_i;
logic obi_we_i;
logic [DATA_WIDTH/8-1:0] obi_be_i;
logic [DATA_WIDTH-1:0] obi_wdata_i; 
 
//// R Channel signals 
logic obi_rvalid_o;
logic obi_rready_i;  
logic [DATA_WIDTH-1:0] obi_rdata_o;
logic obi_err_o;

always begin
  clk_i = 0; #5; clk_i = 1; #5;
end

obi_slave_be #(
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
   //// A-channel signals
   .obi_req_i (obi_req_i),
   .obi_gnt_o (obi_gnt_o),
   .obi_addr_i (obi_addr_i),
   .obi_we_i (obi_we_i),
   .obi_be_i (obi_be_i),
   .obi_wdata_i (obi_wdata_i),
   
    //// R-Channel signals 
   .obi_rvalid_o (obi_rvalid_o),
   .obi_rready_i (obi_rready_i),
   .obi_rdata_o (obi_rdata_o),
   .obi_err_o (obi_err_o)
);

//Preload RAM
initial begin
    $readmemh("mem.hex", dut.mem);
end


// Initialize signals
initial begin
    $dumpfile("obi_slave_be.vcd");
    $dumpvars(0, dut);
    $display("Starting the testbench...");
    $display("Test 0: Power-on (Transition to IDLE state)");
    reset_ni = 1'b1;
    obi_req_i = 1'b0; 
    obi_we_i = 1'b0;
    obi_addr_i = 'b0; 
    obi_wdata_i = 'b0;
    
    
    // @posedge is not supported by iverilog
    // (systemverilog.dev) 
    #5; //posedge
    reset_ni = 1'b0; 
    #5;
    reset_ni = 1'b1; 
    #10;
    //assert that state is IDLE
    assert(dut.state == 2'b00) else begin
        $error("Failed to reset! Actual value: %h", dut.state);
        $stop;
    end
    $display("Test 1: Read DA7A5EAD @ 0x0000_0004.");
    //set req high 
    obi_req_i = 1'b1; 
    obi_addr_i = 'h0000_0004;
    obi_rready_i = 1'b1;
    #10;
    obi_req_i = 1'b0;
    //check on posedge
    assert(obi_rdata_o == 'hDA7A5EAD) else begin
        $error("Failed to read! Actual value: %h", obi_rdata_o);
        $stop;
    end
    
    //$display("Test 2: Bad out-of-range read @ 0x0000_0100.");
    #5; //clk edge
    /*
    obi_req_i = 1'b1;
    obi_addr_i = 'hFFFF_FFFF;
    #15;
    assert(obi_rdata_o == 'hBADCAB1E && obi_err_o == 1) else begin
        $error("Failed to read BADCAB1E! Actual value: %h, obi_err_o == ", obi_rdata_o, obi_err_o);
        $stop;
    end
    $display("Test 3: Write data to 0x0000002 data. [FAIL]");
    obi_addr_i = 'h0000_0002;
    obi_wdata_i = 'h1337_C0DE;
    obi_we_i = 1'b1;
    obi_req_i = 1'b1;
    // two clock cycles
    #20
    */    
    $display("Test 3: Write good data to 0x000000C data.");
    obi_be_i = 4'b1111;
    obi_addr_i = 'h0000_0008;
    obi_wdata_i = 'h1337_C0DE;
    obi_we_i = 1'b1;
    obi_req_i = 1'b1;
    // two clock cycles
    #20
    assert(dut.mem[2] == 'h1337_C0DE) else begin
        $error("Failed to write! Actual value: %h", dut.mem[2]);
        $display("memdump %h %h %h %h %h", dut.mem[0], dut.mem[1], dut.mem[2], dut.mem[3], dut.mem[4]);
        $stop;
    end
    
    $display("Test 4: Write a byte to 0x000000F.");
    obi_be_i = 4'b1000;
    obi_addr_i = 'h0000_000F;
    obi_wdata_i = 'h1337_C0DE;
    obi_we_i = 1'b1;
    obi_req_i = 1'b1;
    // two clock cycles
    #30
    $display("memdump %h %h %h %h %h", dut.mem[0], dut.mem[1], dut.mem[2], dut.mem[3], dut.mem[4]);
    assert(dut.mem[2] == 'h1337_C0DE) else begin
        $error("Failed to write! Actual value: %h", dut.mem[2]);
        $stop;
    end
    $display("All tests passed successfully");
    $stop; 

end


endmodule
