class rectangle;
    int length;
    int width;

    function new(int l, int w);
        length = l;
        width = w;
    endfunction : new

    function int area();
        return length * width;
    endfunction : area
endclass : rectangle

class square extends rectangle;
    function new(int side);
        super.new(.l(side), .w(side));
    endfunction : new
endclass : square


module top_rectangle;
    rectangle rectangle_h;
    square square_h;
    initial begin
        rectangle_h = new(.l(50), .w(20));
        $display("rectangle area: %0d", rectangle_h.area());
    
        square_h = new(50);
        $display("square area: ", square_h.area());
    end
endmodule : top_rectangle