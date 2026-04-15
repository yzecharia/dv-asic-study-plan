module fsm_cc1_1 (
    input go, ws, clk, rst_n,
    output reg rd, ds
);

    parameter   IDLE = 2'b00,
                READ = 2'b01,
                DLY = 2'b10,
                DONE = 2'b11;
    
    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            rd <= 1'b0;
            ds <= 1'b0;
        end else begin
            state <= 'bx;
            rd <= 1'b0;
            ds <= 1'b0;
            case(state)
                IDLE: begin
                    if (go) begin
                        rd <= 1'b1;
                        state <= READ;
                    end else state <= IDLE;
                end
                READ: begin
                    rd <= 1'b1;
                    state <= DLY;
                end
                DLY: begin
                    if (!ws) begin 
                        ds <= 1'b1;
                        state <= DONE;
                    end
                    else begin
                        rd <= 1'b1;
                        state <= READ;
                    end
                end
                DONE: state <= IDLE;
            endcase
        end
    end

    

endmodule : fsm_cc1_1