// mem_waligned_32
// Generic RISC-V 32-bit data/instruction memory.
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

module mem_waligned_32#(
    parameter MEM_WIDTH = 6
) ( 
    input logic clk, reset, we,
    input logic [3:0] be,
    input logic [31:0] a, wd,
    output logic [31:0] rd,
    output logic err 
);

logic werr, rerr;

///// Memory array declaration
/// Credit where its due:
// https://stackoverflow.com/questions/58305689/

//    [shw][sby][dat]    [   word_count   ]
logic [1:0][1:0][7:0] mem[2**MEM_WIDTH-1:0];

always_ff@(posedge clk) begin : mem_write
    // Unfortunately implicit bit truncation will crash your simulation,
    // hence the 7 magic constant. 
    // Also, multi-dimensional selects like mem[a[7:2]][[a[1]][a[0]] 
    // crash librelane on the DRC check. Noone knows why.
    werr = 1'b0;
    if(we) begin 
        case(be)
        // sw
        4'b1111: mem[a[7:2]] <= wd; // sw
        // sh zone
        4'b1100: mem[a[7:2]][1] <= wd[31:16]; //sh
        4'b0011: mem[a[7:2]][0] <= wd[15:0]; 
        // sb zone
        4'b1000: mem[a[7:2]][1][1] <= wd[31:24];
        4'b0100: mem[a[7:2]][1][0] <= wd[23:16];
        4'b0010: mem[a[7:2]][0][1] <= wd[15:8];
        4'b0001: mem[a[7:2]][0][0] <= wd[7:0];
        default:
            werr = 1'b1;
        endcase
    end
end

always_comb begin : mem_read 
   rerr = 1'b0;
   rd = 0;
   case(be)
        4'b1111: rd = mem[a[7:2]]; // lw
        // lh zone
        4'b1100: rd[31:16] = mem[a[7:2]][1];
        4'b0011: rd[15:0] = mem[a[7:2]][0];
        // lb zone
        4'b1000: rd[31:24] = mem[a[7:2]][1][1];
        4'b0100: rd[23:16] = mem[a[7:2]][1][0];
        4'b0010: rd[15:8]  = mem[a[7:2]][0][1];
        4'b0001: rd[7:0]   = mem[a[7:2]][0][0];
        default: begin
            rerr = 1'b1;
            rd = 'hDEADBEEF;
        end
    endcase
end

assign err = werr | rerr;

endmodule

