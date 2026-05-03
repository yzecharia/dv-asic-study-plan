class StimData;
    rand int samples[];

    constraint c_samples {
        samples.size() inside {[1:1000]};
    }

endclass : StimData

program automatic test;
    initial begin
        StimData sd = new();

        repeat (20) begin
            assert(sd.randomize());
            $display("array[0:%0d]: %p\n\n", sd.samples.size()-1, sd.samples);
        end
    end
endprogram : test