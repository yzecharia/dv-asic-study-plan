module handshake_sender(
    input clk, rst_n,
    input send, ready,
    input [7:0] data_in,
    output logic [7:0] data_out,
    output logic valid
);

/*
    Rules:
    1. Assert valid when data is availiable
    2. Hold valid high until ready is seen
    3. Data must be stable while valid and !ready
    4. After hanshake (valid && ready), deassert valid for 1 cycle

    - Sender asserts valid
    - Reciver asserts ready
    - transfer happens when (valid and ready) 

    send: tells me if there is new data to send (if data_in is ready)
*/

    localparam  IDLE = 2'b00,
                WAITING = 2'b01,
                COOLDOWN = 2'b10;

    logic [1:0] state, next;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            data_out <= '0;
        end else begin
            state <= next;
            if ((state == IDLE) && send)
                data_out <= data_in;        
        end
    end


    always_comb begin
        valid = 1'b0;
        next = state;
        case(state)
            IDLE: begin
                if (send) next = WAITING;
                else next = IDLE;
            end
            WAITING: begin
                valid = 1'b1;
                if (ready) next = COOLDOWN;
                else next = WAITING;
            end
            COOLDOWN: begin
                next = IDLE;
            end
            default: begin
                next = IDLE;
            end
        endcase
    end

endmodule