# Memory Models — SRAM, BRAM, Register File

**Category**: Memory · **Used in**: W6 (dual-port RAM), W7 (regfile), W8 (regfile in CPU), W18 (line buffers) · **Type**: auto-stub

Memory blocks come in three flavours that the synthesis tool maps
differently:

| Type | Synthesises to | Typical use |
|---|---|---|
| Register file (small, multi-port) | flops | RV32I 32×32 regfile |
| Block RAM (medium, 1–2 port) | FPGA BRAM / ASIC SRAM macro | UART/FIFO buffers |
| Distributed RAM (small, FPGA-only) | LUT-RAM | very small lookups |

## Register file pattern

```systemverilog
module regfile_rv32i (
    input  logic        clk,
    input  logic [4:0]  rs1, rs2, rd,
    input  logic [31:0] wd,
    input  logic        we,
    output logic [31:0] rd1, rd2
);
    logic [31:0] x [0:31];
    always_ff @(posedge clk)
        if (we && rd != 5'd0) x[rd] <= wd;
    assign rd1 = (rs1 == 5'd0) ? '0 : x[rs1];
    assign rd2 = (rs2 == 5'd0) ? '0 : x[rs2];
endmodule : regfile_rv32i
```

## BRAM pattern

```systemverilog
// Single-port synchronous read, write-first
module bram_sp #(parameter int W = 8, D = 1024) (
    input  logic               clk,
    input  logic [$clog2(D)-1:0] addr,
    input  logic               we,
    input  logic [W-1:0]       din,
    output logic [W-1:0]       dout
);
    logic [W-1:0] mem [0:D-1];
    always_ff @(posedge clk) begin
        if (we) mem[addr] <= din;
        dout <= mem[addr];        // synchronous read
    end
endmodule : bram_sp
```

## Reading

- Sutherland *SystemVerilog for Design* memory chapter.
- Chu ch.4–6 — FPGA memory inference patterns.

## Cross-links

- `[[sync_fifo]]` — built on top of a 2-port BRAM.
- `[[async_fifo]]`
