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
    $readmemh("./obi_slave/mem.hex", dut.foo.mem);
    $readmemh("./obi_slave/mem.hex", dut.bar.mem);
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

// Try to read something from foo.
req_i = 1;
addr_i = 32'h0000_0003;
#30
assert(rsp_o == 32'h0000_3333) else $error("Failed to read! %h", rsp_o);
req_i = 1;
we_i = 1;
addr_i = 32'h0000_0001;
wdata_i = 32'h1337_C0DE;
// wait 3 clock cycles for a write
#30;
assert(dut.foo.mem[1] == 32'h1337_C0DE) else $error("Failed to write LEETCODE to 0x1, got: %h", dut.foo.mem[1]);


$display("Simulation finished.");
$display("+------------------+");
$display("All tests passed successfully.");
$stop;
end

endmodule
