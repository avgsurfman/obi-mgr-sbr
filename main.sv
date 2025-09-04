// OBI Master-2-Slaves communication using Mux-demux
// Originally created by Leo Mosser (mole99 @ github.com).
// Modified by Franciszek Moszczuk (avgsurfman @ github.com).
// Licensed under Apache 2.0 License.

// SPDX-FileCopyrightText: © 2025 Leo Moser <leo.moser@pm.me>
// SPDX-License-Identifier: Apache-2.0

`include "obi_slave.sv"
`include "obi_master.sv"
`include "soc_pkg.sv"
`include "./ip/common_cells/src/cf_math_pkg.sv"
`include "./ip/obi/src/obi_pkg.sv"

module add_compare import soc_pkg::*;
(
    input logic clk_i,
    input logic rst_ni,
    //output logic [7:0] err_cnt_o,
    output logic [7:0] pc_o
);   
    //// Local Params
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 32;


    //// Wires
    logic received_s1, received_s2;
    logic received_ack;
    logic bit_compare;
    logic increment;
     

    //// State declaration


    /*
    typedef enum logic [3:0] { 
         FETCH = 1'h0,
         ADD   = 1'h1,
         SAVE  = 1'h2,
         FETCH2 = 1'h3,
         COMPARE = 1'h4,
         ERROR = 1'h5,
         FETCHNEXT = 1'h6,
         STOP = 1'h7
         INCREMENT = 1'h8
    } statetype;
    statetype state, nextstate;
    
    //// 255 counter
    logic[7:0] PC;
    always_ff@(posdedge clk_i or negedge rst_ni)
        if (!rst_ni) PC <= 32'b0000_0000;
        else begin
           if(increment) PC = PC + 1;
        end
    */
    // ---------------
    // Main FSM
    // Like, is it even necessary?
    // I don't need a control unit.
    // Nor do I know how to make one.
    // This is literally TB in hardware.
    // This is bad.
    // What I need is a good testbench.
    // --------------- 
     
    /*
    always_ff@(posedge clk_i or negedge rst_ni)
	if (!rst_ni) state <= FETCH;
        else state <= nextstate;

    always_comb begin
        case(state):
            FETCH:
            if(received_s1) nextstate = ADD;
            else nextstate = FETCH;
            SAVE:
            nextstate = FETCH2;
            FETCH2:
            if(received_s2) nextstate = COMPARE;
            else nextstate = FETCH2;
            COMPARE:
            if(bitcompare) nextstate = FETCHNEXT;
            else nextstate = ERROR;
            ERROR:
            nextstate = FETCHNEXT;
            FETCH_NEXT:
            // STOP.
            nextstate = INCREMENT;
            default:
            nextstate = FETCH;
            // compare regs
        endcase 
    end
    */
 

    // -----------------
    // Manager buses into Mux
    // -----------------

    sbr_obi_req_t master_mux_obi_req;
    sbr_obi_rsp_t master_mux_obi_rsp;
    assign master_mux_obi_req.a.aid = '0;
    assign master_mux_obi_req.a.be = '1;
    assign master_mux_obi_req.a.wdata = '0;
    //assign master_mux_obi_req.a.optional = '0;
    
    
    // ---------------------
    // Mux to Demux bus
    // ---------------------

    sbr_obi_req_t mux_demux_obi_req;
    sbr_obi_rsp_t mux_demux_obi_rsp;


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

    // ------------------
    // Interface bindings
    // ------------------
    ///// SIGNAL DECLARATION
    //// MASTER
    /// A Channel signals
    logic obi_req_o;
    logic obi_gnt_i;
    logic [ADDR_WIDTH-1:0] obi_addr_o;
    logic obi_we_o;
    logic [DATA_WIDTH/8-1:0] obi_be_o;
    logic [DATA_WIDTH-1:0] obi_wdata_o; 
     
    /// R Channel signals 
    logic obi_rvalid_i;
    logic obi_rready_o;  
    logic [DATA_WIDTH-1:0] obi_rdata_i;
    logic obi_err_i;

    ///// SIGNAL ASSIGNMENTS
    ////  SLAVE
    ///   A Channel signals
    logic obi_req_i;
    logic obi_gnt_o;
    logic [ADDR_WIDTH-1:0] obi_addr_i;
    logic obi_we_i;
    logic [DATA_WIDTH/8-1:0] obi_be_i;
    logic [DATA_WIDTH-1:0] obi_wdata_i; 
     
    /// R Channel signals 
    logic obi_rvalid_o;
    logic obi_rready_i;  
    logic [DATA_WIDTH-1:0] obi_rdata_o;
    logic obi_err_o;


    ///// SIGNAL ASSIGNMENTS
    ////  MASTER
    /// A Channel signals
    assign obi_req_o = master_mux_obi_req.req;
    assign obi_gnt_i = master_mux_obi_rsp.gnt;
    assign obi_addr_o = master_mux_obi_req.a.addr;
    assign obi_we_o = master_mux_obi_req.a.we;
    assign obi_be_o = master_mux_obi_req.a.be;
    assign obi_wdata_o = master_mux_obi_req.a.wdata; 
     
    /// R Channel signals 
    assign obi_rvalid_i = master_mux_obi_rsp.rvalid;
    assign obi_rready_o = master_mux_obi_rsp.rready;  
    assign obi_rdata_i = master_mux_obi_rsp.r.rdata;
    assign obi_err_i = master_mux_obi_rsp.r.err;
    // Master <-> Obi Mux

    obi_mux #(
        .SbrPortObiCfg      ( SbrObiCfg     ),
        
        .sbr_port_obi_req_t   ( sbr_obi_req_t ),
        .sbr_port_a_chan_t    ( sbr_obi_a_chan_t ),
        .sbr_port_obi_rsp_t   ( sbr_obi_rsp_t ),
        .sbr_port_r_chan_t    ( sbr_obi_r_chan_t ),
        
        .NumSbrPorts ( NumManagers   ),
        .NumMaxTrans ( 1             )
      ) i_obi_mux (
        .clk_i      ( clk_i  ),
        .rst_ni     ( rst_ni ),
        .testmode_i ( 1'b0   ),
    
        .sbr_ports_req_i   ( mgrs_mux_obi_req  ),
        .sbr_ports_rsp_o   ( mgrs_mux_obi_rsp  ),
    
        .mgr_port_req_o    ( mux_demux_obi_req ),
        .mgr_port_rsp_i    ( mux_demux_obi_rsp )
      );


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
        //// TODO: FILL THIS OUT
        .req_i (),
        .we_i (),
        .addr_i (),
        .rsp_o (),
        .wdata_i (),
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
  always_comb begin
    // default
    periph_idx = 0; 

    // last rule wins
    for (int i=0; i<NumPeriphRules; i++) begin
        if ((mux_demux_obi_req.a.addr >= periph_addr_map[i].start_addr) &&
        ((mux_demux_obi_req.a.addr < periph_addr_map[i].end_addr) || (periph_addr_map[i].end_addr == '0))) periph_idx = periph_addr_map[i].idx;
    end
  end
  
  logic [31:0] mux_demux_obi_req_a_addr;
  assign mux_demux_obi_req_a_addr = mux_demux_obi_req.a.addr;

    obi_demux #(
      .ObiCfg      ( SbrObiCfg     ),
      .obi_req_t   ( sbr_obi_req_t ),
      .obi_rsp_t   ( sbr_obi_rsp_t ),
      .NumMgrPorts ( NumPeriphs    ),
      .NumMaxTrans ( 1             )
    ) i_obi_demux (
      .clk_i  ( clk_i  ),
      .rst_ni ( rst_ni ),

      .sbr_port_select_i ( periph_idx         ),
      .sbr_port_req_i    ( mux_demux_obi_req  ),
      .sbr_port_rsp_o    ( mux_demux_obi_rsp  ),

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

    //// Slave signals
    /// Foo
    // A Channel signals
    logic foo_req_i;
    logic foo_gnt_o;
    logic [ADDR_WIDTH-1:0] foo_addr_i;
    logic foo_we_i;
    logic [DATA_WIDTH/8-1:0] foo_be_i;
    logic [DATA_WIDTH-1:0] foo_wdata_i; 
     
    // R Channel signals 
    logic foo_rvalid_o;
    logic foo_rready_i;  
    logic [DATA_WIDTH-1:0] foo_rdata_o;
    logic foo_err_o;

    assign foo_req_i = foo_obi_req.req;
    assign foo_gnt_o = foo_obi_rsp.gnt;
    assign foo_addr_i = foo_obi_req.a.addr;
    assign foo_we_i = foo_obi_req.a.we;
    assign foo_be_i = foo_obi_req.a.be;
    assign foo_wdata_i = foo_obi_req.a.wdata;
    
    assign foo_rvalid_o = foo_obi_rsp.rvalid;
    assign foo_rready_i = foo_obi_rsp.rready;
    assign foo_rdata_o = foo_obi_rsp.r.rdata;
    assign foo_err_o = foo_obi_rsp.r.err;
 

    //// Bar 
    // A Channel signals
    logic bar_req_i;
    logic bar_gnt_o;
    logic [ADDR_WIDTH-1:0] bar_addr_i;
    logic bar_we_i;
    logic [DATA_WIDTH/8-1:0] bar_be_i;
    logic [DATA_WIDTH-1:0] bar_wdata_i; 
     
    // R Channel signals 
    logic bar_rvalid_o;
    logic bar_rready_i;  
    logic [DATA_WIDTH-1:0] bar_rdata_o;
    logic bar_err_o;
    
    assign bar_req_i = bar_obi_req.req;
    assign bar_gnt_o = bar_obi_rsp.gnt;
    assign bar_addr_i = bar_obi_req.a.addr;
    assign bar_we_i = bar_obi_req.a.we;
    assign bar_be_i = bar_obi_req.a.be;
    assign bar_wdata_i = bar_obi_req.a.wdata;
    
    assign bar_rvalid_o = bar_obi_rsp.rvalid;
    assign bar_rready_i = bar_obi_rsp.rready;
    assign bar_rdata_o = bar_obi_rsp.r.rdata;
    assign bar_err_o = bar_obi_rsp.r.err;
    
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
       .obi_req_i (foo_req_i),
       .obi_gnt_o (foo_gnt_o),
       .obi_addr_i (foo_addr_i),
       .obi_we_i (foo_we_i),
       .obi_be_i (foo_be_i),
       .obi_wdata_i (foo_wdata_i),
       
        //// R-Channel signals 
       .obi_rvalid_o (foo_rvalid_o),
       .obi_rready_i (foo_rready_i),
       .obi_rdata_o (foo_rdata_o),
       .obi_err_o (foo_err_o)
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
       .obi_req_i (bar_req_i),
       .obi_gnt_o (bar_gnt_o),
       .obi_addr_i (bar_addr_i),
       .obi_we_i (bar_we_i),
       .obi_be_i (bar_be_i),
       .obi_wdata_i (bar_wdata_i),
       
        //// R-Channel signals 
       .obi_rvalid_o (bar_rvalid_o),
       .obi_rready_i (bar_rready_i),
       .obi_rdata_o (bar_rdata_o),
       .obi_err_o (bar_err_o)
    );

endmodule
