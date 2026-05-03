//   Copyright 2013 Ray Salemi
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.

module tinyalu (
    input  [7:0]  A,
    input  [7:0]  B,
    input         clk,
    input  [2:0]  op,
    input         reset_n,
    input         start,
    output        done,
    output [15:0] result
);

    wire        done_aax;
    wire        done_mult;
    wire [15:0] result_aax;
    wire [15:0] result_mult;
    reg         start_single;
    reg         start_mult;
    reg  [15:0] result_r;
    reg         done_internal;

    // Start de-mux: route start to single-cycle or multiply block based on op[2]
    always @(*) begin
        case (op[2])
            1'b0: begin
                start_single = start;
                start_mult   = 1'b0;
            end
            1'b1: begin
                start_single = 1'b0;
                start_mult   = start;
            end
            default: begin
                start_single = 1'b0;
                start_mult   = 1'b0;
            end
        endcase
    end

    // Result mux
    always @(*) begin
        case (op[2])
            1'b0:    result_r = result_aax;
            1'b1:    result_r = result_mult;
            default: result_r = 16'bx;
        endcase
    end

    // Done mux
    always @(*) begin
        case (op[2])
            1'b0:    done_internal = done_aax;
            1'b1:    done_internal = done_mult;
            default: done_internal = 1'bx;
        endcase
    end

    assign result = result_r;
    assign done   = done_internal;

    single_cycle add_and_xor (
        .A          (A),
        .B          (B),
        .clk        (clk),
        .op         (op),
        .reset_n    (reset_n),
        .start      (start_single),
        .done_aax   (done_aax),
        .result_aax (result_aax)
    );

    three_cycle mult (
        .A           (A),
        .B           (B),
        .clk         (clk),
        .reset_n     (reset_n),
        .start       (start_mult),
        .done_mult   (done_mult),
        .result_mult (result_mult)
    );

endmodule
