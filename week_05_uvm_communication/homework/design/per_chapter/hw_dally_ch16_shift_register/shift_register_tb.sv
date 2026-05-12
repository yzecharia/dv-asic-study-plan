module shift_register_tb;
    localparam N = 8;
    logic clk;
    logic rst;
    logic load, shift;
    logic [N-1:0] din_parallel, dout_parallel;
    logic din_serial, dout_serial;

    logic [N-1:0] expected_p_dout;
    logic expected_s_dout;

    int pass_count;
    int fail_count;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task reset_dut();
        #20 rst = 1'b1;
        #20 rst = 1'b0;
        #20;
        expected_p_dout = '0;
        expected_s_dout = 1'b0;
    endtask : reset_dut

    shift_register #(.N(N)) sh_reg(clk, rst, load, shift, din_parallel, din_serial,
                                    dout_parallel, dout_serial);

    task load_dut (logic [N-1:0] p_in);
        din_parallel = p_in;
        load = 1'b1;
        @(posedge clk);
        #1 load = 1'b0;
        expected_p_dout = p_in;
        expected_s_dout = p_in[N-1];
    endtask : load_dut

    task enable_shift (logic s_in);
        din_serial = s_in;
        shift = 1'b1;
        @(posedge clk);
        #1 shift = 1'b0;
        expected_p_dout = {expected_p_dout[N-2:0], s_in};
        expected_s_dout = expected_p_dout[N-1];
    endtask : enable_shift

    task hold_dut ();
        load = 1'b0;
        shift = 1'b0;
        @(posedge clk);
        #1;
    endtask : hold_dut

    function void verify(string scenario);
        if (dout_parallel !== expected_p_dout || dout_serial !== expected_s_dout) begin
            $error("FAIL [%s]: dout_p=%h dout_s=%b (expected p=%h s=%b)",
                   scenario, dout_parallel, dout_serial,
                   expected_p_dout, expected_s_dout);
            fail_count++;
        end else begin
            pass_count++;
        end
    endfunction : verify

    initial begin
        rst = 1'b0; load = 1'b0; shift = 1'b0;
        din_parallel = '0; din_serial = 1'b0;
        expected_p_dout = '0; expected_s_dout = 1'b0;
        pass_count = 0; fail_count = 0;

        reset_dut();
        verify("reset");

        load_dut(8'hA5);
        verify("load A5");

        for (int i = 0; i < N; i++) begin
            enable_shift(1'b0);
            verify($sformatf("shift cycle %0d", i+1));
        end

        repeat (100) begin
            case ($urandom_range(0,2))
                0: load_dut(8'($urandom));
                1: enable_shift($urandom & 1'b1);
                2: hold_dut();
            endcase
            verify("random op");
        end

        if (fail_count == 0)
            $display("PASS: %0d / %0d checks passed", pass_count, pass_count);
        else
            $fatal(1, "FAIL: %0d / %0d checks failed",
                   fail_count, pass_count + fail_count);
        $finish;
    end

endmodule : shift_register_tb
