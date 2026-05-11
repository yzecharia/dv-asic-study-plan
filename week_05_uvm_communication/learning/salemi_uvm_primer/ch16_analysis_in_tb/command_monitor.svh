class command_monitor extends uvm_component;
    `uvm_component_utils(command_monitor)

    /*
    typedef struct {
      byte unsigned        A;
      byte unsigned        B;
      operation_t op;
   } command_s;
    */
    uvm_analysis_port #(command_s) ap;


    function void build_phase (uvm_phase phase);
        virtual tinyalu_bfm bfm;

        if (!uvm_config_db #(virtaul tinyalu_bfm)::get(null, "*", "bfm", bfm))
            $fatal("Failed to get BFM");

        bfm.command_monitor_h = this;

        ap = new("ap", this);
    endfunction : build_phase

    function void write_to_monitor(byte A, byte B, bit[2:0] op);
        command_s cmd;
        cmd.A = A;
        cmd.B = B;
        cmd.op = op2enum(op);
        $display("COMMAND MONITOR: A:0x%2h B:0x%2h op: %s", A, B, cmd.op.name());
        ap.write(cmd);
    endfunction : write_to_monitor


   function operation_t op2enum(bit[2:0] op);
      case(op)
        3'b000 : return no_op;
        3'b001 : return add_op;
        3'b010 : return and_op;
        3'b011 : return xor_op;
        3'b100 : return mul_op;
        3'b111 : return rst_op;
        default : $fatal($sformatf("Illegal operation on op bus: %3b",op));
      endcase // case (op)
   endfunction : op2enum

   function new (string name, uvm_component parent);
      super.new(name,parent);
   endfunction
endclass : command_monitor