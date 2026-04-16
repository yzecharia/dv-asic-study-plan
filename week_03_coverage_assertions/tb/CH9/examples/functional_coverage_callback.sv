program automatic test;
    Enviroment env;

    initial begin
        Driver_cbs_coverage dcc;
        
        env = new();
        env.gen_cfg();
        env.build();

        // Create and register the coverage callback
        dcc = new();
        env.drv.cbs_push_back(dcc); // Put into drivers Q

        env.run();
        env.wrap_up();
    end
endprogram : test