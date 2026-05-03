module MagComp #(
    parameter K = 8
)(
    input logic [K-1:0] a, b,
    output logic gt
);
    always_comb begin
        gt = 1'b0;
        for (int i = 1; i < K; i++) begin
            gt = (a[i-1] & ~b[i-1]) | ~(a[i-1] ^ b[i-1]) & gt;
        end
    end

endmodule