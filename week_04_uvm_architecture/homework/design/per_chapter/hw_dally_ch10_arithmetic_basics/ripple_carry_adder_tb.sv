module ripple_carry_adder_tb;

    localparam WIDTH = 8;
    logic [WIDTH-1:0] a, b, s;
    logic             cin, cout;
    logic [WIDTH:0]   expected_val;
    logic [10:0]      pass_tests_num = '0;   

    ripple_carry_adder #(WIDTH) adder (.a(a), .b(b), .cin(cin), .s(s), .cout(cout));

    initial begin
        drive(8'h00, 8'h00, 1'b0);   // all-zero (sanity)
        drive(8'h00, 8'h00, 1'b1);   // cin-only (carry from below into bit 0)
        drive(8'hFF, 8'h00, 1'b0);   // operand max, no propagation
        drive(8'hFF, 8'h01, 1'b0);   // FULL carry chain bit-0 → cout
        drive(8'hFF, 8'hFF, 1'b1);   // all-ones plus cin (max sum)
        drive(8'h80, 8'h80, 1'b0);   // ONLY the top bit generates a carry
        drive(8'h55, 8'hAA, 1'b0);   // every bit propagates, NONE generates
        drive(8'h7F, 8'h01, 1'b0);   // carry walks 7 bits then stops at MSB

        repeat (1000) begin
            a   = WIDTH'($urandom);
            b   = WIDTH'($urandom);
            cin = 1'($urandom);
            #5;
            verify_ans();
        end

        if (pass_tests_num == 1008)
            $display("Test PASS — 8 directed + 1000 random = 1008 vectors");
        else
            $display("Test FAIL — only %0d of 1008 vectors passed", pass_tests_num);
        $finish;
    end


    task drive(input logic [WIDTH-1:0] da,
               input logic [WIDTH-1:0] db,
               input logic             dcin);
        a   = da;
        b   = db;
        cin = dcin;
        #5;
        verify_ans();
    endtask : drive

    task verify_ans();
        expected_val = a + b + cin;
        if (expected_val !== {cout, s})
            $fatal(1, "FATAL: a=%0h b=%0h cin=%0h | expected=%0h actual=%0h",
                   a, b, cin, expected_val, {cout, s});
        else
            pass_tests_num = pass_tests_num + 1;
    endtask : verify_ans

endmodule : ripple_carry_adder_tb
