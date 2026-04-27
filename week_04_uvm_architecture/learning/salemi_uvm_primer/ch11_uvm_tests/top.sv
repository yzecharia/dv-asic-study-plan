/*
   Copyright 2013 Ray Salemi

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
module top;
   import uvm_pkg::*;
`include "uvm_macros.svh"

   import   tinyalu_pkg::*;
`include "tinyalu_macros.svh"

   tinyalu_bfm       bfm();
   tinyalu DUT (.A(bfm.A), .B(bfm.B), .op(bfm.op), 
                .clk(bfm.clk), .reset_n(bfm.reset_n), 
                .start(bfm.start), .done(bfm.done), .result(bfm.result));

initial begin
   //1. storing the bfm in a global location
   /*
      ::set(0, 1, 2, 3)
      0,1 : tell set to make the data availiable across the entire testbench
      2 : a name for the data stored in the data base
      3 : the data to be stored (in this case a handle to tinyalu_bfm)
   */
  uvm_config_db #(virtual tinyalu_bfm)::set(null, "*", "bfm", bfm);
  //2. Once stored the bfm in global location, can start the test
  run_test(); // Can accept a string name of the test, but this beats the whole purpose
end

endmodule : top

     
   