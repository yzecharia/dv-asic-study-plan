module shift_register #(
    parameter N=8
) (
    input logic clk, rst, load, shift,
    input logic [N-1:0] din_parallel,
    input logic din_serial,
    output logic [N-1:0] dout_parallel,
    output logic dout_serial
);

    logic [N-1:0] shift_mem;
    assign {dout_serial, dout_parallel} = {shift_mem[N-1], shift_mem};
    always_ff @(posedge clk) begin
        if (rst) shift_mem <= '0;
        else if (load) shift_mem <= din_parallel;
        else if (shift) shift_mem <= {shift_mem[N-2:0], din_serial};
    end

endmodule : shift_register
