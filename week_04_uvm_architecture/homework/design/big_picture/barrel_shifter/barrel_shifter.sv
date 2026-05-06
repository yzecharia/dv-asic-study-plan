// Design HW4 — Single-cycle Barrel Shifter. Spec: docs/week_04.md (Design HW4).
module barrel_shifter #(
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

    logic [2*WIDTH-1:0] shift_vec;

    always_comb begin
        if (sh_type == ROR) shift_vec = {d_in, {WIDTH{1'b0}}};
        else shift_vec = {{WIDTH{1'b0}}, d_in};
        case(sh_type)
            SLL: shift_vec = (shift_vec << shamt);
            SRL: shift_vec = (shift_vec >> shamt);
            SRA: shift_vec[WIDTH-1:0] = ($signed(shift_vec[WIDTH-1:0]) >>> shamt);
            ROL: begin
                shift_vec = (shift_vec << shamt);
                shift_vec[WIDTH-1:0] = shift_vec[2*WIDTH-1:WIDTH] | shift_vec[WIDTH-1:0];
            end
            ROR: begin
                shift_vec = (shift_vec >> shamt);
                shift_vec[WIDTH-1:0] = shift_vec[2*WIDTH-1:WIDTH] | shift_vec[WIDTH-1:0];
            end
            default: shift_vec = '0;
        endcase
        d_out = shift_vec[WIDTH-1:0];
    end

endmodule : barrel_shifter
