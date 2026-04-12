module counter #(
    parameter WIDTH = 4
) ( 
    input logic clk, reset_n, en, load, up_down,
    input logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] count_out,
    output logic wrap
);
    
    // reset_n: async reset active-low
    // up_down: 1 = up, 0 = down

    always_ff @(posedge clk, negedge reset_n) begin
        if (~reset_n) begin
            count_out <= '0;
            wrap <= 1'b0;
        end
        else if (load) begin
            count_out <= data_in;
            wrap <= 1'b0;
        end
        else if (en) begin
            {wrap, count_out} <= up_down ? count_out + 1'd1 : count_out - 1'd1;
        end
        else wrap <= 1'b0;
    end


endmodule