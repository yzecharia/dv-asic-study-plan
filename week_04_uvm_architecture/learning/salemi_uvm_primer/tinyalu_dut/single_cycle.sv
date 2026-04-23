// SV port of Ray Salemi's single_cycle_add_and_xor.vhd
// Single-cycle operations: ADD (op=001), AND (op=010), XOR (op=011).
// Note: Salemi's VHDL uses synchronous reset for result_aax but
// asynchronous reset for done_aax — preserved here as-is.

module single_cycle (
    input  logic [7:0]  A,
    input  logic [7:0]  B,
    input  logic        clk,
    input  logic [2:0]  op,
    input  logic        reset_n,
    input  logic        start,
    output logic        done_aax,
    output logic [15:0] result_aax
);

    // ── Single-cycle ops (synchronous reset) ─────────────────────────
    always_ff @(posedge clk) begin
        if (!reset_n) begin
            result_aax <= 16'h0000;
        end else if (start) begin
            case (op)
                3'b001:  result_aax <= {8'b0, A} + {8'b0, B};   // ADD
                3'b010:  result_aax <= {8'b0, A} & {8'b0, B};   // AND
                3'b011:  result_aax <= {8'b0, A} ^ {8'b0, B};   // XOR
                default: ;                                        // hold
            endcase
        end
    end

    // ── Done signal (asynchronous reset) ─────────────────────────────
    always_ff @(posedge clk, negedge reset_n) begin
        if (!reset_n) begin
            done_aax <= 1'b0;
        end else if (start && op != 3'b000) begin
            done_aax <= 1'b1;
        end else begin
            done_aax <= 1'b0;
        end
    end

endmodule
