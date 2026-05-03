module lcu4_tb ();
    logic [3:0] bg, bp;
    logic       cin, carry_out, bg_grp, bp_grp;
    logic [3:1] cout;

    logic [4:1] expected_cout;

    lcu4 lcu01 (
        .bg(bg), .bp(bp), .cin(cin),
        .cout(cout), .carry_out(carry_out),
        .bg_grp(bg_grp), .bp_grp(bp_grp)
    );

    initial begin
        for (int i = 0; i < 16; i++) begin
            for (int j = 0; j < 16; j++) begin
                drive(i[3:0], j[3:0], 1'b0);
                drive(i[3:0], j[3:0], 1'b1);
            end
        end
        $display("Test PASS - 512 vectors");
        $finish;
    end

    task drive(input logic [3:0] bg_d, bp_d, input logic cin_d);
        bg  = bg_d;
        bp  = bp_d;
        cin = cin_d;
        #1;
        verify_drive();
    endtask 

    function automatic logic [4:1] golden_lcu(input logic [3:0] g, p, input logic ci);
        logic [4:0] chain;
        chain[0] = ci;
        for (int i = 0; i < 4; i++) chain[i+1] = g[i] | (p[i] & chain[i]);
        return chain[4:1];
    endfunction : golden_lcu

    function automatic logic golden_bg_grp(input logic [3:0] g, p);
        logic c;
        c = 1'b0;
        for (int i = 0; i < 4; i++) c = g[i] | (p[i] & c);
        return c;
    endfunction : golden_bg_grp

    task verify_drive();
        expected_cout = golden_lcu(bg, bp, cin);

        if (cout      !== expected_cout[3:1])   $fatal(1, "FATAL cout: bg=%0h bp=%0h cin=%0d got=%0h expected=%0h", bg, bp, cin, cout, expected_cout[3:1]);
        if (carry_out !== expected_cout[4])     $fatal(1, "FATAL carry_out: bg=%0h bp=%0h cin=%0d got=%0h expected=%0h", bg, bp, cin, carry_out, expected_cout[4]);
        if (bp_grp    !== &bp)                  $fatal(1, "FATAL bp_grp: bg=%0h bp=%0h got=%0h expected=%0h", bg, bp, bp_grp, &bp);
        if (bg_grp    !== golden_bg_grp(bg, bp)) $fatal(1, "FATAL bg_grp: bg=%0h bp=%0h got=%0h expected=%0h", bg, bp, bg_grp, golden_bg_grp(bg, bp));
    endtask : verify_drive

endmodule : lcu4_tb
