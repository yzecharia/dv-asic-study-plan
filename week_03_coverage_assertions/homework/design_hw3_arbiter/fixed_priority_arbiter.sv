// Design HW3 — Fixed-priority arbiter
// Spec: docs/week_03.md, Design HW3
//   - request 0 = highest priority, request N-1 = lowest
//   - grant is one-hot (or all zero if no requests)
//   - combinational (no latency)
//   - grant_valid = OR of grant bits

module fixed_priority_arbiter #(
    parameter int NUM_REQ = 4
)(
    input  logic                clk, rst_n,
    input  logic [NUM_REQ-1:0]  request,
    output logic [NUM_REQ-1:0]  grant,
    output logic                grant_valid
);

        // TODO: implement
    logic [NUM_REQ-1:0] c;
    always_comb begin
        c[0] = 1'b1;
        for (int i = 1; i < NUM_REQ; i++)
            c[i] = c[i-1] & ~request[i-1];
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            grant <= '0;
        end else begin
            grant <= c & request;
        end
    end

    assign grant_valid = |grant;
endmodule
