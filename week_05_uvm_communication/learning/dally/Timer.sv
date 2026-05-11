module Timer #(
    parameter N = 4
) (
    input logic clk, rst, load, 
    input logic [N-1:0] in,
    output logic done
);

    logic [N-1:0] count, next_count;

    assign done = (count == '0);

    always_ff @(posedge clk) count <= next_count;

    always_comb begin
        if (rst || (done && !load)) next_count = '0;
        else if (load) next_count = in;
        else next_count = count - 1'b1;
    end

endmodule : Timer