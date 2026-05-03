module prog_priority_arbiter_noncyclic #(
    parameter N=8
) (
    input logic [N-1:0] r,
    input logic [N-1:0] p,
    output logic [N-1:0] g
);

    logic [2*N-1:0] r_dbl, p_pad, c;

    always_comb begin
        r_dbl = {r, r};
        p_pad = {{N{1'b0}}, p};
        c[0] = p_pad[0];

        for (int i=1; i<2*N; i++) begin
            c[i] = p_pad[i] | (c[i-1] & ~r_dbl[i-1]);
        end

        g = r & (c[2*N-1:N] | c[N-1:0]);
    end

endmodule