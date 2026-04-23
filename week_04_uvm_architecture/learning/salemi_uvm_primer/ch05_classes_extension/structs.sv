typedef struct {
    int length;
    int width;
} rectangle_struct;

typedef struct {
    int side;
} square_struct;

module top_struct;
    rectangle_struct rectangle_s;
    square_struct square_s;
    initial begin
        rectangle_s.length = 50;
        rectangle_s.width = 20;
        $display("rectangle area: %0d", rectangle_s.length * rectangle_s.width);
        square_s.side = 50;
        $display("square area: %0d", square_s.side ** 2);
    end
endmodule