module handshake_sender_sva_tb;

    logic clk, rst_n, send, ready, valid;
    logic [7:0] data_in, data_out;

    handshake_sender DUT (
        .clk      (clk),
        .rst_n    (rst_n),
        .send     (send),
        .ready    (ready),
        .data_in  (data_in),
        .data_out (data_out),
        .valid    (valid)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    property valid_must_hold;
        @(posedge clk) disable iff (!rst_n) (valid && !ready) |=> valid;
    endproperty

    property data_stable;
        @(posedge clk) disable iff (!rst_n) (valid && !ready) |=> $stable(data_out);
    endproperty

    property handshake_complete;
        @(posedge clk) disable iff (!rst_n) valid && ready;
    endproperty

    property cooldown;
        @(posedge clk) disable iff (!rst_n) (valid && ready) |=> !valid;
    endproperty

    property no_unknown;
        @(posedge clk) disable iff (!rst_n) !$isunknown({valid, ready, data_out});
    endproperty

    A_valid_must_hold:    assert property (valid_must_hold)
        else $error("VIOLATION: valid_must_hold @ %0t", $time);
    A_data_stable:        assert property (data_stable)
        else $error("VIOLATION: data_stable @ %0t", $time);
    C_handshake_complete: cover  property (handshake_complete);
    A_cooldown:           assert property (cooldown)
        else $error("VIOLATION: cooldown @ %0t", $time);
    A_no_unknown:         assert property (no_unknown)
        else $error("VIOLATION: no_unknown @ %0t", $time);

    task automatic drive_txn(input [7:0] d, input int ready_delay);
        @(posedge clk); data_in = d; send = 1'b1;
        @(posedge clk); send = 1'b0;
        repeat (ready_delay) @(posedge clk);
        @(posedge clk); ready = 1'b1;
        @(posedge clk); ready = 1'b0;
    endtask

    initial begin
        $dumpfile("handshake_sva.vcd");
        $dumpvars(0, handshake_sender_sva_tb);

        rst_n   = 0;
        send    = 0;
        ready   = 0;
        data_in = 0;
        repeat (3) @(posedge clk);
        rst_n = 1;

        $display("\n[%0t] === Phase 1: Correct handshakes (expect NO failures) ===", $time);
        drive_txn(8'hA5, 3);
        drive_txn(8'h5A, 1);
        drive_txn(8'hFF, 0);

        $display("\n[%0t] === Phase 2: Intentional violations (expect failures) ===", $time);

        $display("\n[%0t] -- Violating valid_must_hold --", $time);
        @(posedge clk); data_in = 8'h11; send = 1'b1;
        @(posedge clk); send = 1'b0;
        @(posedge clk);
        force valid = 1'b0;
        @(posedge clk);
        release valid;
        @(posedge clk); ready = 1'b1;
        @(posedge clk); ready = 1'b0;

        $display("\n[%0t] -- Violating data_stable --", $time);
        @(posedge clk); data_in = 8'h22; send = 1'b1;
        @(posedge clk); send = 1'b0;
        @(posedge clk);
        force data_out = 8'hDE;
        @(posedge clk);
        force data_out = 8'hAD;
        @(posedge clk);
        release data_out;
        @(posedge clk); ready = 1'b1;
        @(posedge clk); ready = 1'b0;

        $display("\n[%0t] -- Violating cooldown --", $time);
        @(posedge clk); data_in = 8'h33; send = 1'b1;
        @(posedge clk); send = 1'b0;
        @(posedge clk); ready = 1'b1;
        force valid = 1'b1;
        @(posedge clk); ready = 1'b0;
        @(posedge clk);
        release valid;

        $display("\n[%0t] -- Violating no_unknown --", $time);
        @(posedge clk); ready = 1'bx;
        @(posedge clk); ready = 1'b0;

        $display("\n[%0t] === Phase 3: $assertoff / $asserton ===", $time);

        $display("\n[%0t] Disabling A_valid_must_hold -- next violation stays silent", $time);
        $assertoff(0, A_valid_must_hold);

        @(posedge clk); data_in = 8'h44; send = 1'b1;
        @(posedge clk); send = 1'b0;
        @(posedge clk);
        force valid = 1'b0;
        @(posedge clk);
        release valid;
        @(posedge clk); ready = 1'b1;
        @(posedge clk); ready = 1'b0;

        $display("\n[%0t] Re-enabling A_valid_must_hold", $time);
        $asserton(0, A_valid_must_hold);

        repeat (3) @(posedge clk);

        $display("\n[%0t] Disabling ALL assertions with $assertoff(0)", $time);
        $assertoff(0);

        @(posedge clk); data_in = 8'h55; send = 1'b1;
        @(posedge clk); send = 1'b0;
        @(posedge clk);
        force valid = 1'b0;
        force data_out = 8'h00;
        @(posedge clk);
        release valid;
        release data_out;
        @(posedge clk); ready = 1'b1;
        @(posedge clk); ready = 1'b0;

        $display("\n[%0t] Re-enabling ALL assertions with $asserton(0)", $time);
        $asserton(0);

        repeat (5) @(posedge clk);
        $display("\n[%0t] === Test complete ===", $time);
        $finish;
    end

endmodule
