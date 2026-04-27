// SystemVerilog port of three_cycle_mult.vhd
// Functional twin of the original VHDL — pipelined multiplier
module three_cycle (
    input  logic [7:0]   A,
    input  logic [7:0]   B,
    input  logic         clk,
    input  logic         reset_n,
    input  logic         start,
    output logic         done_mult,
    output logic [15:0]  result_mult
);

    logic [7:0]  a_int, b_int;
    logic [15:0] mult1, mult2;
    logic        done3, done2, done1, done_mult_int;

    // Asynchronous active-low reset (matches VHDL: process sensitive to clk + reset_n)
    always_ff @(posedge clk or negedge reset_n) begin : multiplier
        if (!reset_n) begin
            done_mult_int <= 1'b0;
            done3         <= 1'b0;
            done2         <= 1'b0;
            done1         <= 1'b0;
            a_int         <= 8'h00;
            b_int         <= 8'h00;
            mult1         <= 16'h0000;
            mult2         <= 16'h0000;
            result_mult   <= 16'h0000;
        end else begin
            a_int         <= A;
            b_int         <= B;
            mult1         <= a_int * b_int;
            mult2         <= mult1;
            result_mult   <= mult2;
            done3         <= start && !done_mult_int;
            done2         <= done3 && !done_mult_int;
            done1         <= done2 && !done_mult_int;
            done_mult_int <= done1 && !done_mult_int;
        end
    end

    assign done_mult = done_mult_int;

endmodule : three_cycle
