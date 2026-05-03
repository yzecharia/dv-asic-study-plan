// rom (fixed width) built with a case statement
module rom_case (a, d);
    input  [3:0] a;
    output [7:0] d;
    reg    [7:0] d;

    always @(*) begin
        case (a)
            4'h0: d = 8'h00;
            4'h1: d = 8'h11;
            4'h2: d = 8'h22;
            4'h3: d = 8'h33;
            4'h4: d = 8'h44;
            4'h5: d = 8'h12;
            4'h6: d = 8'h34;
            4'h7: d = 8'h56;
            4'h8: d = 8'h78;
            4'h9: d = 8'h9a;
            4'ha: d = 8'hbc;
            4'hb: d = 8'hde;
            4'hc: d = 8'hf0;
            4'hd: d = 8'h12;
            4'he: d = 8'h34;
            4'hf: d = 8'h56;
            default: d = 8'h0;
        endcase // case (a)
    end // always @(*)
endmodule