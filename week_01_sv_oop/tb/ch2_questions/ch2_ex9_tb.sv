module ch2_ex9_tb;

typedef bit [7:0] bit7_t;

typedef struct packed {
    bit7_t header;
    bit7_t cmd;
    bit7_t data;
    bit7_t crc;
} packet_t;

packet_t pkt;

initial begin
    pkt.header = 7'h5A;

    $display("The updated header is: %0h", pkt.header);
    $display("packet = 0x%0h", pkt);
    $display("packet = %p", pkt);
end

endmodule