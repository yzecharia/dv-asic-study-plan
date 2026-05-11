module UDL_Count3 #(
    parameter N = 4
) (
    input logic clk, rst, up, down, load, 
    input logic [N-1:0] in,
    output logic [N-1:0] out
);

    logic [N-1:0] next, outpm1;

    assign outpm1 = out + {{N-1{down}}, 1'b1};

    always_ff @(posedge clk) out <= next;

    always_comb begin
        if (rst) next = '0;
        else if (load) next = in;
        else if (up || down) next = outpm1;
        else next = out;
    end

endmodule : UDL_Count3