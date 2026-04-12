class ScoreBoard;
    Transaction scb[$];

    function void save_expected(input Transaction tr);
        scb.push_back(tr);
    endfunction : save_expected

    function void compare_actual(input Transaction tr);
        int q[$];
        q = scb.find_index(x) with (x.src == tr.src);
        case(q.size())
            0: $display("No match found");
            1: scb.delete(q[0]);
            default: $display("Error, Multipule matches found");
        endcase
    endfunction : compare_actual
endclass : ScoreBoard


class Driver_cbs_scoreboard extends Driver_cbs;
    ScoreBoard scb;
    virtual task pre_tx(ref Transaction tr, ref bit drop);
        scb.push_back(tr) // Put the transaction into the scoreboard
    endtask : pre_tx

    function new(input ScoreBoard scb);
        this.scb = scb;
    endfunction : new
endclass : Driver_cbs_scoreboard

program automatic test;
    Enviroment env;
    initial begin
        env = new();
        env.gen_cfg();
        env.build();

        begin
            Driver_cbs_scoreboard dcs = new(env.scb);
            env.drv.cbs.push_back(dcs);
        end

        env.run();
        env.wrap();
    end
endprogram : test