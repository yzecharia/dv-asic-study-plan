interface arb_if_modport(input bit clk);
    logic [1:0] grant, request;
    bit rst;

    clocking cb @(posedge clk);
        output request;
        input grant;
    endclocking : cb

    /*
    clocking cb @(posedge clk);
        default input #15 output #10;
        output request;
        input grant
    endclocking : cb

    In this clocking block the inputs are sampled 15 ns before the posedge clk and the outputs  are driven 10 ns after the posedge clk.

    Can also be written as so:
    clocking cb @(posedge clk);
        ouput #10ns request;
        input #15ns grant;
    endclocking : cb   
    */

    modport TEST (
        clocking cb,
        output rst
    );

    modport DUT (
        input request, rst, clk, 
        output grant
    );

    modport MONITOR (
        input request, grant, rst, clk
    );
endinterface : arb_if_modport