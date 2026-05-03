// top -> testbench -> tester -> scoreboard -> coverage

class transaction;
    int a, b, expected;
endclass : transaction

class scoreboard;
    function void write(transaction tr);
        $display("Transaction: a=%0d, b=%0d, expexted=%0d", tr.a, tr.b, tr.expected);
    endfunction : write
endclass : scoreboard

class driver;
    scoreboard sb;

    task run();
        repeat (5) begin
            transaction tr = new();
            tr.a = $urandom;
            tr.b = $urandom;
            tr.expected = tr.a + tr.b;
            sb.write(tr);
            #10ns;
        end
    endtask : run
endclass : driver

class env;
    driver drv;
    scoreboard sb;

    function new();
        drv = new();
        sb = new();
        drv.sb = sb;
    endfunction : new

    task run();
        fork
            drv.run();
        join_none
    endtask : run;

endclass : env


module top;
    env tb_env;
    initial begin
        tb_env = new();
        tb_env.run();
        #200ns;
        $finish;
    end
endmodule : top