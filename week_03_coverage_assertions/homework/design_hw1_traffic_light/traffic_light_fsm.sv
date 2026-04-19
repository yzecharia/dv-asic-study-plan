module traffic_light_fsm(
    input logic clk, rst_n,
    input logic sensor,            // Car detected on side road
    output logic [2:0] main_light, // {R, G, Y}
    output logic [2:0] side_light  // {R. G, Y}
);
    typedef enum logic [1:0] {
        MAIN_GREEN,
        MAIN_YELLOW,
        SIDE_YELLOW,
        SIDE_GREEN
    } state_t;

    state_t state, next;

    localparam  RED = 3'b001,
                GREEN = 3'b010,
                YELLOW = 3'b100;

    localparam  MAIN_GREEN_COUNT = 50,
                SIDE_GREEN_COUNT = 30,
                YELLOW_COUNT = 10;

    logic [5:0] count, count_next;


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= MAIN_GREEN;
            count <= MAIN_GREEN_COUNT;
        end else begin
            state <= next;
            count <= count_next;
        end
    end

    always_comb begin
        main_light = '0;
        side_light = '0;
        next = state;
        count_next = count;
        case(state)
            MAIN_GREEN: begin
                main_light = GREEN;
                side_light = RED;
                if (count > 1) count_next = count - 1;
                else begin
                    if (sensor) begin
                        next = MAIN_YELLOW;
                        count_next = YELLOW_COUNT;
                    end
                end
            end
            MAIN_YELLOW: begin
                main_light = YELLOW;
                side_light = RED;
                if (count > 1) count_next = count - 1;
                else begin
                    next = SIDE_GREEN;
                    count_next = SIDE_GREEN_COUNT;
                end
            end
            SIDE_GREEN: begin
                main_light = RED;
                side_light = GREEN;
                if (count > 1) count_next = count - 1;
                else begin
                    next = SIDE_YELLOW;
                    count_next = YELLOW_COUNT;
                end
            end
            SIDE_YELLOW: begin
                main_light = RED;
                side_light = YELLOW;
                if (count > 1) count_next = count - 1;
                else begin
                    next = MAIN_GREEN;
                    count_next = MAIN_GREEN_COUNT;
                end
            end
            default: begin
                main_light = RED;
                side_light = RED;
                next = MAIN_GREEN;
                count_next = MAIN_GREEN_COUNT;
            end
        endcase
    end


    
endmodule