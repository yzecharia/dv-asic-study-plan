# SPI Protocol

**Category**: Protocols · **Used in**: W11 · **Type**: authored

Synchronous serial protocol with a master clock (`SCK`), separate
data lines for master-out (`MOSI`) and master-in (`MISO`), and a
chip-select per slave. **Four modes** cover the combinations of
clock polarity and clock phase.

## Modes (CPOL / CPHA)

| Mode | CPOL | CPHA | SCK idle | MOSI sampled on | MISO sampled on |
|---|---|---|---|---|---|
| 0 | 0 | 0 | low | rising | rising |
| 1 | 0 | 1 | low | falling | falling |
| 2 | 1 | 0 | high | falling | falling |
| 3 | 1 | 1 | high | rising | rising |

Mode 0 and Mode 3 are the most common on real silicon.

## Master FSM (W11 design HW)

```
S_IDLE → drop SS → emit SCK edges and shift bits → raise SS → S_IDLE
```

Per bit: master shifts MOSI on the **shift edge** and samples MISO
on the **sample edge**. CPHA=0 means sample = first edge after SS
falls; CPHA=1 means sample = second edge.

## SV skeleton (Mode 0, master, 8-bit transfer)

```systemverilog
typedef enum logic [1:0] {S_IDLE, S_SHIFT, S_DONE} spist_t;
spist_t state;
logic [3:0] bit_cnt;
logic [7:0] shift_tx, shift_rx;
logic       sck_int;

// Half-period clock divider for SCK
// (omitted: a counter that toggles sck_int every N source clocks)

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_IDLE; ss_n <= 1'b1; sck <= 1'b0; bit_cnt <= '0;
    end else begin
        case (state)
            S_IDLE: if (start) begin
                shift_tx <= mosi_data;
                ss_n     <= 1'b0;
                bit_cnt  <= 4'd8;
                state    <= S_SHIFT;
            end
            S_SHIFT: begin
                // Mode 0: shift on falling SCK edge, sample on rising
                if (sck_falling) begin
                    mosi     <= shift_tx[7];
                    shift_tx <= shift_tx << 1;
                end
                if (sck_rising) begin
                    shift_rx <= {shift_rx[6:0], miso};
                    bit_cnt  <= bit_cnt - 1;
                    if (bit_cnt == 4'd1) state <= S_DONE;
                end
            end
            S_DONE: begin
                ss_n <= 1'b1;
                miso_data <= shift_rx;
                done <= 1'b1;
                state <= S_IDLE;
            end
        endcase
    end
end
```

## Verification (W11)

- Mode-aware self-checking TB: parameterize the TB's reference SPI
  slave by `(CPOL, CPHA)`; sweep all 4 modes per regression.
- Functional coverage: mode × payload byte × SS gap.
- SVA: SS must be low for the entire 8-cycle transfer; SCK must
  toggle exactly 8 times between SS-low and SS-high.

## Reading

- Nandland SPI tutorial (free, well-illustrated).
- Manufacturer datasheets (e.g. Microchip 25xx EEPROM) for real
  command framing examples.

## Cross-links

- `[[fsm_encoding_styles]]` — clean three-block FSM for the master.
- `[[uart_protocol]]` — comparison: synchronous vs asynchronous serial.
