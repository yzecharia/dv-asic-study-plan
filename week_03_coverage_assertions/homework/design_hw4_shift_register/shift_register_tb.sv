// Design HW4 — Shift register TB
// Spec: docs/week_03.md, Design HW4
//   1. Load 0xA5, shift left 8 times, capture serial_out → should reconstruct 0xA5
//   2. Test right-shift mode similarly
//   3. Verify load overrides an in-progress shift

`include "shift_register.sv"

module shift_register_tb;

    // TODO: implement
    localparam WIDTH = 8;
    logic clk, rst_n;
    logic shift_en, load;
    logic [WIDTH-1:0] data_in;
    logic serial_in_l, serial_in_r;
    logic [WIDTH-1:0] data_out_l, data_out_r;
    logic serial_out_l, serial_out_r;

    shift_register #(.DIRECTION("LEFT")) DUT_LEFT (clk, rst_n, shift_en, load, data_in, serial_in_l, data_out_l, serial_out_l);
    shift_register #(.DIRECTION("RIGHT")) DUT_RIGHT (clk, rst_n, shift_en, load, data_in, serial_in_r, data_out_r, serial_out_r);

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $display("TODO: shift_register_tb");

        rst_n = 0; load = 0; shift_en = 0; serial_in_l = 0; serial_in_r = 0; data_in = '0;
        #20 rst_n = 1;

        @(posedge clk); data_in = 8'hA5; load = 1;
        #20 @(posedge clk); load = 0;

        repeat (8) begin
            shift_en = 1;
            serial_in_l = serial_out_l; serial_in_r = serial_out_r;
            @(posedge clk); 
            $display("[%0t] During shifts (LEFT): data_out=%b, serial_out=%b", $time, data_out_l, serial_out_l);
            $display("[%0t] During shifts (RIGHT): data_out=%b, serial_out=%b", $time, data_out_r, serial_out_r);
        end
        shift_en = 0;
        $display("============== After shifts ==============\n");
        $display("Data out (LEFT) = %b", data_out_l);
        $display("Data out (RIGHT) = %b", data_out_r);

        assert (data_out_l == 8'hA5) else $error("LEFT rotation failed: got %h expected A5", data_out_l);
        assert (data_out_r == 8'hA5) else $error("RIGHT rotation failed: got %h expected A5", data_out_r);

        // Test 3: load overrides shift
        $display("============== Test 3: load overrides shift ==============");
        @(posedge clk); data_in = 8'hF0; load = 1; shift_en = 1;
        @(posedge clk); #1;
        $display("Data out (LEFT)  after simultaneous load+shift = %h", data_out_l);
        $display("Data out (RIGHT) after simultaneous load+shift = %h", data_out_r);
        assert (data_out_l == 8'hF0) else $error("LEFT: load didn't override shift: got %h expected F0", data_out_l);
        assert (data_out_r == 8'hF0) else $error("RIGHT: load didn't override shift: got %h expected F0", data_out_r);
        load = 0; shift_en = 0;
        


        $finish;
    end

endmodule
