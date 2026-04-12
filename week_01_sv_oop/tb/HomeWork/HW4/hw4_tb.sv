class BaseDriver;
    function void drive();
        $display("[BaseDriver] driving");
    endfunction : drive

    virtual function void v_drive();
        $display("[BaseDriver] v_driving");
    endfunction : v_drive
endclass : BaseDriver

class UartDriver extends BaseDriver;
    function void drive();
        $display("[UartDriver] driving");
    endfunction : drive

    virtual function void v_drive();
        $display("[UartDriver] v_driving");
    endfunction : v_drive
endclass : UartDriver

program automatic test;
    initial begin
        BaseDriver d;
        UartDriver u = new();
        d = u;

        $display("=== Non-virtual method ===");
        d.drive();

        $display("\n=== Virtual method ===");
        d.v_drive();
    end
endprogram : test
