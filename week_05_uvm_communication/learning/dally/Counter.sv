module Counter #(
    parameter N=5
) (
    input logic clk, rst,
    output logic [N-1:0] count
);

    logic [N-1:0] next;
    assign next = rst ? 0 : count + 1;

    always_ff @(posedge clk) begin
        count <= next;
    end

endmodule : Counter