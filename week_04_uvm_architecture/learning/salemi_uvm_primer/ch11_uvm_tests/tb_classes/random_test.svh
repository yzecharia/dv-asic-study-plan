class random_test extends uvm_test;
   `uvm_component_utils(random_test);
   /*
      In order to extend uvm_component we need to follow strict rules when we write the mandatory new() method:
         • The constructor must have two arguments called name and parent that are defined in that order: name is the first argument, parent is the second argument.
         • The name argument must be of typestring. The parent argument must be of type uvm_component.
         • The constructor's first executable line must call super.new(name, parent). The UVM will only work properly if you make this call.
   */
   virtual tinyalu_bfm bfm;
   
   function new (string name, uvm_component parent);
      super.new(name,parent);
      if(!uvm_config_db #(virtual tinyalu_bfm)::get(null, "*","bfm", bfm))
        $fatal("Failed to get BFM");
   endfunction : new


   task run_phase(uvm_phase phase);
      random_tester    random_tester_h;
      coverage  coverage_h;
      scoreboard scoreboard_h;

      phase.raise_objection(this);

      random_tester_h    = new(bfm);
      coverage_h  = new(bfm);
      scoreboard_h = new(bfm);
      
      fork
         coverage_h.execute();
         scoreboard_h.execute();
      join_none

      random_tester_h.execute();
      phase.drop_objection(this);
   endtask : run_phase

endclass