// Design HW3 — Fixed-priority arbiter
// Spec: docs/week_03.md, Design HW3
//   - request 0 = highest priority, request N-1 = lowest
//   - grant is one-hot (or all zero if no requests)
//   - combinational (no latency)
//   - grant_valid = OR of grant bits

module fixed_priority_arbiter #(
    parameter NUM_REQ = 4
)(
    input  logic                clk, rst_n,
    input  logic [NUM_REQ-1:0]  request,
    output logic [NUM_REQ-1:0]  grant,
    output logic                grant_valid
);

    // TODO: implement

endmodule
