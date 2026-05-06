// Design HW4 — Single-cycle Barrel Shifter (alternative implementation).
// Spec: docs/week_04.md (Design HW4). Companion to barrel_shifter.sv.
//
// Same interface as barrel_shifter.sv. Two structural differences:
//   * SLL/SRL/SRA operate directly on d_in — no 2W scratch vector.
//   * ROL/ROR use {d_in, d_in} + indexed part-select instead of
//     halve-and-OR.
module barrel_shifter_alt #(
    parameter int WIDTH   = 8,
    parameter int SHAMT_W = (WIDTH > 1) ? $clog2(WIDTH) : 1
) (
    input  logic [WIDTH-1:0]    d_in,
    input  logic [SHAMT_W-1:0]  shamt,
    input  logic [2:0]          sh_type,
    output logic [WIDTH-1:0]    d_out
);

    typedef enum logic [2:0] {
        SLL = 3'b000,
        SRL = 3'b001,
        SRA = 3'b010,
        ROL = 3'b011,
        ROR = 3'b100
    } shift_type_e;

    // Indexing into a 2W-bit vector needs $clog2(2W) bits, which is
    // SHAMT_W + 1 — one wider than `shamt` itself.
    localparam int IDX_W = $clog2(2 * WIDTH);

    // doubled[k] == d_in[k mod WIDTH] for any k in [0, 2W-1], so any
    // contiguous WIDTH-wide window through `doubled` is a rotation of
    // d_in. ROR by k starts the window at k; ROL by k starts at W-k.
    logic [2*WIDTH-1:0] doubled;
    logic [IDX_W-1:0]   shamt_ext;
    logic [IDX_W-1:0]   rol_start;

    assign doubled   = {d_in, d_in};
    assign shamt_ext = IDX_W'(shamt);
    assign rol_start = IDX_W'(WIDTH) - shamt_ext;

    always_comb begin
        unique case (sh_type)
            SLL:     d_out =          d_in  <<  shamt;
            SRL:     d_out =          d_in  >>  shamt;
            SRA:     d_out = $signed(d_in) >>> shamt;
            ROL:     d_out = doubled[rol_start +: WIDTH];
            ROR:     d_out = doubled[shamt_ext +: WIDTH];
            default: d_out = '0;
        endcase
    end

endmodule : barrel_shifter_alt
