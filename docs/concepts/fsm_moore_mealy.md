# FSMs — Moore vs Mealy

**Category**: FSM · **Used in**: W3, W10, W11 · **Type**: auto-stub

A **Moore** FSM has outputs that depend only on the current state.
A **Mealy** FSM has outputs that depend on current state **and**
current inputs. Mealy can react one cycle faster but creates
combinational paths from input to output that are harder to time
and prone to glitches.

## Trade-off summary

| | Moore | Mealy |
|---|---|---|
| Output depends on | state only | state + input |
| Latency to react | 1 cycle | 0 cycles (combinational) |
| Glitch risk | low (registered output) | high (input-dependent) |
| Timing analysis | simple | input-to-output path adds to critical path |
| Default choice | **prefer this** | only when latency demands it |

## Reading

- Cummings *Synthesizable FSM Design Techniques*, SNUG-2003.
- Sutherland *RTL Modeling with SystemVerilog* FSM ch.

## SV skeleton (Moore, registered outputs)

```systemverilog
typedef enum logic [1:0] {S_IDLE, S_RUN, S_DONE} state_t;
state_t state, next;

always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) state <= S_IDLE; else state <= next;

always_comb begin
    next = state;
    case (state)
        S_IDLE: if (start) next = S_RUN;
        S_RUN : if (done)  next = S_DONE;
        S_DONE: next = S_IDLE;
    endcase
end

// Moore output: depends only on state
assign run_o = (state == S_RUN);
```

## Cross-links

- `[[fsm_encoding_styles]]` — one-block vs multi-block style.
- `[[multiplexers_decoders]]`
