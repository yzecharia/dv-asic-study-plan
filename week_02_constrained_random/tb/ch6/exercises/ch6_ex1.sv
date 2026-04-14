// Exercise 1: data == 5, address inside {[3:4]}
class Exercise1;
    rand bit [7:0] data;
    rand bit [3:0] address;

    constraint c_exercise1 {
        address inside {[3:4]};
        data == 5;
    }

    function void display();
        $display("data=%0d, address=%0d", data, address);
    endfunction : display
endclass : Exercise1


class Exercise2 extends Exercise1;
    constraint c_exercise1 {
        data == 5;
        address dist {0 :/ 10, [1:14] :/ 80, 15 :/ 10};
    }
endclass : Exercise2

// Exercise 3: Generate 20 random values from Exercise2, check solver success
program automatic test;
    initial begin
        // Q1
        begin
            Exercise1 ex1 = new();
            assert(ex1.randomize());
            ex1.display();
        end

        // Q2 + Q3
        begin
            Exercise2 ex2 = new();
            repeat (20) begin
                if (ex2.randomize())
                    ex2.display();
                else
                    $display("Randomization failed!");
            end
        end

        // Q4
        begin
           Exercise2 ex4 = new ();
           int count[16], maxx[$];
           repeat (1000) begin
               if (ex4.randomize()) begin
                    count[ex4.address]++;
               end else begin
                    $display("Randomization Failed");
               end
           end 
           maxx = count.max();
           foreach (count[i]) begin
               $write("address[%2d] = %4d", i, count[i]);
               repeat (count[i] * 40 / maxx[0]) begin
                   $write("#");
               end
               $display;
           end
        end
    end
endprogram : test
