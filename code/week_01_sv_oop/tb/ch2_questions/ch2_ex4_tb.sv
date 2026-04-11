// ============================================================================
// Chapter 2, Exercise 4 — Multi-dimensional unpacked arrays
// ============================================================================
//
// QUESTION:
//   Declare a 5 by 31 multi-dimensional unpacked array, my_array1.
//   Each element holds a 4-state value.
//
// DECLARATION:
//   logic my_array1[5][31];
//
//   - logic = 4-state (0, 1, X, Z)
//   - [5]   = first dimension, indices 0..4
//   - [31]  = second dimension, indices 0..30
//   - each element is 1-bit (single logic)
//
// ============================================================================
// PART (a): Which assignments are legal and not out of bounds?
//
//   my_array1[4][30] = 1'b1;    ✅ LEGAL
//     - [4] is valid (0..4), [30] is valid (0..30)
//
//   my_array1[29][4] = 1'b1;    ❌ ILLEGAL — OUT OF BOUNDS
//     - [29] is out of bounds! First dimension only goes 0..4
//     - The write is silently ignored at runtime
//
//   my_array1[4]     = 32'b1;   ❌ ILLEGAL — TYPE MISMATCH
//     - my_array1[4] is a sub-array of 31 elements, not a scalar
//     - You can't assign a 32-bit value to an unpacked array
//     - This is a COMPILE ERROR
//
// ============================================================================
// PART (b): Draw my_array1 after legal assignments complete
//
//   Initial state: all elements = X (4-state logic, uninitialized)
//
//   After my_array1[4][30] = 1'b1:
//
//          [0]  [1]  [2]  ...  [29] [30]
//   [0]     x    x    x   ...   x    x
//   [1]     x    x    x   ...   x    x
//   [2]     x    x    x   ...   x    x
//   [3]     x    x    x   ...   x    x
//   [4]     x    x    x   ...   x    1    <-- only this one changed
//
//   Everything is X except my_array1[4][30] = 1
//
// ============================================================================

module ch2_ex4_tb;

    // Declaration: 5 x 31 unpacked array of 4-state values
    logic my_array1[5][31];

    initial begin

        $display("=== Exercise 4: Multi-dimensional unpacked arrays ===\n");

        // Show initial state (should be X — 4-state uninitialized)
        $display("--- Initial state (all X for 4-state logic) ---");
        $display("my_array1[0][0]  = %b", my_array1[0][0]);
        $display("my_array1[4][30] = %b", my_array1[4][30]);

        // ── Assignment 1: my_array1[4][30] = 1'b1 ──
        // LEGAL: [4] in range 0..4, [30] in range 0..30
        my_array1[4][30] = 1'b1;
        $display("\n--- After my_array1[4][30] = 1'b1 (LEGAL) ---");
        $display("my_array1[4][30] = %b  ✅", my_array1[4][30]);

        // ── Assignment 2: my_array1[29][4] = 1'b1 ──
        // ILLEGAL: index 29 is out of bounds (first dim is 0..4)
        // Write is silently ignored at runtime
        my_array1[29][4] = 1'b1;
        $display("\n--- After my_array1[29][4] = 1'b1 (OUT OF BOUNDS) ---");
        $display("Write was silently ignored (index 29 > max 4)");

        // ── Assignment 3: my_array1[4] = 32'b1 ──
        // ILLEGAL: my_array1[4] is a sub-array, not a scalar
        // This would be a COMPILE ERROR, so we can't include it.
        // Uncomment to see the error:
        // my_array1[4] = 32'b1;  // ERROR: can't assign scalar to unpacked array
        $display("\n--- my_array1[4] = 32'b1 (COMPILE ERROR) ---");
        $display("Cannot assign a scalar to an unpacked sub-array");
        $display("my_array1[4] is 31 elements, not a single value");

        // ── Part (b): Show final state ──
        $display("\n--- Final state of my_array1 (Part b) ---");
        $display("Only my_array1[4][30] = 1, everything else = x\n");

        // Print the full array to prove it
        $display("Printing all non-X elements:");
        begin
            int count;
            count = 0;
            foreach (my_array1[i, j]) begin
                if (!$isunknown(my_array1[i][j])) begin
                    $display("  my_array1[%0d][%0d] = %b", i, j, my_array1[i][j]);
                    count++;
                end
            end
            $display("Total non-X elements: %0d (out of %0d)",
                count, 5 * 31);
        end

        // Visual representation of row [4]
        $display("\n--- Visual: Row [4] (only row with a change) ---");
        $write("  [4]: ");
        for (int j = 0; j < 31; j++) begin
            if (my_array1[4][j] === 1'bx)
                $write("x");
            else
                $write("%0b", my_array1[4][j]);
        end
        $display("  <-- bit [30] is '1'\n");

        $finish;
    end

endmodule
