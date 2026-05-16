interface alu_if (input logic clk, reset_n);
    import alu_pkg::*;

    command_monitor command_monitor_h;
    result_monitor result_monitor_h;

    command_t cmd;
    result_t res;
    logic start, done;

    // Edge-detect latches for the BFM always blocks. Declared at interface
    // scope (not inside the always blocks) to guarantee static lifetime —
    // some simulators give in-block declarations automatic lifetime, which
    // would silently break the "fire once per rising edge" semantics.
    bit new_command;
    bit new_result;

    // Initialize start to a known 0 so the BFM's `if (!start)` branch
    // arms new_command on the first cycle. Without this, start defaults
    // to X (logic), `!X` is X, and the edge detector never arms — the
    // very first command is missed.
    initial start = 1'b0;

    modport dut (input cmd, start, clk, reset_n, output res, done);
    modport tb (clocking cb_tb);

    clocking cb_tb @(posedge clk);
        default input #1step output #1;
        output cmd, start;
        input res, done, reset_n;
    endclocking : cb_tb

    always @(posedge clk) begin
        if (!start) new_command = 1'b1;
        else begin
            if (new_command) begin
                command_monitor_h.write_to_monitor(cmd);
                new_command = 1'b0;
            end
        end
    end

    always @(posedge clk) begin
        if (!done) new_result = 1'b1;
        else begin
            if (new_result) begin
                result_monitor_h.write_to_monitor(res);
                new_result = 1'b0;
            end
        end
    end

endinterface : alu_if


