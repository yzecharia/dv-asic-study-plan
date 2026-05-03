module MagComp_msb #(
    parameter K=8
)(
    input logic [K-1:0] a, b,
    output logic gt
);

    logic [K-1:0] eqi, gti;
    logic [K:0] gtb;

    assign eqi = ~(a ^ b); // a[i] == b[i]
    assign gti = a & ~b; // a[i] > b[i]

    always_comb begin
        gtb[0] = 1'b0;
        for (int i = 0; i < K; i++) begin
            gtb[i+1] = gti[i] | (eqi[i] & gtb[i]);
        end
    end

    assign gt = gtb[K];
endmodule