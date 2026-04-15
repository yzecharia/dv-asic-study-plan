module fsm_cc1_2 (
    input  logic go, ws, clk, rst_n,
    output logic rd, ds
);

    parameter   IDLE = 2'b00,
                READ = 2'b01,
                DLY = 2'b10,
                DONE = 2'b11;

    logic [1:0] state, next;

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            state <= IDLE;
        end else begin
            state <= next;
        end
    end

    always_comb begin
        next = 'bx;
        rd = 1'b0;
        ds = 1'b0;
        case (state)
            IDLE: next = go ? READ : IDLE;
            READ: begin
                rd = 1'b1;
                next = DLY;
            end
            DLY: begin
                rd = 1'b1;
                next = !ws ? DONE : READ;
            end
            DONE: begin
                ds = 1'b1;
                next = IDLE;
            end
        endcase
    end

endmodule : fsm_cc1_2
