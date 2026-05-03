module cla_adder_tb;

    logic [15:0] a, b, s;
    logic cin, cout, bp_grp, bg_grp;

    logic [15:0] expected_s;
    logic expected_cout;
    int pass_count = 0;
    cla_adder adder(.*);

    initial begin
        drive(16'h0000, 16'h0000, 1'b0);
        drive(16'h0000, 16'h0000, 1'b1);
        drive(16'hFFFF, 16'h0000, 1'b0);
        drive(16'hFFFF, 16'h0001, 1'b0);
        drive(16'hFFFF, 16'hFFFF, 1'b1);
        drive(16'h8000, 16'h8000, 1'b0);
        drive(16'h5555, 16'hAAAA, 1'b0);
        drive(16'h0FFF, 16'h0001, 1'b0);
        repeat (1000) begin
            drive(16'($urandom), 16'($urandom), 1'($urandom));
        end
        if (pass_count == 1008) $display("Test PASS - 1008 vectors");
        else $display("Test FAIL - only %0d of 1008", pass_count);
        $finish;
    end

    task drive(input logic [15:0] a_d, b_d, input logic cin_d);
        a = a_d;
        b = b_d;
        cin = cin_d;
        #1;
        verify_drive();
    endtask : drive

    task verify_drive();
        {expected_cout, expected_s} = a + b + cin;

        if (expected_cout !== cout) $fatal(1, "FATAL cout: a=%0h b=%0h cin=%0d got=%0d expected=%0d", a, b, cin, cout, expected_cout);
        if (expected_s !== s) $fatal(1, "FATAL s: a=%0h b=%0h cin=%0d got=%0h expected=%0h", a, b, cin, s, expected_s);
        pass_count = pass_count + 1;
    endtask : verify_drive


endmodule : cla_adder_tb
