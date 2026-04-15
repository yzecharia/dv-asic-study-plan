`include "packet.sv"
class ConstrainedPacket extends Packet;
    typedef enum {SMALL, MEDIUM, LARGE} size_e;
    rand size_e size_c;
    rand bit [7:0] payload[];

    constraint c_size {
        (size_c == SMALL) -> payload.size() inside {[1:4]};
        (size_c == MEDIUM) -> payload.size() inside {[5:16]};
        (size_c == LARGE) -> payload.size() inside {[17:64]};
    }

    constraint c_addr {
        src_addr != dst_addr;
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
        int small_cnt, medium_cnt, large_cnt;

        $display("=== Part 1: 100 packets with distribution constraint ===");
        small_cnt = 0; medium_cnt = 0; large_cnt = 0;
        repeat (100) begin
            assert(pkt.randomize());
            assert(pkt.src_addr != pkt.dst_addr);
            if (pkt.dst_addr == 8'hFF) assert(pkt.size_c == SMALL);
            case (pkt.size_c)
                SMALL:  begin assert(pkt.payload.size() inside {[1:4]});  small_cnt++;  end
                MEDIUM: begin assert(pkt.payload.size() inside {[5:16]}); medium_cnt++; end
                LARGE:  begin assert(pkt.payload.size() inside {[17:64]}); large_cnt++; end
            endcase
        end
        $display("  SMALL=%0d%% MEDIUM=%0d%% LARGE=%0d%%", small_cnt, medium_cnt, large_cnt);

        // Part 2: Disable distribution, regenerate, show difference
        $display("\n=== Part 2: distribution disabled ===");
        pkt.c_dist.constraint_mode(0);
        small_cnt = 0; medium_cnt = 0; large_cnt = 0;
        repeat (100) begin
            assert(pkt.randomize());
            case (pkt.size_c)
                SMALL:  small_cnt++;
                MEDIUM: medium_cnt++;
                LARGE:  large_cnt++;
            endcase
        end
        $display("  SMALL=%0d%% MEDIUM=%0d%% LARGE=%0d%%", small_cnt, medium_cnt, large_cnt);

        // Part 3: Inline constraint forces broadcast, verify SMALL
        $display("\n=== Part 3: dst_addr == 0xFF forces SMALL ===");
        pkt.c_dist.constraint_mode(1);
        repeat (10) begin
            assert(pkt.randomize() with {dst_addr == 8'hFF;});
            assert(pkt.size_c == SMALL);
            $display("  dst=%0h size=%s payload_size=%0d", pkt.dst_addr, pkt.size_c.name(), pkt.payload.size());
        end

        $display("\nAll assertions passed!");
    end
endprogram : test
