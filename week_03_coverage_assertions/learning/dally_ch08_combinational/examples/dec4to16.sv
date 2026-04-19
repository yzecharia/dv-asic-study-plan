module dec4to16 (
    input logic [3:0] a,
    output logic [15:0] b
    
);

    logic [3:0] x, y;

    decoder d0 (a[1:0], x);
    decoder d1 (a[3:2], y);

    assign b[3:0] = x & {4{y[0]}};
    assign b[7:4] = x & {4{y[1]}};
    assign b[11:8] = x & {4{y[2]}};
    assign b[15:12] = x & {4{y[3]}};


endmodule