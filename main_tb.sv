module main_tb();   

logic clk_i;
logic rst_ni;
logic [7:0] err_cnt_o;
logic req_i;
logic we_i;
logic [31:0] addr_i;
logic [31:0] rsp_o;
logic [31:0]wdata_i;

main dut(
.clk_i (clk_i),
.rst_ni (rst_ni),
.req_i (req_i),
.we_i (we_i),
.err_cnt_o (err_cnt_o),
.addr_i (addr_i),
.rsp_o (rsp_o),
.wdata_i (wdata_i)
);

always begin
  clk_i = 0; #5; clk_i = 1; #5;
end

//initalize ram
//Preload RAM
initial begin
    $readmemh("mem.hex", dut.foo.mem);
    $readmemh("mem.hex", dut.bar.mem);
end

initial begin    
    $dumpfile("waveform.vcd");
    $dumpvars(0, dut);
    $display("Starting the testbench...");
req_i = 0;
we_i = 0;
addr_i = 32'h0000_0000;
wdata_i = 32'h0000_0000;
rst_ni = 1'b1;
#1;
rst_ni = 1'b0;
#4;
rst_ni = 1'b1;
#5;

// Try to read something from foo or bar.
req_i = 1;
addr_i = 32'h0000_0003;
#20

//assert(rsp_o == 32'h0000_3333) else $error("Mismatch! %h", rsp_o);
#20;
$display("Simulation finished.");
$stop;
end

endmodule
