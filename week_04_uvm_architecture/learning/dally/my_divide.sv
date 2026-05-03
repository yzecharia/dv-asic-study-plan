/*
R′ = 0
for i = N−1 to 0
R = {R′ << 1, Ai}
D=R− B
if D < 0 then Qi = 0, R′ = R 
else Qi = 1, R′ = D
R = R′

N = dividend width = 6
M = Divisor width = 3

q width = 6, exactly like the n incase devide by 1;
r width = 3 exactly like m (max reminder is 6 = 110)

partial_reminder width = m+1
*/

module my_divide (
    input logic [5:0] y,
    input logic [2:0] x,
    output logic [5:0] q,
    output logic [2:0] r
);
    localparam n = 6;
    localparam m = 3;
    logic [m:0] partial_reminder;
    logic [m:0] r_internal;
    logic [4:0] d;
    integer i;
    always_comb begin
        partial_reminder = '0;
        q = '0;

        for (i = n-1; i >= 0; i--) begin
            r_internal = {partial_reminder[m-1:0], y[i]};
            // d = r - x: d is 5 bits, x is 3 bits
            d = {1'b0, r_internal} - {2'b0, x};
            {q[i], partial_reminder} = d[4] ? {1'b0, r_internal} : {1'b1, d[3:0]};
        end
        r = partial_reminder[m-1:0];
    end


    

endmodule : my_divide
