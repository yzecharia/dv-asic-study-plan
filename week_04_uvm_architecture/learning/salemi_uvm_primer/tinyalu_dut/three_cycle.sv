// SV port of Ray Salemi's three_cycle_mult.vhd
// 3-stage pipelined multiplier with async reset.
// After start is asserted, done_mult pulses high for 1 cycle three cycles later.
// The "AND NOT done_mult" chain acts as a self-clearing mechanism on the done pulse.
//
// VHDL used an internal done_mult_int because VHDL can't read output ports —
// SystemVerilog CAN, so we use done_mult directly.

module three_cycle (
    input  logic [7:0]  A,
    input  logic [7:0]  B,
    input  logic        clk,
    input  logic        reset_n,
    input  logic        start,
    output logic        done_mult,
    output logic [15:0] result_mult
);

    logic [7:0]  a_int, b_int;
    logic [15:0] mult1, mult2;
    logic        done3, done2, done1;

    always_ff @(posedge clk, negedge reset_n) begin
        if (!reset_n) begin
            a_int       <= 8'h00;
            b_int       <= 8'h00;
            mult1       <= 16'h0000;
            mult2       <= 16'h0000;
            result_mult <= 16'h0000;
            done3       <= 1'b0;
            done2       <= 1'b0;
            done1       <= 1'b0;
            done_mult   <= 1'b0;
        end else begin
            // Datapath pipeline: A/B -> mult1 -> mult2 -> result_mult
            a_int       <= A;
            b_int       <= B;
            mult1       <= a_int * b_int;
            mult2       <= mult1;
            result_mult <= mult2;

            // Done pipeline with self-clearing after one pulse
            done3       <= start & ~done_mult;
            done2       <= done3 & ~done_mult;
            done1       <= done2 & ~done_mult;
            done_mult   <= done1 & ~done_mult;
        end
    end

endmodule
