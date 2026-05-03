`include "hw2_transaction.sv"
`include "hw2_read_transaction.sv"
`include "hw2_write_transaction.sv"

program automatic test;
    Transaction txn_queue[$]; 

    initial begin
        repeat (5) begin
            ReadTransaction rd = new();
            assert(rd.randomize());
            txn_queue.push_back(rd);
        end
        repeat (5) begin
            WriteTransaction wr = new();
            assert(wr.randomize());
            txn_queue.push_back(wr);
        end

        foreach(txn_queue[i]) txn_queue[i].display();

        begin
            ReadTransaction rd_handle;
            if ($cast(rd_handle, txn_queue[0])) $display("latency = %0d", rd_handle.latency);
        end
    end
endprogram : test