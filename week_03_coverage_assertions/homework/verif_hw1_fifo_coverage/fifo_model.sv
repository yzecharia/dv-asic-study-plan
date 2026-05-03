// Verif HW1 — Behavioral FIFO model (DUT for covergroup exercise)
// Spec: docs/week_03.md, HW1

module fifo_model #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
)(
    input  logic             clk, rst_n,
    input  logic             wr_en, rd_en,
    input  logic [WIDTH-1:0] wr_data,
    output logic [WIDTH-1:0] rd_data,
    output logic             full, empty,
    output logic             overflow, underflow,
    output logic [$clog2(DEPTH):0]       data_count
);

    logic [WIDTH-1:0] fifo_mem [DEPTH-1:0];
    logic [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
    logic [$clog2(DEPTH+1)-1:0] counter;

    // TODO: implement behavioral FIFO (not RTL — array + pointers is fine)
    assign data_count = counter;
    assign overflow = (wr_en && full && !rd_en);
    assign underflow = (rd_en && empty);
    assign empty = (counter == '0);
    assign full = (counter == DEPTH);

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            counter <= '0;
            rd_data <= '0;
            wr_ptr <= '0;
            rd_ptr <= '0;
        end else begin
            case({wr_en, rd_en})
                2'b10: begin // write *can only write if not full
                    if (!full) begin
                        fifo_mem[wr_ptr] <= wr_data;
                        counter <= counter + 1;
                        wr_ptr <= wr_ptr + 1;
                    end
                end
                2'b01: begin // read, can only read when not empty
                    if (!empty) begin
                        rd_data <= fifo_mem[rd_ptr];
                        rd_ptr <= rd_ptr + 1;
                        counter <= counter - 1;
                    end
                end
                2'b11: begin // read and write, if empty can only write if full can only read
                    if (empty) begin
                        fifo_mem[wr_ptr] <= wr_data;
                        wr_ptr <= wr_ptr + 1;
                        counter <= counter + 1;
                    end
                    else begin // full or not empty can read and write
                        fifo_mem[wr_ptr] <= wr_data;
                        rd_data <= fifo_mem[rd_ptr];
                        wr_ptr <= wr_ptr + 1;
                        rd_ptr <= rd_ptr + 1;
                    end
                end
            endcase
        end
    end


endmodule
