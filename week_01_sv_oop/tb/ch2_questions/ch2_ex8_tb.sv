module ch2_ex8_tb;

byte q[$] = '{2, -1, 127};
byte tmp[$];

initial begin
    $display("Sum of queue = %0d", q.sum());
    tmp = q.min(); $display("Queue min = %0d", tmp[0]);
    tmp = q.max(); $display("Queue max = %0d", tmp[0]);
    q.sort();
    $display("Sorted Queue = %p", q);
    begin
        int  idx[$] = q.find_index with (item < 0);
        byte pos[$] = q.find with (item > 0);
        $display("Indexes of neg elements: %p", idx);
        $display("Positive elements: %p", pos);
    end
    q.rsort();
    $display("Reversed sorted queue = %p", q);

end

endmodule