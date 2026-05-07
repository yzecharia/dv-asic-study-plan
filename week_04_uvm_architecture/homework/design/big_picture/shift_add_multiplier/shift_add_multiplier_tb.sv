// Design HW3 — Shift-Add Multiplier TB. Spec: docs/week_04.md (Design HW3).
module shift_add_multiplier_tb;

    localparam WIDTH = 8;

    logic clk, rst_n;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task reset_dut();
        rst_n = 1'b0;
        #20 rst_n = 1'b1;
    endtask : reset_dut

    logic [WIDTH-1:0] a, b;
    logic valid_in, valid_out;
    logic [2*WIDTH-1:0] d_out;

    task drive(logic [WIDTH-1:0] iA, logic [WIDTH-1:0] iB, logic v_in);
        @(posedge clk);
        #1;
        a = iA;
        b = iB;
        valid_in = v_in;
    endtask : drive

    shift_add_multiplier #(WIDTH) DUT (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .valid_in(valid_in),
        .d_out(d_out),
        .valid_out(valid_out)
    );

    int pass_count, fail_count;

    task test_one(logic [WIDTH-1:0] iA, logic [WIDTH-1:0] iB);
        logic [2*WIDTH-1:0] expected;
        expected = (2*WIDTH)'(iA) * (2*WIDTH)'(iB);
        drive(iA, iB, 1'b1);
        drive(iA, iB, 1'b0);
        wait (valid_out == 1'b1);
        if (d_out !== expected) begin
            $error("FAIL a=%0d b=%0d expected=%0d got=%0d", iA, iB, expected, d_out);
            fail_count++;
        end else begin
            pass_count++;
        end
    endtask : test_one

    initial begin
        pass_count = 0;
        fail_count = 0;
        valid_in = 1'b0;
        a = '0;
        b = '0;
        reset_dut();
        @(posedge clk);

        test_one(8'd0,   8'd123);
        test_one(8'd0,   8'd0);
        test_one(8'd1,   8'd200);
        test_one(8'd200, 8'd1);
        test_one(8'd255, 8'd255);
        test_one(8'd128, 8'd2);
        test_one(8'd17,  8'd13);

        repeat (100) begin
            test_one(WIDTH'($urandom_range(0, 255)), WIDTH'($urandom_range(0, 255)));
        end

        if (fail_count == 0)
            $display("SHIFT_ADD_MULTIPLIER_TB PASS  %0d/%0d", pass_count, pass_count + fail_count);
        else
            $display("SHIFT_ADD_MULTIPLIER_TB FAIL  %0d errors out of %0d", fail_count, pass_count + fail_count);
        $finish;
    end


endmodule : shift_add_multiplier_tb
