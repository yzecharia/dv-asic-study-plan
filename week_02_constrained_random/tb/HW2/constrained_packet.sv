`include "packet.sv"
class ConstrainedPacket extends Packet;
    typedef enum {SMALL, MEDIUM, LARGE} size_e;
    rand size_e size_c;
    rand bit [7:0] payload[]; // dynamic array

    constraint c_size {
        (size_c == SMALL) -> payload.size() inside {[1:4]};
        (size_c == MEDIUM) -> payload.size() inside {[5:16]};
        (size_c == LARGE) -> payload.size() inside {[17:64]};        
    }

    constraint c_addr {
        src_addr != dst_addr; // No loopback;
    }

    constraint c_dst_addr_size {
        (dst_addr == 8'hFF) -> size_c == SMALL;
    }

    constraint c_dist {
        size_c dist {SMALL :/ 50, MEDIUM :/ 30, LARGE :/ 20};
    }
endclass : ConstrainedPacket

program automatic test;
    initial begin
        ConstrainedPacket pkt = new();
        repeat (100) begin
            assert(pkt.randomize());
            pkt.display();
            $display(" category: %s, payload= %p", pkt.size_c.name(), pkt.payload);
        end

        pkt.c_dist.constraint_mode(0);
        repeat (100) begin
            assert(pkt.randomize());
            pkt.display();
            $display(" category: %s, payload= %p", pkt.size_c.name(), pkt.payload);
        end

        pkt.c_dist.constraint_mode(1);
        assert(pkt.randomize() with {dst_addr == 8'hFF;});
        assert(pkt.size_c == SMALL);
        pkt.display();
        $display(" category: %s, payload= %p", pkt.size_c.name(), pkt.payload);
    end
endprogram : test