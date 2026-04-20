module round_robin_arbiter (
    input logic [7:0] a,
    input logic [7:0] p,
    output logic [7:0] b
);

    logic [7:0] c;
    logic [7:0] next_p;

    assign next_p = {p[0], p[7:1]};

    always_comb begin

        c[7] = next_p[7] | (c[0] & ~a[0]);
        for (int i = 6; i >= 0; i--) begin
            c[i] = next_p[i] | (c[i+1] & ~a[i+1]);
        end
    end

    assign b = c & a;

endmodule