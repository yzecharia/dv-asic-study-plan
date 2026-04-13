parameter int SIZE = 100;

class Stack #(type T=int);
    local T stack[SIZE];
    local int top;

    function void push(input T i);
        stack[top++] = i;
    endfunction : push

    function T pop();
        return stack[--top];
    endfunction : pop
endclass : Stack

program automatic test;
    initial begin
        Stack #(real) rStack;
        rStack = new();
        for (int i=0; i<SIZE; i++) rStack.push(i*2.0);

        for (int i=0; i<SIZE; i++) $display("%f", rStack.pop());
    end
endprogram : test