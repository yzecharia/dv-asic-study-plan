`include "vending_defines.svh"
module VendingMachineControl(
    input logic clk, rst, nickel, dime, quarter, dispense, done, enough, zero,
    output logic serve, change, sub,
    output logic [3:0] selval,
    output logic [2:0] selnext
);

    typedef enum logic [2:0] {
        DEPOSIT = 3'b000,
        SERVE1 = 3'b001,
        SERVE2 = 3'b010,
        CHANGE1 = 3'b011,
        CHANGE2 = 3'b100
    } state_e;


    state_e state, next_state;

    always_ff @(posedge clk) begin
        if (rst) state <= DEPOSIT;
        else state <= next_state;
    end

    always_comb begin
        next_state = state;
        case (state)
            DEPOSIT: if (dispense && enough) next_state = SERVE1;
            SERVE1: if (done) next_state = SERVE2;
            SERVE2: begin
                if (!done)
                    next_state = state_e'(zero ? DEPOSIT : CHANGE1);
            end
            CHANGE1: if (done) next_state = CHANGE2;
            CHANGE2: begin
                if (!done)
                    next_state = state_e'(zero ? DEPOSIT : CHANGE1);
            end
            default: next_state = DEPOSIT;
        endcase
    end



    // This is the handshake block. we want first to be 1 for one cycle  when it hits one of the states SERVE1 or CHANGE1.
    // So to do this we ask are we in one of those states (continuesly). If we are then in_pulse sate goes to 1 if not then it is 0.
    // If we arent in those states so first keeps getting 1'b1, because it is the not of the question.
    // If we are in those states then first goes to 0 the next cycle, that wat we make first pulse on the correct states.
    logic in_pulse_state;
    assign in_pulse_state = ((state == SERVE1) || (state == CHANGE1));
    logic first;

    always_ff @(posedge clk) begin
        if (rst) first <= 1'b1;
        else first <= ~in_pulse_state;
    end


    assign serve = (state == SERVE1) && first; // So serve is high when we are in state SERVE1 and it is our first cycle on first1;
    assign change = (state == CHANGE1) && first; // Same thing for change signal.


    // This part decides when the adder should subtract.
    // We should subtract when we are in deposit state and we hit dispense (we need no clac amount >= price to see if the is change and we do that by subtracting the price from amount)
    // Or we sub when we are in change 1 state in this case we keep subing a nickel from amount until we hit 0 do dispense all the change.
    logic in_deposit;
    assign in_deposit = (state == DEPOSIT);
    assign sub = (in_deposit && dispense) || (state == CHANGE1);


    // This part is the one-hot encoding of the selval (this choses what should enter the adder/subtractor)
    // selval is 4 bit {PRICE, NICKEL, DIME, QUARTER};
    // so price should be one when we are in_deposit and dispense is high thats when we load price and check if amount >= price
    // NICKLE should be asserted when we are in deposit state and the user put a nickle coin or in change1 state where we keep subing amount - NICKLE
    // DIME should be asserted when in deposit and user put a dime coin in the machine
    // QUARTER shout be asserted when in deposit and user put a quarter in the machine
    assign selval = {(in_deposit && dispense),
                     (in_deposit && nickel) || (state == CHANGE1),
                     (in_deposit && dime),
                     (in_deposit && quarter)};



    // selnext block
    // selnext is one hot encoded too {HOLD, SUM, O}.
    /*
        load_sum: When do we use it?
            - in deposit, when a coin drops - Need to add it to amount so we need to pass in the updated amount (sum)
            - in deposit when we transition from deposit to serve1, when dispense and enough are asserted, in this case we need to pass through the sub of amount - price witch is the sum option
            - in change 1 when we need to subtract a nickle from amount (But it is gated to the first cycle on change 1)
    */
    logic load_sum;
    assign load_sum = (in_deposit && (nickel || dime || quarter || (dispense && enough))) || ((state == CHANGE1) && first);
    assign selnext = {~(load_sum || rst), load_sum && ~rst, rst};
endmodule : VendingMachineControl
