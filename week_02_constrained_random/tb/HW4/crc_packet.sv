class CrcPacket;
    rand bit [7:0] header;
    rand bit [7:0] payload[4];
    bit [7:0] crc; // Not rand - computed after randomization

    function void post_randomize();
        crc = header;
        foreach (payload[i]) begin
            crc ^= payload[i];
        end
    endfunction : post_randomize

endclass : CrcPacket


program automatic test;
    initial begin
        CrcPacket pkt;
        bit [7:0] crc_check;
        bit [7:0] prev_crc = 0;
        int count = 0;

        repeat (20) begin
            pkt = new();
            assert(pkt.randomize());
            pkt.post_randomize();
            crc_check = pkt.header;
            foreach (pkt.payload[i]) begin
                crc_check ^= pkt.payload[i];
            end

            assert(pkt.crc == crc_check);

            if (prev_crc != pkt.crc) count++;
            prev_crc = pkt.crc;

            $display("header=%0h, payload=%p, crc=%0h", pkt.header, pkt.payload, pkt.crc);
        end

        assert(count > 0);
        $display("\nCRC different %d/20 times", count);
    end
endprogram : test