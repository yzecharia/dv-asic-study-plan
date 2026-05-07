// Design HW4 — Barrel Shifter TB. Spec: docs/week_04.md (Design HW4).
module barrel_shifter_tb;

    localparam int WIDTH = 8;
    localparam int SHAMT_W = (WIDTH > 1) ? $clog2(WIDTH) : 1;
    localparam int IDX_W = $clog2(2 * WIDTH);

    logic [WIDTH-1:0] d_in, d_out;
    logic [SHAMT_W-1:0] shamt;
    logic [2:0] sh_type;
    int pass_count, fail_count;

    typedef enum logic [2:0] {
        SLL = 3'b000,
        SRL = 3'b001,
        SRA = 3'b010,
        ROL = 3'b011,
        ROR = 3'b100
    } shift_type_e;

    barrel_shifter #(WIDTH) DUT (
        .d_in(d_in),
        .shamt(shamt),
        .sh_type(sh_type),
        .d_out(d_out)
    );


    task drive ();
        for (int i = 0; i < 2**WIDTH; i++) begin
            for (int j = 0; j < 2**SHAMT_W; j++) begin
                for (int k = 0; k < 2**3; k++) begin
                    d_in = i[WIDTH-1:0];
                    shamt = j[SHAMT_W-1:0];
                    sh_type = k[2:0];
                    #5;
                    verify();
                end
            end
        end
    endtask : drive

    function void verify();
        logic [WIDTH-1:0] expected_d_out;
        logic [2*WIDTH-1:0] doubled;
        logic [IDX_W-1:0] shamt_ext;
        logic [IDX_W-1:0] rol_start;

        doubled = {d_in, d_in};
        shamt_ext = IDX_W'(shamt);
        rol_start = IDX_W'(WIDTH) - shamt_ext;

        case (sh_type)
            SLL:     expected_d_out = d_in << shamt;
            SRL:     expected_d_out = d_in >> shamt;
            SRA:     expected_d_out = $signed(d_in) >>> shamt;
            ROL:     expected_d_out = doubled[rol_start +: WIDTH];
            ROR:     expected_d_out = doubled[shamt_ext +: WIDTH];
            default: expected_d_out = '0;
        endcase

        if (d_out !== expected_d_out) begin
            $error("MISMATCH d_in=%h shamt=%0d sh_type=%b expected=%h got=%h",
                   d_in, shamt, sh_type, expected_d_out, d_out);
            fail_count++;
        end else begin
            pass_count++;
        end
    endfunction : verify


    initial begin
        pass_count = 0;
        fail_count = 0;
        d_in = '0;
        shamt = '0;
        sh_type = '0;
        #1;
        drive();
        if (fail_count == 0)
            $display("BARREL_SHIFTER_TB PASS  %0d/%0d", pass_count, pass_count + fail_count);
        else
            $display("BARREL_SHIFTER_TB FAIL  %0d errors out of %0d", fail_count, pass_count + fail_count);
        $finish;
    end


endmodule : barrel_shifter_tb
