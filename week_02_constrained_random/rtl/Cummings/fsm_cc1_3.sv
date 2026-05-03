module fsm_cc1_3(
    input logic go, ws, clk, rst_n,
    output logic rd, ds
);
    parameter   IDLE = 2'b00,
                READ = 2'b01,
                DLY = 2'b10,
                DONE = 2'b11;

    logic [1:0] state, next;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next;
    end

    always_comb begin
        next = 'bx;
        case(state)
            IDLE : next = go ? READ : IDLE;
            READ : next = DLY;
            DLY : next = !ws ? DONE : READ;
            DONE : next = IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd <= 1'b0;
            ds <= 1'b0;
        end else begin
            rd <= 1'b0;
            ds <= 1'b0;
            case(next)
                READ: rd <= 1'b1;
                DLY : rd <= 1'b1;
                DONE: ds <= 1'b1;
            endcase
        end
    end

endmodule