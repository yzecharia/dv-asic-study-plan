// Verif HW4 — 4-bit up/down counter (DUT for combined coverage + SVA exercise)
// Spec: docs/week_03.md, HW4

module up_down_counter (
    input  logic       clk, rst_n,
    input  logic       up, down, load,
    input  logic [3:0] data_in,
    output logic [3:0] count_out
);

    // TODO: implement
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) count_out <= '0;
        else if (load) count_out <= data_in;
        else if (up) count_out <= count_out + 1;
        else if (down) count_out <= count_out - 1;
    end


endmodule
