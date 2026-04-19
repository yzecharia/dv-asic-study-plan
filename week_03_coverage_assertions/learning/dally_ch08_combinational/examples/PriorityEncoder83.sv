module PriorityEncoder83(
    input logic [7:0] r,
    output logic [2:0] b
);

    logic [7:0] one_hot_mask;

    Arb #(8) a (r, one_hot_mask);
    Enc83 e(one_hot_mask, b);

endmodule