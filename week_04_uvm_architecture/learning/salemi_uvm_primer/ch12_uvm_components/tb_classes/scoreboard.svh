class scoreboard extends uvm_component;
   `uvm_component_utils(scoreboard);

   virtual tinyalu_bfm bfm;

   function new (string name, uvm_component parent);
      super.new(name, parent);
   endfunction : new

   function void build_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual tinyalu_bfm)::get(null, *, "bfm", bfm))
         $fatal("Failed to get BFM");
   endfunction : build_phase

   task run_phase(uvm_phase phase);
      shortint predicted_result;
      forever begin : self_checker
         @(posedge bfm.done) #1;
         case (bfm.op_set)
            add_op: predicted_result = bfm.A + bfm.B;
            and_op: predicted_result = bfm.A & bfm.B;
            xor_op: predicted_result = bfm.A ^ bfm.B;
            mul_op: predicted_result = bfm.A * bfm.B;
         endcase

         if ((bfm.op_set != no_op) && (bfm.op_set != rst_op))
            if (predicted_result != bfm.result)
               $error ("FAILED: A: %0h  B: %0h  op: %s  result: %0h",
                        bfm.A, bfm.B, bfm.op_set.name(), bfm.result);
      end : self_checker
   endtask : run_phase

endclass : scoreboard