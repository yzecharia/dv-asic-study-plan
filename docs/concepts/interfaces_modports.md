# SystemVerilog Interfaces and Modports

**Category**: UVM / SV-for-Design · **Used in**: W4 (anchor), W5+, W11, W14, W20 · **Type**: authored

An `interface` bundles a set of related signals into a single named
construct. A `modport` defines a *view* of that interface from a
particular perspective (e.g. master vs slave). Together they replace
hundreds of port connections and let you change the bundle in one
place.

## Why bother

Without an interface, instantiating an AXI-Lite slave requires:

```systemverilog
axi_lite_slave dut (
    .clk(clk), .rst_n(rst_n),
    .awvalid(awvalid), .awready(awready), .awaddr(awaddr), .awprot(awprot),
    .wvalid(wvalid), .wready(wready), .wdata(wdata), .wstrb(wstrb),
    .bvalid(bvalid), .bready(bready), .bresp(bresp),
    .arvalid(arvalid), .arready(arready), .araddr(araddr), .arprot(arprot),
    .rvalid(rvalid), .rready(rready), .rdata(rdata), .rresp(rresp)
);
```

With an interface:

```systemverilog
axi_lite_slave dut (.aif(aif));
```

## Interface skeleton

```systemverilog
interface axi_lite_if #(parameter int AW = 32, DW = 32) (input logic clk, rst_n);
    logic [AW-1:0] awaddr;
    logic          awvalid, awready;
    logic          awprot;
    logic [DW-1:0] wdata;
    logic [DW/8-1:0] wstrb;
    logic          wvalid, wready;
    logic [1:0]    bresp;
    logic          bvalid, bready;
    logic [AW-1:0] araddr;
    logic          arvalid, arready;
    logic          arprot;
    logic [DW-1:0] rdata;
    logic [1:0]    rresp;
    logic          rvalid, rready;

    modport master (
        output awaddr, awvalid, awprot, wdata, wstrb, wvalid, bready,
               araddr, arvalid, arprot, rready,
        input  awready, wready, bvalid, bresp, arready, rvalid, rdata, rresp,
               clk, rst_n
    );

    modport slave  (
        input  awaddr, awvalid, awprot, wdata, wstrb, wvalid, bready,
               araddr, arvalid, arprot, rready,
               clk, rst_n,
        output awready, wready, bvalid, bresp, arready, rvalid, rdata, rresp
    );

    // Verification view — clocking block to dodge race conditions
    clocking master_cb @(posedge clk);
        default input #1step output #1;
        output awaddr, awvalid, awprot, wdata, wstrb, wvalid, bready,
               araddr, arvalid, arprot, rready;
        input  awready, wready, bvalid, bresp, arready, rvalid, rdata, rresp;
    endclocking : master_cb

    modport tb (clocking master_cb, input clk, rst_n);
endinterface : axi_lite_if
```

## Virtual interfaces in UVM

A class-based UVM driver can't access an interface directly — the
class lives outside the static module hierarchy. The fix is the
**virtual interface**: a handle to the actual interface instance.

```systemverilog
class axi_lite_driver extends uvm_driver #(axi_lite_seq_item);
    virtual axi_lite_if.tb vif;
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_lite_if.tb)::get(this, "", "vif", vif))
            `uvm_fatal("VIF", "vif not set in config_db")
    endfunction
endclass
```

The TB top sets `vif` in `config_db`; the env propagates it down via
wildcard sets.

## Reading

- Sutherland *SystemVerilog for Design* ch.10 — interfaces and
  modports (the canonical reference; pp. TBD).
- Spear *SV for Verification* ch.4 — clocking blocks and virtual
  interfaces (Yuval's `cheatsheets/spear_ch4_interfaces.sv` lives
  here).

## Cross-links

- `[[clocking_resets]]` — clocking blocks live inside interfaces.
- `[[axi_lite]]` — the most common interface example.
- `[[uvm_factory_config_db]]` — virtual interfaces propagate via
  config db.
