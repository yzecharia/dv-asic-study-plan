# FSM Encoding and Coding Style

**Category**: FSM · **Used in**: W3, W10 (UART), W11 (SPI) · **Type**: authored

Two orthogonal decisions: **encoding** (how state values are
assigned) and **coding style** (how many `always` blocks). Get both
wrong and you have an FSM that synthesises with glitches, fails
timing, or is opaque to read.

## Encoding choice

| Encoding | When | Note |
|---|---|---|
| **Binary** (default) | small N states (≤ 8) | minimal flops |
| **One-hot** | large N (≥ 16), Fmax-critical | one flop per state; next-state logic is faster |
| **Gray** | rare in pure FSM; useful only when state itself crosses CDC | `[[gray_code_pointers]]` |
| **One-cold** | inverse of one-hot, no real advantage today | legacy |

For RV32I-tier control units (≤16 states), binary is fine. For UART
or SPI (≤8 states), binary. For a 32-state video pipeline scheduler,
one-hot.

## Coding style

Cummings SNUG-2003 names three styles. Pick by team standard or by
what's clearer to read:

### Three-block style (cleanest, most common at NVIDIA/Apple)

```systemverilog
typedef enum logic [1:0] {S_IDLE, S_TX, S_DONE} state_t;
state_t state, next;

// 1) State register
always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) state <= S_IDLE; else state <= next;

// 2) Next-state logic (combinational)
always_comb begin
    next = state;
    case (state)
        S_IDLE: if (start) next = S_TX;
        S_TX  : if (done)  next = S_DONE;
        S_DONE: next = S_IDLE;
    endcase
end

// 3) Output logic (Moore — registered or combinational from state)
assign tx_active_o = (state == S_TX);
```

### Two-block style

State register + combined next-state-and-output `always_comb`. Saves
one block; mixes concerns. Acceptable for tiny FSMs.

### One-block (single registered) style

Everything in `always_ff`. Outputs are registered (good for timing)
but the next-state and output logic are entangled (bad for reading).
Common in some legacy codebases. The user has asked to practise
this style — use it specifically for the W3 traffic-light FSM
exercise to get a feel.

```systemverilog
// One-block style example
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state        <= S_IDLE;
        tx_active_o  <= 1'b0;
    end else begin
        case (state)
            S_IDLE: if (start) begin
                state        <= S_TX;
                tx_active_o  <= 1'b1;
            end
            S_TX  : if (done) begin
                state        <= S_DONE;
                tx_active_o  <= 1'b0;
            end
            S_DONE: state    <= S_IDLE;
        endcase
    end
end
```

## Glitch-free outputs

Moore outputs taken combinationally from `state` will glitch on
state transitions. To avoid:

- Register the output (one-block style does this naturally).
- One-hot encode and assign the output as a single state-bit
  (`assign tx_active_o = state[1];`). This is the cleanest.
- Cummings SNUG-2010 covers this pattern in detail.

## Reading

- Cummings *Synthesizable Finite State Machine Design Techniques*,
  SNUG-2003.
- Cummings *Coding And Scripting Techniques For FSM Designs*,
  SNUG-2010 — glitch-free outputs.
- Sutherland *RTL Modeling with SystemVerilog* FSM ch.

## Cross-links

- `[[fsm_moore_mealy]]`
- `[[multiplexers_decoders]]` — one-hot encoding ≈ unary state vector.
