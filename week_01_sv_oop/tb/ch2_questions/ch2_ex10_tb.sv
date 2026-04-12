module ch2_ex10_tb;

typedef bit [3:0] nibble;
real r = 4.33;
shortint i_pack;
nibble k[4] = '{4'h0, 4'hF, 4'hE, 4'hD};

initial begin
    $display("k array =  %p", k);

    i_pack = {<<{k}};
    $display("i_pack (bit reversed) = 0x%0h", i_pack);

    i_pack = {<<nibble{k}};
    $display("i_pack (nibble reversed) = 0x%0h", i_pack);

    k[0] = nibble'(r);
    $display("k after k[0] = nibble'(r) = %p", k);


end


endmodule