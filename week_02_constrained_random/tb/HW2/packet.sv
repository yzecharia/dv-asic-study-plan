class Packet;

    rand bit [7:0] src_addr;
    rand bit [7:0] dst_addr;
    rand bit [31:0] data;
    rand bit [3:0] length;
    bit [15:0] crc;

    function new(input bit [7:0] src_addr = 8'b0, input bit [7:0] dst_addr = 8'b0, input bit [31:0] data = 32'b0, input bit [3:0] length = 4'b0);
        this.src_addr = src_addr;
        this.dst_addr = dst_addr;
        this.data = data;
        this.length = length;
    endfunction : new

    function void calc_crc();
        this.crc = src_addr ^ dst_addr ^ data ^ length;
    endfunction : calc_crc

    function void display();
        $display("Packet: src_addr=%0h, dst_addr=%0h, data=%0h, length=%0h, crc=%0h",
                src_addr, dst_addr, data, length, crc);
    endfunction : display

    function Packet copy();
        Packet cpy = new(src_addr, dst_addr, data, length);
        cpy.crc = crc;
        return cpy;
    endfunction : copy


    function bit compare(input Packet pck);
        return {src_addr, dst_addr, data, length, crc} == {pck.src_addr, pck.dst_addr, pck.data, pck.length, pck.crc};
    endfunction : compare
endclass : Packet