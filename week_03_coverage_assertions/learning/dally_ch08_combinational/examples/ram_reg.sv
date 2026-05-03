module ram_reg #(
    parameter B=32, W=4
)(
    input logic write,
    input logic [W-1:0] ra, wa,
    input logic [B-1:0] din,
    output logic [B-1:0] dout
);
    logic [B-1:0] ram [2**W-1:0];
    assign dout = ram[ra];

    always @(*) begin
        if(write == 1) ram[wa] = din;
    end

endmodule

