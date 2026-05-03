module prog_priority_encoder (
    input [7:0] p,
    input [7:0] a,
    output logic [2:0] b
);

    //p - One hot bit array tells me what bit in a has proirity.

    logic [7:0] c;
    logic [7:0] b_onehot;
    always_comb begin
        c[7] = p[7] | (c[0] & ~a[0]);
        for (int i = 6; i>=0; i--) begin
            c[i] = p[i] | (c[i+1] & ~a[i+1]);
        end
        b_onehot = c & a;
    end
    
    assign b[2] = b_onehot[7] | b_onehot[6] | b_onehot[5] | b_onehot[4];
    assign b[1] = b_onehot[7] | b_onehot[6] | b_onehot[3] | b_onehot[2];
    assign b[0] = b_onehot[7] | b_onehot[5] | b_onehot[3] | b_onehot[1];
endmodule