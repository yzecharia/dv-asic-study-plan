// SystemVerilog port of single_cycle_add_and_xor.vhd
// Functional twin of the original VHDL — single-cycle ADD/AND/XOR unit
module single_cycle (
    input  logic [7:0]   A,
    input  logic [7:0]   B,
    input  logic         clk,
    input  logic [2:0]   op,
    input  logic         reset_n,
    input  logic         start,
    output logic         done_aax,
    output logic [15:0]  result_aax
);

    // Synchronous reset for the result register (matches VHDL: process sensitive to clk only)
    always_ff @(posedge clk) begin : single_cycle_ops
        if (!reset_n) begin
            result_aax <= 16'h0000;
        end else if (start) begin
            unique case (op)
                3'b001 : result_aax <= {8'h00, A} + {8'h00, B};
                3'b010 : result_aax <= {8'h00, A} & {8'h00, B};
                3'b011 : result_aax <= {8'h00, A} ^ {8'h00, B};
                default: ; // no-op
            endcase
        end
    end

    // Asynchronous active-low reset for done (matches VHDL: process sensitive to clk + reset_n)
    always_ff @(posedge clk or negedge reset_n) begin : set_done
        if (!reset_n)
            done_aax <= 1'b0;
        else
            done_aax <= (start && (op != 3'b000));
    end

endmodule : single_cycle
