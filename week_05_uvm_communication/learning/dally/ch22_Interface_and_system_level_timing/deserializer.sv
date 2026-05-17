// deserializer.sv
// Dally & Harting, "Digital Design: A Systems Approach",
// ch.22 "Interface and System-Level Timing" — Example 22.2 (Figure 22.7).
//
// Gathers N input elements of WIDTH_IN bits each into one
// WIDTH_IN*N-bit output word. Both sides use PUSH flow control:
//   - input  : an element is captured only on cycles where `vin` is high.
//   - output : `vout` pulses for the one cycle `dout` holds a full word.
// Reset is synchronous and active-high (no reset pin on the flops —
// the reset is muxed into their data inputs, Dally's house style).
//
// Primitives: DFF.sv (D flip-flop), DFFE.sv (D flip-flop with enable).

module deserializer #(
    parameter int WIDTH_IN = 1,   // bits per input element
    parameter int N        = 8    // elements gathered per output word
) (
    input  logic                  clk,
    input  logic                  rst,    // synchronous, active-high
    input  logic [WIDTH_IN-1:0]   din,
    input  logic                  vin,    // input valid (push)
    output logic [WIDTH_IN*N-1:0] dout,
    output logic                  vout    // output valid (push)
);

    // en_out: a one-hot pointer marking which slot is written next.
    logic [N-1:0] en_nxt, en_nxt_rst, en_out;

    // While `vin` is high, rotate the one-hot left by one each cycle;
    // hold it otherwise. {en_out[N-2:0], en_out[N-1]} is a 1-bit rotate.
    assign en_nxt     = vin ? {en_out[N-2:0], en_out[N-1]} : en_out;

    // Synchronous reset forces the pointer back to slot 0.
    assign en_nxt_rst = rst ? {{N-1{1'b0}}, 1'b1} : en_nxt;

    // The one-hot pointer register (Dally uses an N-wide array of 1-bit
    // DFFs; a single parameterized N-bit DFF is equivalent).
    DFF #(.N(N)) cnts (
        .clk (clk),
        .d   (en_nxt_rst),
        .q   (en_out)
    );

    // The data store: an array of N enabled flip-flops. `din` is
    // broadcast to every flop; the one-hot `en_out` enables exactly one,
    // so each input element lands in its own slot. On reset every flop
    // is enabled and fed 0, clearing `dout`.
    DFFE #(.N(WIDTH_IN)) data [N-1:0] (
        .clk (clk),
        .en  (rst ? {N{1'b1}} : en_out),
        .d   (rst ? {WIDTH_IN{1'b0}} : din),
        .q   (dout)
    );

    // `vout` asserts the cycle after the last (N-th) element is captured.
    logic vout_nxt;
    assign vout_nxt = ~rst & en_out[N-1] & vin;

    DFF #(.N(1)) vout_r (
        .clk (clk),
        .d   (vout_nxt),
        .q   (vout)
    );

endmodule : deserializer
