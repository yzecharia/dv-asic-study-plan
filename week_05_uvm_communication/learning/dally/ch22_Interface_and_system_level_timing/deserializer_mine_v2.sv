module deserializer_mine_v2 #(parameter WIDTH_IN = 1, parameter N = 8) (
    input logic clk, rst, vin,
    input logic [WIDTH_IN-1:0] din,
    output logic vout,
    output logic [N*WIDTH_IN-1:0] dout
);

    logic [N-1:0] grant;
    one_hot_encoder #(.N(N)) u_grant (.clk(clk), .rst(rst), .grant(grant), .vin(vin));

    logic [N-1:0] slot_en;
    assign slot_en = grant & {N{vin}};
    dff_en #(.WIDTH_IN(WIDTH_IN)) data[N-1:0] (.clk(clk), .en(slot_en), .din(din), .dout(dout));

    logic vout_next;
    assign vout_next = ~rst & grant[N-1] & vin;
    always_ff @(posedge clk) begin
        vout <= vout_next;
    end


endmodule : deserializer_mine_v2

module one_hot_encoder #(parameter N = 8) (
    input logic clk, rst, vin,
    output logic [N-1:0] grant
);  
    always_ff @(posedge clk) begin
        if (rst) grant <= {{N-1{1'b0}}, 1'b1};
        else if (vin) begin
            grant <= {grant[N-2:0], grant[N-1]};
        end
    end
endmodule : one_hot_encoder

module dff_en #(parameter WIDTH_IN = 1) (
    input logic clk, en,
    input logic [WIDTH_IN-1:0] din,
    output logic [WIDTH_IN-1:0] dout
);

    always_ff @(posedge clk) begin
        if (en) dout <= din;
    end

endmodule : dff_en