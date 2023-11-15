`resetall
`timescale 1ns / 1ps
`define FINISHTIME 150000
`define CLK_PERIOD 50
//`include "divider_default.v"
  
  module tb_divider;
   //Parameter
  `include "radio_calculator_define.vh"
   //Output
   wire pll_rst_n_o;
   wire pass_led;
   wire fail_led;
   //Input	
   reg clk;
   reg reset;
   reg clken;
   

///////////////////
// Module Instantiation
///////////////////

   //DUT
    demo_divider  demo_inst (
        //Output
        .pll_rst_n_o (pll_rst_n_o),
        .pass_led (pass_led),
        .fail_led (fail_led),
        //Input
        .clk   (clk),
        .reset (reset),
        .clken (clken)
    );
   

///////////////////
// Test begin
///////////////////
   
   //assign quotient_c = (8) / (4);
   //assign remain_c =  (8) % (4);
   
   /*initial
     begin
	//$shm_open("tb_divider.shm");
	//$shm_probe(tb_divider,"ACMTF");
	//$dumpfile("tb_divider.vcd");
	//$dumpvars(0, tb_divider);
     end*/

   //Generate test pattern
   initial begin
      clk = 0;
      forever begin
	 #(`CLK_PERIOD/2) clk = ~clk;
      end
    end
    
        
     initial
      begin
      	  reset <= 1'b1;
	      clken <= 1'b0;
	      #500;
	      reset <= 1'b0;
	      #275;
	      clken <= 1'b1;
	      #19500;
	      clken <= 1'b0;
	      #20800;
	      clken <= 1'b1;
	      #21900;
	      clken <= 1'b0;
	      #21750;
	      clken <= 1'b1;
	      #23850;
	      clken <= 1'b0;
	      #29800;
	      clken <= 1'b1;
      end
      
      initial begin
      #(`FINISHTIME);

      if(demo_inst.pass == 1 && demo_inst.fail == 0) $display($time," ns---PASSED---");
      else $display($time," ns---FAILED---"); 
      
      $finish;
      end
   
endmodule
