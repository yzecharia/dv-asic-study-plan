// Design HW3 — Sequential Shift-Add Multiplier. Spec: docs/week_04.md (Design HW3).
module shift_add_multiplier #(
    parameter int WIDTH = 8
) (
    input logic clk, rst_n,
    input logic [WIDTH-1:0] a, b,
    input logic valid_in,
    output logic [2*WIDTH-1:0] d_out,
    output logic valid_out
);

    typedef enum logic [1:0] { 
        IDLE = 2'b00,
        COMPUTE = 2'b01,
        DONE = 2'b10
    } state_e;

    state_e state, next_state;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else state <= next_state;
    end

    logic [WIDTH-1:0] iA, iB;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin iA <= '0; iB <= '0; end
        else begin
            if (valid_in && state == IDLE) begin
                iA <= a;
                iB <= b;
            end
        end
    end

    logic [2*WIDTH-1:0] acc, acc_next;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) acc <= '0;
        else if (state == IDLE) acc <= '0;
        else acc <= acc_next; 
    end

    logic [$clog2(WIDTH)-1:0] counter, counter_next;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= '0;
        end else begin
            counter <= counter_next;
        end
    end
    
    localparam logic [$clog2(WIDTH)-1:0] LAST_IDX = ($clog2(WIDTH))'(WIDTH - 1);
    always_comb begin
        next_state = state;
        acc_next = acc;
        valid_out = 1'b0;
        counter_next = counter;
        case (state)
            IDLE: begin next_state = valid_in ? COMPUTE : IDLE; counter_next = '0; end
            COMPUTE: begin
                if (iB[counter] == 1'b1)
                    acc_next = acc + ((2*WIDTH)'(iA) << counter);
                if (counter == LAST_IDX)
                    next_state = DONE;
                else
                    counter_next = counter + 1;
            end
            DONE: begin valid_out = 1'b1; next_state = IDLE; counter_next = '0; end
            default : next_state = IDLE;
        endcase
    end

    assign d_out = (state == DONE) ? acc : '0;
endmodule : shift_add_multiplier
