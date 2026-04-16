module mem (simple_bus sb);
    bit [7:0] data, addr;
    event write_event;
    
    cover property (@(posedge sb.clk) sb.write_ena == 1) -> write_event;
endmodule : mem

program automatic test(simple_bus sb);
    covergroup Write_cg @($root.top.m1.write_event);
        coverpoint $root.top.m1.data;
        coverpoint $root.top.m1.addr;
    endgroup : Write_cg

    Write_cg wcg;

    initial begin
        wcg = new();
        sb.write_ena <= 1; 
        #10000ns $finish;
    end
endprogram : test