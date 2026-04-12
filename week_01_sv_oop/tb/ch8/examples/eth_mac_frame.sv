// ============================================================================
// Chapter 8, Section 8.4 — Composition, Inheritance, and Alternatives
// ============================================================================
// This file demonstrates ALL THREE approaches to building an Ethernet MAC
// frame class, using the book's real-world example.
//
// Ethernet has two flavors:
//   - Normal (Type II):  DA, SA, etype, payload, fcs
//   - VLAN (802.1Q):     DA, SA, TPID, TCI(vlan_id + prio), etype, payload, fcs
//
// Three ways to model this:
//   1. COMPOSITION   — EthMacFrame HAS-A VlanInfo object
//   2. INHERITANCE   — EthVlanFrame IS-A EthMacFrame (with extra fields)
//   3. FLAT CLASS    — one class with a discriminant (kind) + conditional constraints
//
// The book concludes: for testbench transactions, the FLAT class is usually best.
// ============================================================================


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  APPROACH 1: COMPOSITION (has-a)                                       ║
// ║  EthMacFrame "has-a" VlanInfo object inside it                         ║
// ╚══════════════════════════════════════════════════════════════════════════╝

class VlanInfo;
    rand bit [2:0]  prio;       // 802.1Q prio (0-7)
    rand bit [11:0] vlan_id;        // VLAN ID (0-4095)

    constraint c_valid {
        vlan_id inside {[1:4094]};  // 0 and 4095 are reserved
    }

    function void display(string prefix = "");
        $display("%s  VlanInfo: prio=%0d, vlan_id=%0d", prefix, prio, vlan_id);
    endfunction
endclass


class EthMacComp;  // "Comp" = composition approach
    typedef enum {NORMAL, VLAN} kind_t;

    rand kind_t       kind;
    rand bit [47:0]   da, sa;           // destination & source address
    rand bit [15:0]   etype;            // EtherType (e.g. 0x0800 = IPv4)
    rand bit [7:0]    payload[];        // variable-size payload
    bit [31:0]        fcs;              // frame check sequence (computed)

    // ─── Composition: a handle to VlanInfo ────────────────
    VlanInfo          vlan_h;           // only meaningful when kind == VLAN

    constraint c_payload {
        payload.size() inside {[46:1500]};  // IEEE 802.3 min/max
    }

    function new();
        // PROBLEM #1: must always construct vlan_h because kind isn't
        // known yet (it's random). If we skip it, randomization of
        // vlan_h fields would fail when kind == VLAN.
        vlan_h = new();
    endfunction

    function void display(string prefix = "");
        $display("%s[COMP] kind=%s, da=%h, sa=%h, etype=%h, payload_size=%0d",
                 prefix, kind.name(), da, sa, etype, payload.size());
        if (kind == VLAN)
            // PROBLEM #2: extra hierarchy → vlan_h.vlan_id, vlan_h.prio
            // If you nest deeper, names get very long: eth.vlan_h.vlan_id
            vlan_h.display(prefix);
    endfunction
endclass


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  APPROACH 2: INHERITANCE (is-a)                                        ║
// ║  EthVlanFrame IS-A EthMacFrame with extra VLAN fields                  ║
// ╚══════════════════════════════════════════════════════════════════════════╝

class EthMacInherit;  // base: normal frame
    rand bit [47:0]   da, sa;
    rand bit [15:0]   etype;
    rand bit [7:0]    payload[];
    bit [31:0]        fcs;

    constraint c_payload {
        payload.size() inside {[46:1500]};
    }

    virtual function void display(string prefix = "");
        $display("%s[INHERIT] da=%h, sa=%h, etype=%h, payload_size=%0d",
                 prefix, da, sa, etype, payload.size());
    endfunction
endclass


class EthVlanFrame extends EthMacInherit;  // extended: VLAN frame
    // No extra hierarchy — vlan_id and prio are direct fields
    rand bit [2:0]  prio;
    rand bit [11:0] vlan_id;

    constraint c_vlan {
        vlan_id inside {[1:4094]};
    }

    // Override display — can access vlan_id directly (no .vlan_h. needed)
    virtual function void display(string prefix = "");
        $display("%s[INHERIT-VLAN] da=%h, sa=%h, etype=%h, vlan_id=%0d, prio=%0d, payload_size=%0d",
                 prefix, da, sa, etype, vlan_id, prio, payload.size());
    endfunction
endclass

// PROBLEM with inheritance:
//   - Need $cast when assigning base handle to extended handle
//   - Can't do multiple inheritance (e.g. VLAN+SNAP+Control frame)
//   - Can't have ONE constraint that randomly picks normal vs VLAN
//     (the type is decided at construction time, not randomization time)
//   - All virtual methods must have matching signatures across the hierarchy


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  APPROACH 3: FLAT CLASS (the real-world alternative)                    ║
// ║  One class with discriminant + conditional constraints                  ║
// ║  This is what the book recommends for testbench transactions.           ║
// ╚══════════════════════════════════════════════════════════════════════════╝

class EthMacFlat;
    typedef enum {NORMAL, VLAN} kind_t;

    // ─── Discriminant: which flavor of frame? ─────────────
    rand kind_t       kind;

    // ─── Common fields (always present) ───────────────────
    rand bit [47:0]   da, sa;
    rand bit [15:0]   etype;
    rand bit [7:0]    payload[];
    bit [31:0]        fcs;

    // ─── VLAN-only fields (valid only when kind == VLAN) ──
    rand bit [2:0]    prio;
    rand bit [11:0]   vlan_id;

    // ─── Constraints ──────────────────────────────────────
    constraint c_payload {
        payload.size() inside {[46:1500]};
    }

    // Conditional constraint: VLAN fields only matter when kind == VLAN
    constraint c_vlan {
        if (kind == VLAN) {
            vlan_id inside {[1:4094]};
        } else {
            // When NORMAL, zero out VLAN fields for cleanliness
            vlan_id  == 0;
            prio == 0;
        }
    }

    // ─── Easy distribution control from tests ─────────────
    constraint c_kind_dist {
        kind dist {NORMAL := 50, VLAN := 50};   // 50/50 by default
    }

    // ─── Single display — no extra hierarchy, no $cast ────
    function void display(string prefix = "");
        if (kind == VLAN)
            $display("%s[FLAT] kind=VLAN, da=%h, sa=%h, etype=%h, vlan_id=%0d, prio=%0d, payload_size=%0d",
                     prefix, da, sa, etype, vlan_id, prio, payload.size());
        else
            $display("%s[FLAT] kind=NORMAL, da=%h, sa=%h, etype=%h, payload_size=%0d",
                     prefix, da, sa, etype, payload.size());
    endfunction

    function void compute_fcs();
        fcs = da[31:0] ^ da[47:32] ^ sa[31:0] ^ sa[47:32] ^ etype;
        foreach (payload[i]) fcs ^= payload[i];
        if (kind == VLAN) fcs ^= {prio, vlan_id};
    endfunction
endclass


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  TEST PROGRAM                                                          ║
// ╚══════════════════════════════════════════════════════════════════════════╝
program automatic test;

    initial begin

        // ════════════════════════════════════════════════════
        // Test 1: COMPOSITION approach
        // ════════════════════════════════════════════════════
        $display("\n========== APPROACH 1: COMPOSITION ==========");
        begin
            EthMacComp frame;
            repeat (4) begin
                frame = new();
                assert(frame.randomize());
                frame.display("  ");
            end
            // Notice: to access VLAN fields you always write
            // frame.vlan_h.vlan_id — extra hierarchy layer.
            // Also: vlan_h is always constructed even for NORMAL frames (wasteful).
        end

        // ════════════════════════════════════════════════════
        // Test 2: INHERITANCE approach
        // ════════════════════════════════════════════════════
        $display("\n========== APPROACH 2: INHERITANCE ==========");
        begin
            EthMacInherit base_frame;
            EthVlanFrame  vlan_frame;

            // Normal frame
            base_frame = new();
            assert(base_frame.randomize());
            base_frame.display("  ");

            // VLAN frame
            vlan_frame = new();
            assert(vlan_frame.randomize());
            vlan_frame.display("  ");

            // Polymorphism works — base handle pointing to VLAN object
            base_frame = vlan_frame;
            base_frame.display("  (via base handle) ");

            // But to access vlan_id, you NEED $cast:
            // base_frame.vlan_id → COMPILE ERROR (base doesn't have it)
            // Must do:
            begin
                EthVlanFrame casted;
                if ($cast(casted, base_frame))
                    $display("  $cast OK: vlan_id=%0d", casted.vlan_id);
            end

            // Problem: can't randomly choose normal vs VLAN at randomization time.
            // The type is fixed at construction (new() vs new VlanFrame()).
        end

        // ════════════════════════════════════════════════════
        // Test 3: FLAT CLASS (recommended approach)
        // ════════════════════════════════════════════════════
        $display("\n========== APPROACH 3: FLAT (RECOMMENDED) ==========");
        begin
            EthMacFlat frame = new();

            // Randomize 6 frames — kind is randomly NORMAL or VLAN
            repeat (6) begin
                assert(frame.randomize());
                frame.display("  ");
            end

            // Override: force only VLAN frames with inline constraint
            $display("\n  --- Forcing VLAN only (inline constraint) ---");
            repeat (3) begin
                assert(frame.randomize() with { kind == EthMacFlat::VLAN; });
                frame.display("  ");
            end

            // Override: force only NORMAL frames
            $display("\n  --- Forcing NORMAL only (inline constraint) ---");
            repeat (3) begin
                assert(frame.randomize() with { kind == EthMacFlat::NORMAL; });
                frame.display("  ");
            end
        end

        $display("\n========== DONE ==========");
    end

endprogram : test
