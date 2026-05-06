class testbench;
    virtual tinyalu_bfm bfm;
    scoreboard scoreboard_h;
    tester tester_h;
    coverage coverage_h;

    function new (virtual tinyalu_bfm b);
        this.bfm = b;
        scoreboard_h = new(bfm);
        tester_h = new(bfm);
        coverage_h = new(bfm);
    endfunction : new

    task execute();
        fork
            scoreboard_h.execute();
            tester_h.execute();
            coverage_h.execute();
        join_none
        wait fork;
    endtask : execute

endclass : testbench