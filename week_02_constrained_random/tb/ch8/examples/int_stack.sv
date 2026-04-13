parameter int SIZE = 100;
class IntStack;

    local int stack[SIZE];
    local int top;

    function void push(input int i);
        stack[top++] = i;
    endfunction : push

    function int pop();
        return stack[--top];
    endfunction : pop

endclass : IntStack