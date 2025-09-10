// Struct definition file. Contains OBI Bus definitions.
// Originally created by Leo Mosser (mole99 @ github.com).
// (Slightly) Modified by Franciszek Moszczuk (avgsurfman @ github.com).
// Licensed under the Apache 2.0 License.

// SPDX-FileCopyrightText: © 2025 Leo Moser <leo.moser@pm.me>
// SPDX-License-Identifier: Apache-2.0

package soc_pkg;

    localparam int unsigned HartId = 32'd0;

    localparam int unsigned BootAddr = 32'h0000_0080;

    // Machine Trap-Vector Base Address, 128-byte aligned
    localparam int unsigned MtvecAddr = 32'h0000_0000;

    ///////////////////////
    // Managers         ///
    ///////////////////////

    localparam int unsigned NumManagers = 1; // 
    
    // -- NumManagers > 2 --
    // Enum for bus indices
    // typedef enum int {
    //    ManagInstr     = 0,
    //    ManagData      = 1
    //} manage_outputs_e;

    ///////////////////////
    // Address Maps     ///
    ///////////////////////

    // Address map data type
    typedef struct packed {
        logic [31:0] idx;
        logic [31:0] start_addr;
        logic [31:0] end_addr;
    } addr_map_rule_t;

    /////////////////////////////
    // Peripheral address map ///
    /////////////////////////////

    localparam bit [31:0] FooAddrOffset           = 32'h0000_0000;
    localparam bit [31:0] FooAddrRange            = 32'h0000_000F; 

    localparam bit [31:0] BarAddrOffset            = 32'h2000_0000;
    localparam bit [31:0] BarAddrRange             = 32'h0000_0008; // 256 * 32 bit words

    localparam int unsigned NumPeriphRules  = 2;
    localparam int unsigned NumPeriphs      = NumPeriphRules + 1; // additional OBI error

    // Enum for bus indices
    typedef enum int {
        PeriphError         = 0,
        PeriphFoo        = 1,
        PeriphBar        = 2
    } periph_outputs_e;

    localparam addr_map_rule_t [NumPeriphRules-1:0] periph_addr_map = '{                                        // 0: OBI Error (default)
        '{ idx: PeriphFoo,  start_addr: FooAddrOffset,  end_addr: FooAddrOffset + FooAddrRange },    // 1: Foo (Slave 1)
        '{ idx: PeriphBar,   start_addr: BarAddrOffset,   end_addr: BarAddrOffset  + BarAddrRange  } // 2: Bar (Slave 2)
    };
    
    // ---------------------------------------------

    /// OBI subordinate configuration (from the interconnect to a subordinate device)
    localparam obi_pkg::obi_cfg_t SbrObiCfg = '{
          // rready is used
          UseRReady:      1,
          CombGnt:     1'b0,
          AddrWidth:     32,
          DataWidth:     32,
          // One manager
          IdWidth:        1,
          Integrity:   1'b0,
          BeFull:      1'b1,
          OptionalCfg:  '0
      };


    /// OBI Xbar <-> Subordinate address channel
    typedef struct packed {
        logic [  SbrObiCfg.AddrWidth-1:0] addr;
        logic                             we;
        logic [SbrObiCfg.DataWidth/8-1:0] be;
        logic [  SbrObiCfg.DataWidth-1:0] wdata;
        logic [    SbrObiCfg.IdWidth-1:0] aid;
        logic                             a_optional; // dummy signal; not used
    } sbr_obi_a_chan_t;

    /// OBI Xbar <-> Subordinate request
    typedef struct packed {
        sbr_obi_a_chan_t a;
        logic            req;
        logic            rready;
    } sbr_obi_req_t;

    /// OBI Xbar <-> Subordinate response channel
    typedef struct packed {
        logic [SbrObiCfg.DataWidth-1:0] rdata;
        logic [  SbrObiCfg.IdWidth-1:0] rid;
        logic                           err;
        logic                           r_optional; // dummy signal; not used
    } sbr_obi_r_chan_t;

    /// OBI Xbar <-> Subordinate response
    typedef struct packed {
        sbr_obi_r_chan_t r;
        logic            gnt;
        logic            rvalid;
    } sbr_obi_rsp_t;


endpackage

