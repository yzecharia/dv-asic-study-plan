  interface alu_if (input logic clk, rst_n);
      localparam int WIDTH = 8;
                                                                                                                                      
      logic [WIDTH-1:0] operand_a, operand_b;                                                                                         
      logic [2:0] operation;                                                                                                    
      logic valid_in;                                                                                                     
      logic [WIDTH:0] result;                
      logic valid_out;             
                                                                                                                                      
      clocking driver_cb @(posedge clk);
          default input #1step output #1;                                                                                             
          output operand_a, operand_b, operation, valid_in;
          input  result, valid_out;                                                                                                   
      endclocking
                                                                                                                                      
      clocking monitor_cb @(posedge clk);
          default input #1step;                
          input  operand_a, operand_b, operation, valid_in, result, valid_out;
      endclocking                                                                                                                     
  
      modport dut (                                                                                                                   
          input  clk, rst_n, operand_a, operand_b, operation, valid_in,
          output result, valid_out                                                                                                    
      );
                                                                                                                                      
      modport tb (clocking driver_cb,  input clk, rst_n);                                                                        
      modport monitor (clocking monitor_cb, input clk, rst_n);
                                                                                                                                      
  endinterface : alu_if 