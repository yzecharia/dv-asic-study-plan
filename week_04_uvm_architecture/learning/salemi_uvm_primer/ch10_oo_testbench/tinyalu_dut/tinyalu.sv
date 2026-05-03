// SystemVerilog port of tinyalu.vhd
// Top-level wrapper that demuxes start and muxes done/result based on op[2]
module tinyalu (
    input  logic [7:0]   A,
    input  logic [7:0]   B,
    input  logic         clk,
    input  logic [2:0]   op,
    input  logic         reset_n,
    input  logic         start,
    output logic         done,
    output logic [15:0]  result
);

    logic         done_aax, done_mult;
    logic [15:0]  result_aax, result_mult;
    logic         start_single, start_mult;

    // Demux start to single-cycle or multiplier based on op[2]
    always_comb begin : start_demux
        unique case (op[2])
            1'b0 : begin start_single = start; start_mult = 1'b0; end
            1'b1 : begin start_single = 1'b0;  start_mult = start; end
            default: begin start_single = 1'b0; start_mult = 1'b0; end
        endcase
    end

    // Mux result based on op[2]
    always_comb begin : result_mux
        unique case (op[2])
            1'b0 : result = result_aax;
            1'b1 : result = result_mult;
            default: result = 'x;
        endcase
    end

    // Mux done based on op[2]
    always_comb begin : done_mux
        unique case (op[2])
            1'b0 : done = done_aax;
            1'b1 : done = done_mult;
            default: done = 1'bx;
        endcase
    end

    single_cycle add_and_xor (
        .A          (A),
        .B          (B),
        .clk        (clk),
        .op         (op),
        .reset_n    (reset_n),
        .start      (start_single),
        .done_aax   (done_aax),
        .result_aax (result_aax)
    );

    three_cycle mult (
        .A           (A),
        .B           (B),
        .clk         (clk),
        .reset_n     (reset_n),
        .start       (start_mult),
        .done_mult   (done_mult),
        .result_mult (result_mult)
    );

endmodule : tinyalu
