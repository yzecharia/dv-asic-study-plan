// Design HW4 — Single-cycle barrel shifter
// Spec: docs/week_04.md, Design HW4
//   - Cascaded MUX layers: log2(WIDTH) stages, each shifts by 1, 2, 4, 8, 16...
//   - Three types: SLL (00), SRL (01), SRA (10) — SRA fills with sign bit
//   - Used inside ALUs; same structure appears in RISC-V ALU (week 7)

module barrel_shifter #(
    parameter WIDTH = 32
)(
    input  logic [WIDTH-1:0]         data_in,
    input  logic [$clog2(WIDTH)-1:0] shift_amount,
    input  logic [1:0]               shift_type,   // 00=SLL 01=SRL 10=SRA
    output logic [WIDTH-1:0]         data_out
);

    // TODO: implement cascaded mux stages
    //       Example for WIDTH=32:
    //         stage0: shift by 1  if shift_amount[0]
    //         stage1: shift by 2  if shift_amount[1]
    //         stage2: shift by 4  if shift_amount[2]
    //         stage3: shift by 8  if shift_amount[3]
    //         stage4: shift by 16 if shift_amount[4]

endmodule
