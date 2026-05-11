// AddSub.sv — n-bit adder/subtractor primitive.
// sub=0 → sum = a + b;  sub=1 → sum = a - b.
// ovf is the carry/borrow out of the MSB (overflow indicator, ignored
// in the vending-machine example but exposed for completeness).

module AddSub #(
    parameter N = 6
) (
    input  logic [N-1:0] a, b,
    input  logic         sub,
    output logic [N-1:0] sum,
    output logic         ovf
);
    logic [N:0] ext;     // N+1 bit result to capture the carry/borrow

    assign ext = sub ? ({1'b0, a} - {1'b0, b})
                     : ({1'b0, a} + {1'b0, b});
    assign sum = ext[N-1:0];
    assign ovf = ext[N];
endmodule : AddSub
