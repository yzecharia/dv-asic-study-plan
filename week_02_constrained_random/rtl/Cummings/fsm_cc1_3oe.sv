module fsm_cc1_3oe(
    input go, ws, clk, rst_n,
    output reg rd, ds
);
    parameter   IDLE = 3'b000,
                READ = 3'b001,
                DLY = 3'b101,
                DONE = 3'b010;

    reg [2:0] state, next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else state <= next;
    end

    always @(*) begin
        next = 'bx;
        case(state)
            IDLE: next = go ? READ : IDLE;
            READ: next = DLY;
            DLY : next = !ws ? DONE : READ;
            DONE: next = IDLE;
        endcase
    end

    assign {ds, rd} = state[1:0];
endmodule