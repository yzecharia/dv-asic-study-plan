module test_with_ifc (arb_if arbif);
    initial begin
        @(posedge arbif.clk);
        arbif.request <= 2'b01;
        $display("[%0t]: Drove req=%b", $time, arbif.request);
        repeat (2) begin
            @(posedge arbif.clk);
        end
        if (arbif.grant != 2'b01) $display("[%0t]: Error: grant != 2'b01", $time);
        $finish;
    end
endmodule : test_with_ifc