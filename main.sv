// OBI Master-2-Slaves communication using Mux-demux
// Originally created by Leo Mosser (mole99 @ github.com).
// Modified by Franciszek Moszczuk (avgsurfman @ github.com).
// Licensed under Apache 2.0 License.

// SPDX-FileCopyrightText: © 2025 Leo Moser <leo.moser@pm.me>
// SPDX-License-Identifier: Apache-2.0

`include "./obi_slave/obi_slave.sv"
`include "./obi_master/obi_master.sv"
`include "soc_pkg.sv"
`include "./ip/common_cells/src/cf_math_pkg.sv"
`include "./ip/common_cells/src/delta_counter.sv"
`include "./ip/common_cells/include/common_cells/assertions.svh"
`include "./ip/common_cells/src/fifo_v3.sv"
`include "./ip/obi/src/obi_pkg.sv"
`include "./ip/obi/include/obi/assign.svh"
`include "./ip/obi/src/obi_mux.sv"
`include "./ip/obi/src/obi_demux.sv"
`include "./ip/obi/src/obi_err_sbr.sv"


module main import soc_pkg::*;
(
    input logic clk_i,
    input logic rst_ni,

    output logic [7:0] err_cnt_o,
    //output logic [7:0] pc_o,

    input req_i,
    input we_i,
    input [31:0] addr_i,
    output [31:0] rsp_o,
    input [31:0]wdata_i

);   
    //// Local Params
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 32;

     
   
    /*
    //// 255 counter
    logic[7:0] PC;
    always_ff@(posdedge clk_i or negedge rst_ni)
        if (!rst_ni) PC <= 32'b0000_0000;
        else begin
           if(increment) PC = PC + 1;
        end
    */
 

    // -----------------
    // Manager buses into Demux
    // -----------------

    sbr_obi_req_t master_demux_obi_req;
    sbr_obi_rsp_t master_demux_obi_rsp;
    assign master_demux_obi_req.a.aid = '0;
    //assign master_demux_obi_req.a.wdata = '0;
    //assign master_demux_obi_req.a.optional = '0;
    

    // -----------------
    // Peripheral buses
    // -----------------

    // array of subordinate buses from peripheral demultiplexer
    sbr_obi_req_t [NumPeriphs-1:0] all_periph_obi_req;
    sbr_obi_rsp_t [NumPeriphs-1:0] all_periph_obi_rsp;

    // Error bus
    sbr_obi_req_t error_obi_req;
    sbr_obi_rsp_t error_obi_rsp;

    // Slave 1 bus
    sbr_obi_req_t foo_obi_req;
    sbr_obi_rsp_t foo_obi_rsp;
    
    // Slave 2 bus
    sbr_obi_req_t bar_obi_req;
    sbr_obi_rsp_t bar_obi_rsp;

    // ---------------
    // Periph Addr Map
    // ---------------

    assign error_obi_req = all_periph_obi_req[PeriphError];
    assign all_periph_obi_rsp[PeriphError] = error_obi_rsp;

    assign foo_obi_req = all_periph_obi_req[PeriphFoo];
    assign all_periph_obi_rsp[PeriphFoo] = foo_obi_rsp;
    
    assign bar_obi_req = all_periph_obi_req[PeriphBar];
    assign all_periph_obi_rsp[PeriphBar] = bar_obi_rsp;


    //// Master device
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
    ) master (
        .clk_i (clk_i),
        .reset_ni (rst_ni),
        //// Controler signals
        .req_i (req_i),
        .we_i (we_i),
        .addr_i (addr_i),
        .rsp_o (rsp_o),
        .wdata_i (wdata_i),

        //// A-channel signals
        .obi_req_o (master_demux_obi_req.req),
        .obi_gnt_i (master_demux_obi_rsp.gnt),
        .obi_addr_o (master_demux_obi_req.a.addr),
        .obi_we_o (master_demux_obi_req.a.we),
        .obi_be_o (master_demux_obi_req.a.be),
        .obi_wdata_o (master_demux_obi_req.a.wdata),
        
         //// R-Channel signals 
        .obi_rvalid_i (master_demux_obi_rsp.rvalid),
        .obi_rready_o (master_demux_obi_req.rready),
        .obi_rdata_i (master_demux_obi_rsp.r.rdata),
        .obi_err_i (master_demux_obi_rsp.r.err),

        .err_cnt_o (err_cnt_o)
    );
 

  // -----------------
  // Peripherals
  // -----------------

  // demultiplex to peripherals according to address map
  // Note: this macro just just does log2 of N 
  logic [cf_math_pkg::idx_width(NumPeriphs)-1:0] periph_idx;
  
  // checks whether the incoming adress falls within proper range
  // defined in the soc_pkg file and if so selects the matching id 
  // latter adresses have priority
  // else it goes into the Error device
  always_comb begin : addr_resolver
    // default
    periph_idx = 0; 

    // last rule wins
    for (int i=0; i<NumPeriphRules; i++) begin
        if ((master_demux_obi_req.a.addr >= periph_addr_map[i].start_addr) &&
        ((master_demux_obi_req.a.addr < periph_addr_map[i].end_addr) || (periph_addr_map[i].end_addr == '0))) periph_idx = periph_addr_map[i].idx[cf_math_pkg::idx_width(NumPeriphs)-1:0];
    end
  end
  

    obi_demux #(
      .ObiCfg      ( SbrObiCfg       ),
      .obi_req_t   ( sbr_obi_req_t ),
      .obi_rsp_t   ( sbr_obi_rsp_t   ),
      .NumMgrPorts ( NumPeriphs      ),
      .NumMaxTrans ( 1               )
    ) i_obi_demux (
      .clk_i  ( clk_i  ),
      .rst_ni ( rst_ni ),

      .sbr_port_select_i ( periph_idx         ),
      .sbr_port_req_i    ( master_demux_obi_req ),
      .sbr_port_rsp_o    ( master_demux_obi_rsp ),

      .mgr_ports_req_o   ( all_periph_obi_req ),
      .mgr_ports_rsp_i   ( all_periph_obi_rsp )
    );

     //// Peripheral space error subordinate
     obi_err_sbr #(
       .ObiCfg      ( SbrObiCfg     ),
       .obi_req_t   ( sbr_obi_req_t ),
       .obi_rsp_t   ( sbr_obi_rsp_t ),
       .NumMaxTrans ( 1             ),
       .RspData     ( 32'hBADCAB1E  )
     ) i_periph_err (
       .clk_i      ( clk_i ),
       .rst_ni     ( rst_ni ),
       .testmode_i ( 1'b0 ),
       .obi_req_i  ( error_obi_req ),
       .obi_rsp_o  ( error_obi_rsp )
     );
    
    //// Slave Instantiation
    
    obi_slave #(
        .ADDR_WIDTH (32), 
        .DATA_WIDTH (32),
        .AUSER_WIDTH (0),
        .WUSER_WIDTH (0),
        .RUSER_WIDTH (0),
        .ID_WIDTH (0),
        .ACHK_WIDTH (0),
        .RCHK_WIDTH (0),
        .COMB_GNT (0)
    ) foo (
       .clk_i (clk_i),
       .reset_ni (rst_ni),
       //// A-channel signals
       .obi_req_i (foo_obi_req.req),
       .obi_gnt_o (foo_obi_rsp.gnt),
       .obi_addr_i (foo_obi_req.a.addr),
       .obi_we_i (foo_obi_req.a.we),
       .obi_be_i (foo_obi_req.a.be),
       .obi_wdata_i (foo_obi_req.a.wdata),
       
        //// R-Channel signals 
       .obi_rvalid_o (foo_obi_rsp.rvalid),
       .obi_rready_i (foo_obi_req.rready),
       .obi_rdata_o (foo_obi_rsp.r.rdata),
       .obi_err_o (foo_obi_rsp.r.err)
    );

    obi_slave #(
        .ADDR_WIDTH (32), 
        .DATA_WIDTH (32),
        .AUSER_WIDTH (0),
        .WUSER_WIDTH (0),
        .RUSER_WIDTH (0),
        .ID_WIDTH (0),
        .ACHK_WIDTH (0),
        .RCHK_WIDTH (0),
        .COMB_GNT (0)
    ) bar (
       .clk_i (clk_i),
       .reset_ni (rst_ni),
       //// A-channel signals
       .obi_req_i (bar_obi_req.req),
       .obi_gnt_o (bar_obi_rsp.gnt),
       .obi_addr_i (bar_obi_req.a.addr),
       .obi_we_i (bar_obi_req.a.we),
       .obi_be_i (bar_obi_req.a.be),
       .obi_wdata_i (bar_obi_req.a.wdata),
       
        //// R-Channel signals 
       .obi_rvalid_o (bar_obi_rsp.rvalid),
       .obi_rready_i (bar_obi_req.rready),
       .obi_rdata_o (bar_obi_rsp.r.rdata),
       .obi_err_o (bar_obi_rsp.r.err)
    );

endmodule
