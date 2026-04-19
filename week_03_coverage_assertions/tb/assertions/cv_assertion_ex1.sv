module tb;
    bit a, b;
    bit clk;

    always #10 clk = ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb);
        for (int i=0; i<10; i++) begin
            @(posedge clk);
            a <= $random; 
            b <= $random;
            $display("[%0t] a=%b, b=%b", $time, a, b);
        end
        #10 $finish;
    end

    assert property (@(posedge clk) a & b);
    assert property (@(posedge clk) a | b);
    assert property (@(posedge clk) !(!a ^ b));

endmodule