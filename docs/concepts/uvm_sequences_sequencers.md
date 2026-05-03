# UVM Sequences and Sequencers

**Category**: UVM · **Used in**: W6 (anchor), W12, W14, W20 · **Type**: authored

Sequences are *what* to send. Sequencers are *who arbitrates* between
multiple concurrent sequences targeting the same driver. Drivers
just pull `req` and put back `rsp` — they don't know which sequence
generated the transaction.

## Three layers

```
┌─────────────────────┐
│ Sequence            │  Generates uvm_sequence_items
│  (a class)          │  via `uvm_do / `uvm_create + `uvm_send
└──────┬──────────────┘
       │ start_item / finish_item
       ▼
┌─────────────────────┐
│ Sequencer           │  Arbitrates between sequences;
│  (a uvm_sequencer)  │  acts as a TLM port for the driver.
└──────┬──────────────┘
       │ get_next_item / item_done
       ▼
┌─────────────────────┐
│ Driver              │  Pulls items, drives the DUT pins.
│  (a uvm_driver)     │
└─────────────────────┘
```

## Sequence skeleton

```systemverilog
class write_burst_seq extends uvm_sequence #(axi_lite_seq_item);
    `uvm_object_utils(write_burst_seq)
    rand int unsigned num_items;
    constraint c_num { num_items inside {[10:50]}; }

    task body();
        repeat (num_items) begin
            axi_lite_seq_item item;
            `uvm_do_with(item, { kind == AXI_WRITE; addr inside {[32'h0:32'hFF]}; })
        end
    endtask
endclass
```

## Layered / virtual sequences (W14, W20)

When you have multiple UVCs (e.g. AXI-Lite + UART), each with its
own sequencer, a **virtual sequence** orchestrates across them. The
virtual sequence runs on a **virtual sequencer** that holds handles
to all the per-UVC sequencers.

```systemverilog
class my_virtual_seq extends uvm_sequence;
    `uvm_object_utils(my_virtual_seq)
    `uvm_declare_p_sequencer(my_virtual_sequencer)

    task body();
        write_axi_seq w = write_axi_seq::type_id::create("w");
        send_uart_seq u = send_uart_seq::type_id::create("u");
        fork
            w.start(p_sequencer.axi_seqr);
            u.start(p_sequencer.uart_seqr);
        join
    endtask
endclass
```

This is the W20 capstone pattern.

## Sequence item vs sequence

- `uvm_sequence_item` — one transaction (e.g. one AXI write).
- `uvm_sequence` — a recipe that emits N transactions, possibly
  randomised, possibly conditional on responses.

A driver only sees `uvm_sequence_item` instances — it has no notion
of which sequence sent it.

## Reading

- Salemi ch.20–22 (transactions, agents, sequences), pp. ~155–195
  (verify).
- Rosenberg ch.4 — virtual sequence patterns.

## Cross-links

- `[[uvm_phases]]` — sequences run in `run_phase`.
- `[[uvm_factory_config_db]]` — sequences are factory-registered objects.
- `[[uvm_scoreboard]]` — scoreboard receives items via analysis port.
