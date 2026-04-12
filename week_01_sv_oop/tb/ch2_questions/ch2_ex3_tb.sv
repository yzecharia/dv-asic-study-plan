// ============================================================================
// Chapter 2, Exercise 3 — 2-state array, initialization, bit slicing
// ============================================================================
// Compile & run:
//   iverilog -g2012 -o build/ch2_ex3.out tb/ch2_ex3_tb.sv
//   vvp build/ch2_ex3.out
// ============================================================================

module ch2_ex3_tb;

    // (a) Declare a 2-state array with four 12-bit values
    bit [11:0] my_array[4];

    initial begin

        // (b) Initialize
        my_array = '{12'h012, 12'h345, 12'h678, 12'h9AB};

        // Verify initialization
        $display("=== Initialization ===");
        foreach (my_array[i])
            $display("my_array[%0d] = 12'h%h = %b", i, my_array[i], my_array[i]);

        // (c) Print bits [5:4] with a for loop
        $display("\n=== Bits [5:4] using for loop ===");
        for (int i = 0; i < $size(my_array); i++)
            $display("my_array[%0d][5:4] = %b", i, my_array[i][5:4]);

        // (c) Print bits [5:4] with a foreach loop
        $display("\n=== Bits [5:4] using foreach loop ===");
        foreach (my_array[i])
            $display("my_array[%0d][5:4] = %b", i, my_array[i][5:4]);

        $finish;
    end

endmodule
