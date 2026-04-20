// Design HW4 — Parameterized shift register
// Spec: docs/week_03.md, Design HW4
//   - parallel load overrides shift
//   - serial_out is MSB for LEFT, LSB for RIGHT
//   - serial_in feeds the vacated bit

module shift_register #(
    parameter WIDTH     = 8,
    parameter DIRECTION = "LEFT"   // "LEFT" or "RIGHT"
)(
    input  logic             clk, rst_n,
    input  logic             shift_en,
    input  logic             load,
    input  logic [WIDTH-1:0] data_in,
    input  logic             serial_in,
    output logic [WIDTH-1:0] data_out,
    output logic             serial_out
);

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) data_out <= '0;
        else if (load) data_out <= data_in;
        else if (shift_en) begin
            if (DIRECTION == "LEFT") data_out <= {data_out[WIDTH-2:0], serial_in};
            else data_out <= {serial_in, data_out[WIDTH-1:1]};
        end
    end

    assign serial_out = (DIRECTION == "LEFT") ? data_out[WIDTH-1] : data_out[0];

endmodule
