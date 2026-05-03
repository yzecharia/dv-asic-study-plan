module ch2_ex7_tb;

bit [23:0] mem[bit[19:0]];

initial begin
    mem[20'h00000] = 24'hA50400;
    mem[20'h00400] = 24'h123456;
    mem[20'h00401] = 24'h789ABC;
    mem[20'hFFFFF] = 24'h0F1E2D;

    $display("Number of elements = %0d", mem.num());
    foreach (mem[addr])
        $display ("mem[%h] = %h", addr,mem[addr]);

end

endmodule
