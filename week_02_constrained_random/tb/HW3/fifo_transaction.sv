class FifoTransaction;
    typedef enum {PUSH, POP, PUSH_AND_POP, IDLE} op_e;
    rand op_e operation;
    rand bit [31:0] write_data;
    rand int unsigned delay;

    constraint c_delay {
        delay inside {[0:5]};
    }

    constraint c_op_dist {
        operation dist {PUSH :/ 40, POP :/ 30, PUSH_AND_POP :/ 20, IDLE :/ 10};
    }

    constraint c_write {
        !((operation == PUSH) || (operation == PUSH_AND_POP)) -> write_data == 0;
    }

endclass : FifoTransaction

class FifoTransactionGenerator;
    int unsigned num_transactions;
    FifoTransaction txn_queue[$];
    
    function new(int unsigned n);
        num_transactions = n;
    endfunction : new

    function void gen();
        repeat (num_transactions) begin
            FifoTransaction ftr = new();
            assert(ftr.randomize());
            txn_queue.push_back(ftr);
        end
    endfunction : gen

    function void display_all();
        foreach (txn_queue[i]) begin
            $display("txn (%0d): operation=%s, write_data=%0h, delay=%0d",
                     i, txn_queue[i].operation.name(), txn_queue[i].write_data, txn_queue[i].delay);
        end
    endfunction : display_all

    function void get_stats();
        int count[FifoTransaction::op_e];
        foreach (txn_queue[i]) begin
            count[txn_queue[i].operation]++;
        end
        foreach (count[op]) begin
            $display("%s: %0d", op.name(), count[op]);
        end
    endfunction : get_stats 

endclass : FifoTransactionGenerator

program automatic test;
    initial begin
        FifoTransactionGenerator ftg = new(1000);
        ftg.gen();
        ftg.get_stats();
    end
endprogram : test