# UART Protocol

**Category**: Protocols · **Used in**: W10, W12 portfolio · **Type**: authored

A UART (Universal Asynchronous Receiver/Transmitter) is the simplest
serial protocol: a single wire per direction, no clock, with timing
recovered from the start bit and a fixed bit period (the **baud
rate**).

## Frame format

```
Idle    Start  bit0 bit1 ... bit7  [Parity]  Stop  Stop  Idle
1       0      ↑LSB...MSB↑         optional  1     opt   1
```

| Field | Width | Notes |
|---|---|---|
| Start | 1 bit, always 0 | RX detects the falling edge to start |
| Data | typically 8 bits, LSB first | 5–9 bits configurable |
| Parity | optional, 1 bit | even, odd, mark, space |
| Stop | 1 or 2 bits, always 1 | "stop" really means line returns to idle |

## Baud rate

Both ends must agree on the bit period. Common rates: 9600, 115200,
3 Mbaud. The TX simply emits each bit for `1 / baud` seconds. The RX
**oversamples** the line at typically 16× the baud rate to recover
the bit centres reliably.

## RX — 16× oversampling

```
Line:    1111 1000 0000 0000 1111 1111 1111 ...
Sample:                ↑    (mid-bit position of the start bit)
```

Algorithm:

1. Wait for line going low.
2. Sample 8 cycles later — confirm still low (or it was a glitch,
   abort).
3. From there, sample every 16 oversample cycles to capture each
   data bit at its centre.
4. After all data bits, sample the parity bit (if used) and the
   stop bit. If stop bit is 0 → **framing error**.

## SV TX skeleton (W10)

```systemverilog
typedef enum logic [1:0] {S_IDLE, S_DATA, S_STOP} txst_t;
txst_t state;
logic [3:0] bit_idx;
logic [3:0] baud_div;          // tick when 0
logic [7:0] shift;
logic       tx;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_IDLE; tx <= 1'b1; baud_div <= '0; bit_idx <= '0;
    end else if (baud_div != 0) begin
        baud_div <= baud_div - 1;
    end else begin
        baud_div <= BAUD_TICKS;
        case (state)
            S_IDLE: if (start) begin shift <= data_in; tx <= 1'b0; state <= S_DATA; bit_idx <= 4'd0; end
            S_DATA: begin tx <= shift[0]; shift <= shift >> 1; bit_idx <= bit_idx + 1; if (bit_idx == 4'd8) begin tx <= 1'b1; state <= S_STOP; end end
            S_STOP: state <= S_IDLE;
        endcase
    end
end
```

## Verification (W10, W12)

- Loopback: TX → RX with the same baud, expect transmitted byte
  back.
- Framing-error injection: drive RX line with stop bit forced to 0
  → expect `frame_err` flag.
- Parity error: flip one bit before transmission → expect `parity_err`.
- Functional coverage on baud × parity × payload byte × inter-byte gap.

## Reading

- Chu *FPGA Prototyping by Verilog Examples* ch.7–9 — full UART
  walk-through.
- Nandland UART tutorial (free) — alternative perspective.

## Cross-links

- `[[fsm_encoding_styles]]` — registered TX FSM.
- `[[ready_valid_handshake]]` — TX/RX FIFO pairing.
