typedef enum {RED, GREEN, BLUE, YELLOW} color_t;

class Compare #(type T = bit [3:0]);
    function bit compare (input T a, input T b);
        return (a === b) ? 1 : 0;
    endfunction : compare
endclass : Compare

program automatic test;
    Compare #(bit [7:0]) compare_8 = new();
    Compare #() compare_default = new();
    Compare #(color_t) color_compare = new();
    int errors;

    initial begin
        color_t expexted_color, actual_color;
        $display("%0d", compare_8.compare(8'hAB, 8'hCD));
        $display("%0d", compare_default.compare(4'hA, 4'hA));

        repeat (10) begin
            actual_color = color_t'($urandom_range(0,3));
            expexted_color = color_t'($urandom_range(0,3));
            if (!color_compare.compare(expexted_color, actual_color)) errors++;

            $display("expexted_color=%s, actual_color=%s, compare=%0d", expexted_color.name(), actual_color.name(), color_compare.compare(expexted_color,actual_color));
            $display("Total errors: %0d", errors);
        end
    end
endprogram : test