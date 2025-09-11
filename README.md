# Obi Master-Slave Implementation
OBI BUS protocol Master and Slave sample implementation according to
OBI protocol, version 1.2.

*100% ORGANIC CODE | NOW 100% AI-FREE!*

Contents:
- `obi_master_tb` - Master device able to send Read/Write commands.
- `obi_slave.sv` - Slave device able to write and read signals from its SRAM.
- `*_tb.sv` - Testbenches (Read/Write tests)

Both device files act as templates, as most of unnecessary signals and parameters have been commented out, but can be implemented as see fit.
Both devices implement limited error handling (e.g bad writes).

## Adding a Slave Device 


## State-transition Diagram
![A state transition diagram poorly drawn by hand and digitized. Honestly, just use a screen reader for those files instead.](transition_graph.jpg)


Licensed under Apache 2.0 license, see details in `License.txt`.

