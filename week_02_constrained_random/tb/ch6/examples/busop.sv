// Sample 6.9

// Bus operation, byte, word, or longword
class BusOp;
    typedef enum {BYTE, WORD, LWRD} length_e;
    rand length_e len;

    // Weights for dist constraints
    bit [31:0] w_byte=1, w_word=3, w_lwrd=5;

    constraint c_len {
        len dist {
            BYTE := w_byte,
            WORD := w_word,
            LWRD := w_lwrd
        };
        // 1 + 3 + 5 = 9 => BYTE = 1/9; WORD = 3/9; LWRD=5/9;
    }

endclass : BusOp    