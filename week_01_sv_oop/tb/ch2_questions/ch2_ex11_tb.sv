module ch2_ex11_tb;

timeunit 1ns; timeprecision 1ns;

typedef enum bit [1:0] { 
    ADD = 2'b00,
    SUB = 2'b01,
    INVA = 2'b10,
    REDORB = 2'b11
} opcode_e;

opcode_e opcode;


logic [3:0] a = 4'hA;
logic [3:0] b = 4'h3;
logic [3:0] result;

ALU dut (a, b, opcode, result);

initial begin
    opcode = opcode.first();
    do begin
        #10;
        $display("t=%0t opcode=%s (2'b%b) a=%0h b=%0h result=%0h", $time, opcode.name(), opcode, a, b, result);
        opcode = opcode.next();
    end while (opcode != opcode.first());
    $finish;
end

endmodule

module ALU (
    input [3:0] a, b,
    input [1:0] opcode,
    output logic [3:0] result
);
    timeunit 1ns; timeprecision 1ns;
    always_comb begin 
        case (opcode)
            2'b00: result = a + b;
            2'b01: result = a - b;
            2'b10: result = ~a;
            2'b11: result = {3'b0, |b};
            default: result = '0;
        endcase
    end
endmodule