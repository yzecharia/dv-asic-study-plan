module deserializer_mine #(parameter WIDTH_IN = 1, parameter N = 8) (
    input logic clk, rst, vin,
    input logic [WIDTH_IN-1:0] din,
    output logic vout,
    output logic [N*WIDTH_IN-1:0] dout
);

    logic [$clog2(N)-1:0] count;

    always_ff @(posedge clk) begin
        if (rst) begin
            vout <= 1'b0;
            dout <= '0;
            count <= '0;
        end else begin
            if (vin) begin
                dout[count*WIDTH_IN +: WIDTH_IN] <= din;
                count <= (count == N-1) ? '0 : count + 1;
                vout <= (count == N-1);
            end
            else vout <= 1'b0;
        end
    end 
endmodule : deserializer_mine