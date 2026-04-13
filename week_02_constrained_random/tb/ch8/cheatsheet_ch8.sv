// ============================================================================
// Chapter 8 Cheatsheet: Advanced OOP
// Spear & Tumbush "SystemVerilog for Verification" (3rd ed)
// ============================================================================


// ============================================================================
// §8.1 INHERITANCE
// ============================================================================
// A child class "extends" a parent class, inheriting all its fields and methods.
// The child can add new fields/methods or override existing ones.

class Transaction;
    rand bit [7:0] src, dst;
    rand bit [31:0] data;

    function new(bit [7:0] src=0, bit [7:0] dst=0);
        this.src = src;
        this.dst = dst;
    endfunction

    virtual function void display(string prefix="");
        $display("%s src=%0h dst=%0h data=%0h", prefix, src, dst, data);
    endfunction
endclass

// BadTransaction inherits src, dst, data, display() from Transaction
// and adds its own field + overrides display()
class BadTransaction extends Transaction;
    rand bit corrupt_crc;

    function new(bit [7:0] src=0, bit [7:0] dst=0);
        super.new(src, dst);  // MUST call parent constructor
    endfunction

    virtual function void display(string prefix="");
        super.display(prefix);  // call parent's display first
        $display("  corrupt_crc=%0b", corrupt_crc);
    endfunction
endclass


// ============================================================================
// §8.2 SUPER keyword
// ============================================================================
// "super" refers to the parent class.
// super.new()       — call parent constructor (MUST be first line in new())
// super.method()    — call parent's version of a method
// super.field       — access parent's field (rarely needed)

class DelayedTransaction extends Transaction;
    rand int delay;

    constraint c_delay { delay inside {[1:10]}; }

    function new(bit [7:0] src=0, bit [7:0] dst=0);
        super.new(src, dst);  // parent constructor
        delay = 1;            // child-specific init
    endfunction

    virtual function void display(string prefix="");
        super.display(prefix);          // reuse parent's display
        $display("  delay=%0d", delay); // add child-specific info
    endfunction
endclass


// ============================================================================
// §8.3 POLYMORPHISM with virtual methods
// ============================================================================
// A parent handle can point to a child object.
// "virtual" makes method dispatch based on ACTUAL OBJECT TYPE (runtime),
// not the HANDLE TYPE (compile time).

// Without virtual: parent_handle.display() → always calls parent's display()
// With virtual:    parent_handle.display() → calls child's display() if object is child

// Example:
//   Transaction tr;            // parent handle
//   BadTransaction bad = new();
//   tr = bad;                  // parent handle → child object (upcast, always OK)
//   tr.display();              // calls BadTransaction.display() because "virtual"


// ============================================================================
// §8.4 CONSTRUCTORS in inheritance chains
// ============================================================================
// - Child's new() MUST call super.new() as the FIRST statement
// - If parent new() has no required args, super.new() is called implicitly
// - Constructor args are NOT inherited — child defines its own new()

class Packet extends Transaction;
    rand bit [3:0] length;

    function new(bit [7:0] src=0, bit [7:0] dst=0, bit [3:0] length=0);
        super.new(src, dst);       // must come first
        this.length = length;
    endfunction
endclass


// ============================================================================
// §8.5 COPYING extended objects
// ============================================================================
// Shallow copy: handle assignment — both handles point to SAME object
// Deep copy:    create a new object with same field values

// The copy() method pattern:
//   - Return type is the BASE class (for polymorphism)
//   - Inside, create the ACTUAL type
//   - Copy all fields (including parent's)

class CopyableTransaction extends Transaction;
    rand int tag;

    function new(bit [7:0] src=0, bit [7:0] dst=0);
        super.new(src, dst);
    endfunction

    // Returns Transaction handle, but actual object is CopyableTransaction
    virtual function Transaction copy();
        CopyableTransaction cpy = new(src, dst);
        cpy.data = this.data;
        cpy.tag  = this.tag;
        return cpy;
    endfunction
endclass

// Usage:
//   CopyableTransaction a = new(8'hAA, 8'hBB);
//   a.randomize();
//   Transaction b_handle = a.copy();         // deep copy, returns base handle
//   CopyableTransaction b;
//   $cast(b, b_handle);                      // downcast to access child fields


// ============================================================================
// §8.6 ABSTRACT (virtual) CLASSES
// ============================================================================
// A "virtual class" cannot be instantiated — only extended.
// "pure virtual" methods have NO body — children MUST implement them.

virtual class BaseTransaction;
    pure virtual function void display(string prefix="");
    pure virtual function BaseTransaction copy();
    pure virtual function bit compare(BaseTransaction rhs);

    // Non-pure virtual methods CAN have a default body
    virtual function string get_type();
        return "BaseTransaction";
    endfunction
endclass

// BaseTransaction bt = new();  ← COMPILE ERROR: can't instantiate virtual class

class EthernetFrame extends BaseTransaction;
    rand bit [47:0] mac_src, mac_dst;
    rand bit [15:0] ethertype;

    // MUST implement all pure virtual methods, or compile error
    virtual function void display(string prefix="");
        $display("%s ETH src=%0h dst=%0h type=%0h", prefix, mac_src, mac_dst, ethertype);
    endfunction

    virtual function BaseTransaction copy();
        EthernetFrame cpy = new();
        cpy.mac_src   = this.mac_src;
        cpy.mac_dst   = this.mac_dst;
        cpy.ethertype = this.ethertype;
        return cpy;
    endfunction

    virtual function bit compare(BaseTransaction rhs);
        EthernetFrame rhs_eth;
        if (!$cast(rhs_eth, rhs)) return 0;
        return (mac_src == rhs_eth.mac_src) &&
               (mac_dst == rhs_eth.mac_dst) &&
               (ethertype == rhs_eth.ethertype);
    endfunction

    virtual function string get_type();
        return "EthernetFrame";  // override default
    endfunction
endclass


// ============================================================================
// §8.7 $CAST — downcasting
// ============================================================================
// Upcast (child → parent): always allowed with =
//   Transaction tr = bad;     // OK
//
// Downcast (parent → child): MUST use $cast
//   bad = tr;                 // COMPILE ERROR
//   $cast(bad, tr);           // OK — runtime check
//
// $cast returns 1 on success, 0 on failure
// If called as a task (no return check), failure is a runtime error

// Example: Scoreboard receives base handle, needs to access child fields
//
//   function void check(Transaction tr);
//       BadTransaction bad;
//       if ($cast(bad, tr)) begin
//           // tr actually points to a BadTransaction object
//           $display("corrupt_crc = %0b", bad.corrupt_crc);
//       end else begin
//           // tr points to a plain Transaction — no corrupt_crc field
//           $display("Normal transaction");
//       end
//   endfunction


// ============================================================================
// §8.8 PARAMETERIZED CLASSES
// ============================================================================
// Classes can have type parameters, like C++ templates.
// Allows writing one class that works with any data type.

class Stack #(type T=int, int SIZE=100);
    T items[SIZE];
    int top = 0;

    function void push(T item);
        if (top < SIZE) items[top++] = item;
        else $display("Stack overflow!");
    endfunction

    function T pop();
        if (top > 0) return items[--top];
        else begin
            $display("Stack underflow!");
            return items[0]; // dummy return
        end
    endfunction

    function int size();
        return top;
    endfunction
endclass

// Usage:
//   Stack #(int)              int_stack  = new();  // stack of ints
//   Stack #(real)             real_stack = new();  // stack of reals
//   Stack #(Transaction, 50)  tr_stack   = new();  // stack of 50 Transactions

// Parameterized mailbox (typed):
//   mailbox #(Transaction) mbx = new();
//   mbx.put(tr);          // only accepts Transaction or children
//   mbx.get(tr);          // returns Transaction handle


// ============================================================================
// §8.9 STATIC MEMBERS with inheritance
// ============================================================================
// Static fields belong to the CLASS, not to any object.
// All objects of that class share the same static field.
// Static fields are NOT inherited as separate copies — child shares parent's.

class CountedTransaction extends Transaction;
    static int count = 0;  // shared by ALL CountedTransaction objects

    function new(bit [7:0] src=0, bit [7:0] dst=0);
        super.new(src, dst);
        count++;  // increment every time an object is created
    endfunction

    static function int get_count();
        return count;
    endfunction
endclass

// Usage:
//   CountedTransaction a = new();  // count = 1
//   CountedTransaction b = new();  // count = 2
//   CountedTransaction c = new();  // count = 3
//   $display("Created %0d transactions", CountedTransaction::count);  // 3
//
// Note: CountedTransaction::count uses scope resolution (::)
//       to access static member without an object handle.


// ============================================================================
// §8.10 CALLBACKS
// ============================================================================
// Callbacks let you inject test-specific behavior into reusable components
// WITHOUT modifying them. The component has "hooks" (empty virtual methods)
// that the test can override.

// Step 1: Define callback base class with empty virtual methods
class DriverCallbacks;
    virtual task pre_send(Transaction tr);
        // default: do nothing
    endtask

    virtual task post_send(Transaction tr);
        // default: do nothing
    endtask
endclass

// Step 2: Driver has a queue of callbacks, calls them at hook points
class Driver;
    mailbox #(Transaction) mbx;
    DriverCallbacks cbs[$];  // queue of callback objects

    function new(mailbox #(Transaction) mbx);
        this.mbx = mbx;
    endfunction

    task run();
        Transaction tr;
        while (mbx.num() > 0) begin
            mbx.get(tr);

            // PRE-SEND HOOK: call all registered callbacks
            foreach (cbs[i]) cbs[i].pre_send(tr);

            // Send transaction (simplified — would drive interface signals)
            tr.display("[DRV]");

            // POST-SEND HOOK: call all registered callbacks
            foreach (cbs[i]) cbs[i].post_send(tr);
        end
    endtask
endclass

// Step 3: Test creates custom callbacks by extending base class
class ErrorInjectionCb extends DriverCallbacks;
    virtual task pre_send(Transaction tr);
        if ($urandom_range(0,9) == 0)
            tr.data[0] = ~tr.data[0];  // flip bit on 10% of transactions
    endtask
endclass

class TransactionCounterCb extends DriverCallbacks;
    int count = 0;
    virtual task post_send(Transaction tr);
        count++;
    endtask
endclass

// Step 4: Test plugs callbacks into driver
//   ErrorInjectionCb    err_cb = new();
//   TransactionCounterCb cnt_cb = new();
//   drv.cbs.push_back(err_cb);    // register error injector
//   drv.cbs.push_back(cnt_cb);    // register counter
//   drv.run();                     // driver calls both at each hook point
//
// Key benefit: Driver code NEVER changes. Each test plugs in different
// callbacks for different behavior.


// ============================================================================
// §8.4 (expanded) COMPOSITION vs INHERITANCE vs FLAT CLASS
// ============================================================================

// INHERITANCE (is-a): EthernetVLAN IS-A EthernetFrame
class EthernetVLAN extends EthernetFrame;
    rand bit [11:0] vlan_id;
    rand bit [2:0]  vlan_prio;
endclass

// COMPOSITION (has-a): PacketWithHeader HAS-A header and payload
class Header;
    rand bit [7:0] src, dst;
    rand bit [3:0] prio;
endclass

class Payload;
    rand bit [7:0] data[];
    constraint c_size { data.size() inside {[1:64]}; }
endclass

class PacketWithHeader;
    rand Header  hdr;   // has-a header
    rand Payload pld;   // has-a payload

    function new();
        hdr = new();
        pld = new();
    endfunction
endclass

// FLAT CLASS (discriminant): one class with conditional constraints
class FlatPacket;
    typedef enum {NORMAL, VLAN, JUMBO} packet_kind_e;
    rand packet_kind_e kind;
    rand bit [47:0] mac_src, mac_dst;
    rand bit [11:0] vlan_id;
    rand bit [7:0]  data[];

    constraint c_vlan {
        if (kind == VLAN)  vlan_id inside {[1:4094]};
        else               vlan_id == 0;
    }
    constraint c_size {
        if (kind == JUMBO) data.size() inside {[1501:9000]};
        else               data.size() inside {[46:1500]};
    }
endclass

// When to use which:
// - Inheritance:  when child IS a specialization of parent, shares interface
// - Composition:  when object CONTAINS other objects, more flexible
// - Flat class:   when variants are simple and few, easiest to randomize


// ============================================================================
// BLUEPRINT PATTERN (§8.1 + §8.3)
// ============================================================================
// Generator stores a Transaction handle called "blueprint".
// Each iteration: copy blueprint, randomize the copy, send it.
// Test can swap blueprint with ANY extended type → different transactions
// without modifying the Generator.

class Generator;
    Transaction blueprint;  // handle to prototype object
    mailbox #(Transaction) mbx;

    function new(mailbox #(Transaction) mbx);
        this.mbx = mbx;
        blueprint = new();  // default blueprint
    endfunction

    task run(int count);
        Transaction tr;
        repeat (count) begin
            tr = blueprint.copy();  // deep copy the blueprint
            assert(tr.randomize()); // randomize the copy
            mbx.put(tr);           // send to driver
        end
    endtask
endclass

// Test swaps blueprint:
//   Generator gen = new(mbx);
//   BadTransaction bad = new();
//   gen.blueprint = bad;          // swap! (upcast: child → parent handle)
//   gen.run(100);                 // now generates BadTransactions
//
// Polymorphism makes this work:
//   blueprint.copy() calls BadTransaction.copy() (virtual dispatch)
//   blueprint.randomize() randomizes BadTransaction fields too


// ============================================================================
// SCOREBOARD PATTERN (§8.3 + §8.7)
// ============================================================================
// Stores expected transactions, compares against actual DUT output.

class Scoreboard;
    Transaction expected[$];  // queue of expected transactions
    int pass_count, fail_count;

    function void add_expected(Transaction tr);
        expected.push_back(tr);
    endfunction

    function void compare_actual(Transaction actual);
        int q[$];
        // find_index: search queue for matching src field
        q = expected.find_index(x) with (x.src == actual.src);

        case (q.size())
            0: begin
                // No match: DUT produced something unexpected
                $display("[SCB] FAIL: unexpected transaction src=%0h", actual.src);
                fail_count++;
            end
            1: begin
                // One match: compare all fields, then remove from queue
                if (expected[q[0]].compare(actual)) begin
                    $display("[SCB] PASS");
                    pass_count++;
                end else begin
                    $display("[SCB] FAIL: data mismatch");
                    fail_count++;
                end
                expected.delete(q[0]);
            end
            default: begin
                // Multiple matches: ambiguous — scoreboard design issue
                $display("[SCB] ERROR: %0d matches for src=%0h", q.size(), actual.src);
                fail_count++;
            end
        endcase
    endfunction

    function void report();
        $display("[SCB] Results: %0d passed, %0d failed", pass_count, fail_count);
        if (expected.size() > 0)
            $display("[SCB] WARNING: %0d expected transactions never received", expected.size());
    endfunction
endclass


// ============================================================================
// ENVIRONMENT PATTERN (§8.1)
// ============================================================================
// Assembles all components, connects them, runs them in parallel.

class Environment;
    Generator  gen;
    Driver     drv;
    Scoreboard scb;
    mailbox #(Transaction) gen2drv;

    virtual function void build();
        gen2drv = new();
        gen = new(gen2drv);
        drv = new(gen2drv);
        scb = new();
    endfunction

    virtual task run();
        fork
            gen.run(10);
            drv.run();
        join_any
        disable fork;
    endtask

    virtual task wrap_up();
        scb.report();
    endtask
endclass

// Test:
//   Environment env = new();
//   env.build();
//   // optionally: env.gen.blueprint = new BadTransaction();
//   // optionally: env.drv.cbs.push_back(new ErrorInjectionCb());
//   env.run();
//   env.wrap_up();


// ============================================================================
// QUICK REFERENCE TABLE
// ============================================================================
//
// CONCEPT              KEYWORD/SYNTAX                  WHEN TO USE
// ─────────────────────────────────────────────────────────────────────
// Inheritance          class B extends A               child is-a parent
// Parent constructor   super.new(args)                 first line of child new()
// Parent method call   super.method()                  reuse parent logic in override
// Virtual method       virtual function/task           enable polymorphism
// Abstract class       virtual class                   can't instantiate, only extend
// Pure virtual method  pure virtual function/task      child MUST implement
// Downcast             $cast(child_h, parent_h)        access child fields from parent handle
// Parameterized class  class Foo #(type T=int)         generic/reusable containers
// Static member        static int count                shared across all objects
// Scope resolution     ClassName::static_member        access static without object
// Callback             virtual task in base class      inject test behavior into components
// Blueprint            handle to prototype object      swap transaction types per test
// Deep copy            virtual function copy()         independent copy for scoreboard
//
// HANDLE RULES:
//   parent_h = child_obj     ← UPCAST:   always OK with =
//   child_h  = parent_h      ← DOWNCAST: must use $cast()
//   child_h  = child_obj     ← SAME TYPE: always OK with =
