class Ex1;
    typedef enum {READ, WRITE} op_e;
    rand op_e mode;
    rand bit [7:0] value;
    constraint c_range {
        value inside {[10:50]};
    }

    static function void print_histogram(input int count[int]);
        int max[$];
        max = count.max();
        foreach (count[i]) begin
            $write("value: %2d = %4d ", i, count[i]);
            repeat (count[i] * 40 / max[0]) begin
                $write("#");
            end
            $display;
        end
    endfunction : print_histogram
endclass : Ex1

class Ex7;
    rand bit [7:0] arr[];

    constraint c_arr {
        arr.size() inside {[1:10]};
        unique {arr};
    }
endclass : Ex7

class Ex8;
    randc bit [2:0] value;
endclass : Ex8

class Ex9;
    rand bit [7:0] x, y;

    constraint c_sum {
        x + y == 100;
        x > 0;
        y > 0;
    }
endclass : Ex9

class Ex10;
    rand bit [1:0] x;
    rand bit [3:0] y;

    constraint c_xy {
        y inside {[0:x]};
    }
endclass : Ex10

class Ex10_solve extends Ex10;
    constraint c_solve {
        solve x before y;
    }
endclass : Ex10_solve

program automatic test;
    initial begin
        int count[int];
        Ex1 ex = new();

        // Ex1
        repeat (1000) begin
            assert(ex.randomize());
            count[ex.value]++;
        end
        Ex1::print_histogram(count);

        ex.c_range.constraint_mode(0);

        // Ex2
        $display;
        count.delete();
        repeat (1000) begin
            assert(ex.randomize() with {
                value inside {1, 2, 4, 8, 16, 32};
            });
            count[ex.value]++;
        end
        Ex1::print_histogram(count);

        // Ex3
        $display;
        count.delete();
        repeat (1000) begin
            assert(ex.randomize() with {
                (value % 2) == 0;
                //value[0] = 0;
                value inside {[0:100]};
            });
            count[ex.value]++;
        end
        Ex1::print_histogram(count);

        // Ex4
        $display;
        count.delete();
        repeat (1000) begin
            assert(ex.randomize() with {
                value dist {[0:9] :/ 80, [10:255] :/ 20};
            });
            count[ex.value]++;
        end
        Ex1::print_histogram(count);

        // Ex5
        $display;
        count.delete();
        repeat (1000) begin
            assert(ex.randomize() with {
                (value % 4) == 0;
                // value[1:0] = 0;
            });
            count[ex.value]++;
        end
        Ex1::print_histogram(count);

        // Ex6
        $display;
        count.delete();
        repeat (1000) begin
            assert(ex.randomize() with {
                (mode == READ) -> value == 0;
                (mode == WRITE) -> value != 0;
            });
            count[ex.value]++;
        end
        Ex1::print_histogram(count);

        // Ex7
        $display;
        begin
            Ex7 ex7 = new();
            repeat (20) begin
                assert(ex7.randomize());
                $write("size=%0d: [", ex7.arr.size());
                foreach (ex7.arr[i])
                    $write("%0d%s", ex7.arr[i], (i < ex7.arr.size()-1) ? ", " : "");
                $display("]");
            end
        end

        // Ex8
        $display;
        count.delete();
        begin
            Ex8 ex8 = new();
            repeat (16) begin
                assert(ex8.randomize());
                $write("%0d ", ex8.value);
                count[ex8.value]++;
            end
            $display;
            Ex1::print_histogram(count);
        end

        // Ex9
        $display;
        count.delete();
        begin
            Ex9 ex9 = new();
            repeat (1000) begin
                assert(ex9.randomize());
                count[ex9.x]++;
            end
            Ex1::print_histogram(count);
        end

        // Ex10
        $display;
        count.delete();
        begin
            Ex10 ex10 = new();
            repeat (1000) begin
                assert(ex10.randomize());
                count[ex10.y]++;
            end
            Ex1::print_histogram(count);
        end

        // Ex10 with solve
        $display;
        count.delete();
        begin
            Ex10_solve ex10s = new();
            repeat (1000) begin
                assert(ex10s.randomize());
                count[ex10s.y]++;
            end
            Ex1::print_histogram(count);
        end
    end
endprogram : test
