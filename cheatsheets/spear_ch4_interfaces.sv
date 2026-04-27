// ============================================================================
// Spear & Tumbush — CHAPTER 4 — Connecting the Testbench and Design
// CHEATSHEET (reference only — NOT runnable as-is)
//
// Covers SV interfaces, modports, clocking blocks, virtual interfaces,
// race conditions, and program blocks. Scan by section header or keyword.
// ============================================================================


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  WHY THIS CHAPTER EXISTS                                                  ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// Two problems with old-school Verilog testbenches:
//
//   1) PORT EXPLOSION — every signal must be declared and connected in
//      every place: TB, DUT, BFM, monitor. Add a signal → touch 4-5 files.
//
//   2) RACE CONDITIONS — when TB and DUT both react to the same clock edge,
//      who wins is implementation-defined. Same code, different simulator,
//      different result.
//
// The interface construct fixes both. One named bundle, declared once,
// passed around. Modports give role-specific direction views. Clocking
// blocks give race-free TB driving.


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  4.1 — SEPARATING THE TESTBENCH FROM THE DESIGN                           ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// The job of an interface: be the boundary between RTL hardware (the DUT)
// and behavioral testbench code. Everything that crosses the boundary
// goes through the interface.
//
//        ┌─────────┐         ┌─────────┐         ┌─────────┐
//        │   TB    │────────►│ ahb_if  │◄────────│   DUT   │
//        │ (master)│   bus   │ (signals│   bus   │ (slave) │
//        └─────────┘         │ + cb +  │         └─────────┘
//                            │ asserts)│
//                            └────┬────┘
//                                 │ bus
//                            ┌────▼────┐
//                            │ Monitor │
//                            └─────────┘
//
// All wiring goes through the bus. Add a signal? edit ONE file: the interface.


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  4.2 — INTERFACE DECLARATIONS                                             ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// Basic shape:

interface my_if (input bit clk);          // optional ports (clock typically)
    logic [7:0] addr, data;                // signals — same shape as a module
    logic       valid, ready;
    bit         reset;

    // (modports + clocking blocks go here — see below)
endinterface : my_if

// Instantiate just like a module:
//
//    my_if  bus(clk);
//    my_dut dut(.bus(bus));
//
// You can put types, parameters, tasks, functions, even assertions inside
// the interface — anything that helps describe the protocol lives there.


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  4.3 — STIMULUS TIMING & THE RACE PROBLEM                                 ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// Without a clocking block, this is what races:
//
//    posedge clk fires
//      ├─► DUT's always_ff samples `request`     (which value? OLD or NEW?)
//      └─► TB drives `request <= 2'b01`           ← could happen before OR after
//
// SV's event-scheduling regions are loosely defined for cross-process events,
// so the order is implementation-defined.
//
// Symptom: works in one simulator, fails in another. Or works on Mondays.
//
// Fix: the clocking block. See § 4.4.


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  4.4 — CLOCKING BLOCKS                                                    ║
// ║      Where most of the syntax pain happens — read carefully               ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
//   ★ INSIDE A CLOCKING BLOCK: each line ENDS WITH ; (like SV statements) ★

clocking cb @(posedge clk);                // event for sync
    default input #1step output #0;        // skew defaults — usually omitted
    output addr, data, valid;              // ← signals the OWNER drives
    input  ready;                          // ← signals the OWNER samples
endclocking : cb

// Skews explained:
//   #1step input  → "sample 1 simulator step BEFORE the clock event"
//                   (gets the value as it was *just before* the edge — stable)
//   #0     output → "drive AT the edge (Re-NBA region)"
//                   (drive lands AFTER DUT's NBA samples, so DUT sees OLD value;
//                    the new drive becomes visible NEXT cycle)
//
// Net effect:
//   - TB writes via cb.<sig> <= X        → DUT sees X next cycle (1-cycle latency)
//   - TB reads via  cb.<sig>             → gets stable value from before the edge
//   - No races, ever.


// ── Driving via the clocking block ─────────────────────────────────────────
//
//    bus.cb.addr  <= 8'hAA;       // <= because output skew is non-blocking
//    bus.cb.valid <= 1'b1;
//
//    Why bus.cb.addr (not bus.addr)?
//      - bus.addr        = direct, racy
//      - bus.cb.addr     = via clocking block, skewed and race-free


// ── Sampling via the clocking block ────────────────────────────────────────
//
//    if (bus.cb.ready) ...        // sees value as of #1step before posedge
//    rdata = bus.cb.rdata;        // same — stable, race-free


// ── Synchronizing to the clock ─────────────────────────────────────────────
//
//    @(bus.cb)               // wait for next clocking event
//                            //   (= next posedge clk, but in the deferred
//                            //    region so cb reads/writes are race-free)
//
//    @(posedge bus.clk)      // raw — works but races possible
//
//    PREFER @(bus.cb) when using a clocking block.


// ── Multiple clocking blocks per interface ─────────────────────────────────
//
// Each role can have its own clocking block with directions appropriate to
// that role:

interface ahb_if_example (input bit HCLK);
    logic [20:0] HADDR;
    logic        HWRITE;
    logic [1:0]  HTRANS;
    logic [7:0]  HWDATA, HRDATA;

    clocking master_cb @(posedge HCLK);
        output HADDR, HWRITE, HTRANS, HWDATA;       // master DRIVES
        input  HRDATA;                                // master SAMPLES
    endclocking

    clocking monitor_cb @(posedge HCLK);
        input  HADDR, HWRITE, HTRANS, HWDATA, HRDATA; // all input — passive
    endclocking

    // (modports below)
endinterface


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  4.5 — MODPORTS                                                           ║
// ║      Role-specific views into the same set of signals                     ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
//   ★ INSIDE A MODPORT: declarations are SEPARATED BY , (commas)             ★
//   ★ NO TERMINATOR ON THE LAST ITEM (looks like a function call's args)     ★

interface example_if (input bit clk);
    logic [7:0] data_out, data_in;
    logic       valid, ready, reset;

    clocking master_cb @(posedge clk);
        output data_out, valid;
        input  data_in,  ready;
    endclocking

    clocking monitor_cb @(posedge clk);
        input data_out, data_in, valid, ready;
    endclocking

    // ── Master view: drives most signals ──
    modport master (
        clocking master_cb,
        output reset
    );

    // ── DUT view: opposite of master, no clocking block (RTL doesn't race) ──
    modport dut (
        input  data_out, valid, reset, clk,
        output data_in, ready
    );

    // ── Passive monitor: everything is input ──
    modport monitor (
        clocking monitor_cb
    );
endinterface

// Use a modport when you instantiate the interface in a module:
//
//    module my_master  (example_if.master  bus);  // can only access cb + reset
//    module my_dut     (example_if.dut     bus);  // can only access plain signals
//    module my_monitor (example_if.monitor bus);  // can only sample via mon_cb


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  PUNCTUATION RULES — THE #1 SOURCE OF SYNTAX ERRORS                       ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
//   CLOCKING BLOCK — looks like a series of statements
//   ────────────────────────────────────────────────────
//   clocking cb @(posedge clk);
//       output a, b, c;       ← ; (statement)
//       input  x, y;          ← ; (statement)
//   endclocking
//
//   MODPORT — looks like a function call's argument list
//   ────────────────────────────────────────────────────
//   modport role (
//       input  a, b, c,        ← , (separator)
//       output x, y,           ← , (separator — more after)
//       clocking cb            ← LAST item, NO terminator
//   );
//
// Get this wrong, and xvlog will spew "syntax error near 'output'" or
// "illegal empty modport port declaration".


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  4.6 — VIRTUAL INTERFACES (preview — full coverage in UVM ch.11+)         ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// An interface is STATIC (lives in module hierarchy). A class is DYNAMIC
// (created at runtime). To let class-based TB code talk to a static
// interface, you use a VIRTUAL INTERFACE — a class member that holds a
// HANDLE to the actual interface instance:

class driver;
    virtual example_if vif;          // ← handle, not the interface itself

    function new(virtual example_if v);
        vif = v;
    endfunction

    task drive(byte d);
        vif.master_cb.data_out <= d;  // class code accessing static signals
    endtask
endclass

// Wiring (in a top module):
//    example_if bus(clk);
//    driver d;
//    initial d = new(bus);


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  4.7 — TOP-LEVEL WIRING                                                   ║
// ╚══════════════════════════════════════════════════════════════════════════╝

module tb_top;
    bit clk;
    always #5 clk = ~clk;                    // clock generator

    example_if bus(clk);                     // one interface instance

    my_master  master_inst (.bus(bus));      // explicit named ports — safest
    my_dut     dut_inst    (.bus(bus));
    my_monitor mon_inst    (.bus(bus));

    initial begin
        // optional safety timeout
        #1us $finish;
    end
endmodule

// ── Three ways to connect the interface to instances ──
//
//   1) Explicit named:        my_dut dut(.bus(bus));      ← safest
//   2) Positional:            my_dut dut(bus);             ← terse, fragile
//   3) Wildcard `.*`:         my_dut dut(.*);              ← only if PORT
//                                                          name == signal name
//
// If you use .*, every module's interface port MUST be named the same as
// the interface variable in the parent (e.g. all `bus`).
//
// Common pitfall:
//    interface ahb_if; ... endinterface
//    module ahb_slave (ahb_if.slave  ahbif);  // ← port named "ahbif"
//    module ahb_master(ahb_if.master bus);    // ← port named "bus"
//    module tb_top;
//        ahb_if bus(clk);
//        ahb_slave  s1 (.*);    // FAILS: no signal "ahbif" in this scope
//        ahb_master m1 (.*);    // works:  signal "bus" matches
//    end
// Fix: use named connection or rename the port.


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  4.8 — PROGRAM BLOCKS (Spear pushes them; UVM doesn't use them)           ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// A program block is a SV construct designed for testbenches:

program automatic test (example_if.master bus);
    initial begin
        @(bus.master_cb);
        bus.master_cb.data_out <= 8'hAA;
        // ... more transactions ...
        // No $finish needed — when initial completes, sim ends via implicit $exit
    end
endprogram : test

// Differences vs a plain `module`:
//
//   • Code runs in REACTIVE region (after RTL each cycle) → race-free even
//     without clocking blocks (still use them for clarity)
//   • `automatic` → variables are per-call (good for tasks)
//   • CANNOT contain `always` blocks or nested modules
//   • When all program initial blocks finish → simulation ends automatically
//
// Industry note: UVM testbenches use plain `module` for the top, NOT program.
// Program blocks have fallen out of favor — modern style is class-based TB
// inside a module. Spear teaches them; UVM ignores them.


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  COMPLETE MINI-EXAMPLE — putting it all together                          ║
// ╚══════════════════════════════════════════════════════════════════════════╝

interface bus_if (input bit clk);
    logic [7:0] addr;
    logic       valid;

    clocking cb @(posedge clk);
        output addr, valid;
    endclocking

    modport tb     (clocking cb);
    modport dut    (input clk, addr, valid);
    modport mon    (input clk, addr, valid);
endinterface

module dut_inst (bus_if.dut bus);
    always_ff @(posedge bus.clk)
        if (bus.valid) $display("DUT: addr=%0h", bus.addr);
endmodule

module driver_inst (bus_if.tb bus);
    initial begin
        @(bus.cb);  bus.cb.addr <= 8'h11; bus.cb.valid <= 1;
        @(bus.cb);  bus.cb.valid <= 0;
        @(bus.cb);  $finish;
    end
endmodule

module tb_top_example;
    bit clk; always #5 clk = ~clk;
    bus_if      bus(clk);
    dut_inst    dut(.bus(bus));
    driver_inst drv(.bus(bus));
endmodule


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  COMMON GOTCHAS                                                           ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
//   1) Mixing punctuation — clocking uses ;, modport uses , (see above).
//
//   2) Same clocking block in multiple modports — DON'T. The cb's directions
//      are absolute; if cb says "output addr", every modport using cb will
//      DRIVE addr. Two drivers = bus contention.
//      → Each role gets its own clocking block.
//
//   3) Slave/DUT clocking block — usually unnecessary. RTL `always_ff` is
//      already deterministic. Clocking blocks are for TB code that can race.
//
//   4) `endinterface : <label>` — label must match the interface name.
//      `interface foo;` then `endinterface : bar` is an error.
//
//   5) `.*` instantiation — port name must equal interface variable name.
//      Safer: use `.<port>(<signal>)` form.
//
//   6) xsim limitation — non-blocking `<=` to associative arrays is unsupported.
//      Use blocking `=` for those (a tool quirk, not an SV semantic issue).
//
//   7) Forgetting to drive bus signals to a known state at time 0 — protocol
//      assertions fire on `X` values. Park the bus in IDLE in the master's
//      first cycle.


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  COPY-PASTE INCANTATIONS                                                  ║
// ╚══════════════════════════════════════════════════════════════════════════╝

//   Wait one clock cycle (race-free, in the cb's deferred region):
//       @(bus.cb);
//
//   Wait N cycles:
//       repeat (N) @(bus.cb);
//
//   Drive a signal race-free:
//       bus.cb.<signal> <= <value>;
//
//   Sample a signal race-free:
//       <var> = bus.cb.<signal>;
//
//   Wait for a condition (race-free):
//       do  @(bus.cb);  while (!bus.cb.ready);
//
//   Module-style port using a modport:
//       module my_role (interface_name.modport_name bus);
//
//   Top-level instantiation pattern:
//       interface_name bus(clk);
//       my_master  m (.bus(bus));
//       my_dut     d (.bus(bus));
//       my_monitor n (.bus(bus));


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  WHAT'S NEXT (after ch.4)                                                 ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
//   - Spear ch.5  → OOP basics (classes, inheritance) — already covered week 1
//   - Spear ch.6  → Randomization
//   - Spear ch.8  → Threads & inter-process communication (mailboxes, semaphores)
//   - Salemi ch.10+ → UVM, where modports + virtual interfaces become essential
//
// Every UVM driver/monitor uses what's in this chapter. Master ch.4 → most
// of UVM's mechanics make sense.

// ============================================================================
// END OF CHEATSHEET
// ============================================================================
