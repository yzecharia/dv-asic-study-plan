class BusOp;
    rand bit [31:0] addr;
    rand bit io_space_mode;

    constraint c_io {
        io_space_mode -> addr[31] == 1'b1; //(!A || B) if A is true B has to be True, and if A is False, B can be true or false
    }
endclass : BusOp