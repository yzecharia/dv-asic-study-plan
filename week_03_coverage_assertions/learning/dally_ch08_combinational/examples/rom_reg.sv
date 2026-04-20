module rom_reg #(
    parameter B = 32, W = 4,
    parameter FILE_NAME = "dataFile"
) (
    input  logic [W-1:0] a,
    output logic [B-1:0] d
);

    logic [B-1:0] rom [2**W-1:0];

    initial begin
        $readmemh(FILE_NAME, rom);
    end

    assign d = rom[a];

endmodule