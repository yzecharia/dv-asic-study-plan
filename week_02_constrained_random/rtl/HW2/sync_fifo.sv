module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 8
) (
    input logic clk, rst_n, 
    input logic wr_en, rd_en,
    input logic [DATA_WIDTH-1:0] wr_data,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic full, empty,
    output logic [$clog2(DEPTH):0] count
);

// Circular buffer with read righ pointers

    logic [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
    logic [DATA_WIDTH-1:0] mem [DEPTH-1:0];

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            rd_data <= '0;
            count <= '0;
            wr_ptr <= '0;
            rd_ptr <= '0;
        end else begin
            case({wr_en, rd_en}) 
                2'b10: begin // Write
                    if (!full) begin
                        mem[wr_ptr] <= wr_data;
                        wr_ptr <= wr_ptr + 1'd1;
                        count <= count + 1'd1;
                    end
                end
                2'b01: begin // Read
                    if (!empty) begin
                        rd_data <= mem[rd_ptr];
                        rd_ptr <= rd_ptr + 1'd1;
                        count <= count - 1'd1;
                    end
                end
                2'b11: begin // Read and Write
                    if (empty) begin // Can write but not read
                        mem[wr_ptr] <= wr_data;
                        wr_ptr <= wr_ptr + 1'd1;
                        count <= count + 1'd1;
                    end else if (full) begin // can read but not write
                        rd_data <= mem[rd_ptr];
                        rd_ptr <= rd_ptr + 1'd1;
                        count <= count - 1'd1;
                    end else begin
                        mem[wr_ptr] <= wr_data;
                        rd_data  <= mem[rd_ptr];
                        wr_ptr <= wr_ptr + 1'd1;
                        rd_ptr <= rd_ptr + 1'd1;
                    end
                end
            endcase
        end
    end

    assign empty = (count == '0);
    assign full = (count == DEPTH);

    
endmodule