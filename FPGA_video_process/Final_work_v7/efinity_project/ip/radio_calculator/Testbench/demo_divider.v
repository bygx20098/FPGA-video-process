
`timescale 1ns / 1ps

module demo_divider (
    output wire pll_rst_n_o,
    output wire pass_led,
    output wire fail_led,
    
    input       clk,
    input       clken,
    input       reset
);

`include "radio_calculator_define.vh"

genvar i;
reg [3:0] count;
reg [LATENCY:0] clken_reg;
reg pass, fail;

assign pass_led = pass;
assign fail_led = fail;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        clken_reg[0] <= 1'b0;
    end
    else begin
        clken_reg[0] <= clken;
    end
end

generate
for (i=0; i<LATENCY; i=i+1) begin
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            clken_reg[i+1]    <= 1'b0;
        end
        else begin
            clken_reg[i+1]    <= clken_reg[i];
        end
    end
end

if (NREPRESENTATION == "SIGNED" &&  DREPRESENTATION == "SIGNED") begin
    reg signed [WIDTHN-1:0] numer;
    reg signed [WIDTHD-1:0] denom;
    wire signed [WIDTHN-1:0] quotient;
    wire signed [WIDTHD-1:0] remain;
    reg signed [WIDTHN-1:0] golden_quotient [LATENCY:0];
    reg [WIDTHD-1:0] golden_remain [LATENCY:0];  //the core only support unsigned remain
    wire [WIDTHD-1:0] unsigned_golden_remain;
    
    always @* begin
        golden_quotient[0] = numer/denom;
        golden_remain[0] = numer%denom;
    end
    
    for (i=0; i<LATENCY; i=i+1) begin
        always @(posedge clk or posedge reset) begin
            if (reset) begin
                golden_quotient[i+1]  <= {WIDTHN{1'b0}};
                golden_remain[i+1]    <= {WIDTHD{1'b0}};
            end
            else if(clken) begin
                golden_quotient[i+1]  <= golden_quotient[i];
                golden_remain[i+1]    <= golden_remain[i];
            end
        end
        
        always @(posedge clk or posedge reset) begin
            if (reset) begin
                clken_reg[i+1]    <= 1'b0;
            end
            else begin
                clken_reg[i+1]    <= clken_reg[i];
            end
        end
    end
    
    assign unsigned_golden_remain = golden_remain[LATENCY][WIDTHD-1] ? (~golden_remain[LATENCY] + 1) : golden_remain[LATENCY];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pass         <= 1'b0;
            fail         <= 1'b0;
        end
        else if (clken_reg[LATENCY]) begin
            if (golden_quotient[LATENCY] === quotient && unsigned_golden_remain === remain) begin
                $display("Correct quotient received, %d", quotient);
                $display("Correct remain received, %d", remain);
                pass    <= 1'b1;
            end
            else begin
                pass    <= 1'b0;
            end
            
            if (golden_quotient[LATENCY] !== quotient) begin
                $display("ERROR - Wrong quotient received, %d. Expecting %d", quotient, golden_quotient[LATENCY]);
                fail    <= 1'b1;
            end
            
            if (unsigned_golden_remain !== remain) begin
                $display("ERROR - Wrong remain received, %d. Expecting %d", remain, unsigned_golden_remain);
                fail    <= 1'b1;
            end
        end
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
           count <= 0;
           numer <= 1;
           denom <= 1;
        end
        else begin
           if(clken) begin
              count <= count + 1'b1;
              if (count == 0) begin
                  numer <= 8;
                  denom <= -3;
              end 
          `ifdef SIM_MODE
              else if (count == 1)  begin
                  numer <=  15;
                  denom <=  4;
              end 
              else if (count == 2)  begin
                  numer <=  -13;
                  denom <=  3;
              end 
              else if (count == 3) begin
                  numer <=  -10;
                  denom <=  5;
              end
              else if (count == 4) begin
                  numer <= {WIDTHN{1'b1}};
                  denom <= -3;
              end 
              else if (count == 5)  begin
                  numer <=  15;
                  denom <=  {WIDTHD{1'b1}};
              end 
              else if (count == 6)  begin
                  numer <= {WIDTHN{1'b1}};
                  denom <= {{WIDTHD/2{1'b0}}, {WIDTHD/2{1'b1}}};
              end 
              else if (count == 7) begin
                  numer <=  {{WIDTHN/2{1'b0}}, {WIDTHN/2{1'b1}}};
                  denom <=  {WIDTHD{1'b1}};
              end
              else if (count == 8) begin
                  numer <= -16;
                  denom <= -3;
              end 
              else if (count == 9)  begin
                  numer <=  9;
                  denom <=  4;
              end 
              else if (count == 10)  begin
                  numer <=  -13;
                  denom <=  12;
              end 
              else if (count == 11) begin
                  numer <=  -10;
                  denom <=  -5;
              end
              else if (count == 12) begin
                  numer <=  {{WIDTHN/2{1'b1}}, {WIDTHN/2{1'b0}}};
                  denom <=  {WIDTHD{1'b1}};
              end 
              else if (count == 13)  begin
                  numer <=  {WIDTHN{1'b1}};
                  denom <=  {{WIDTHD/2{1'b1}}, {WIDTHD/2{1'b0}}};
              end 
              else if (count == 14)  begin
                  numer <= {1'b0, {(WIDTHN-1){1'b1}}};
                  denom <= {1'b0, {(WIDTHD/2)-1{1'b1}}, {WIDTHD/2{1'b0}}};
              end 
              else if (count == 15) begin
                  numer <=  {1'b0, {(WIDTHN/2)-1{1'b1}}, {WIDTHN/2{1'b0}}};
                  denom <=  {1'b0, {(WIDTHD-1){1'b1}}};
              end
          `endif
              else begin
                  numer <= 1;
                  denom <= 1; 
              end
           end
        end
    end
    
    ///////////////////
    // Module Instantiation
    ///////////////////
    radio_calculator  dut_inst (
        //Output
        .quotient(quotient),
        .remain  (remain),
        //Input
        .numer   (numer),
        .denom   (denom),
        .clk     (clk),
        .reset   (reset),
        .clken   (clken)
    );
end
else if (NREPRESENTATION == "UNSIGNED" &&  DREPRESENTATION == "UNSIGNED") begin
    reg [WIDTHN-1:0] numer;
    reg [WIDTHD-1:0] denom;
    wire [WIDTHN-1:0] quotient;
    wire [WIDTHD-1:0] remain;
    reg [WIDTHN-1:0] golden_quotient [LATENCY:0];
    reg [WIDTHD-1:0] golden_remain [LATENCY:0];  //the core only support unsigned remain
    wire [WIDTHD-1:0] unsigned_golden_remain;
    
    always @* begin
        golden_quotient[0] = numer/denom;
        golden_remain[0] = numer%denom;
    end
    
    for (i=0; i<LATENCY; i=i+1) begin
        always @(posedge clk or posedge reset) begin
            if (reset) begin
                golden_quotient[i+1]  <= {WIDTHN{1'b0}};
                golden_remain[i+1]    <= {WIDTHD{1'b0}};
            end
            else if(clken) begin
                golden_quotient[i+1]  <= golden_quotient[i];
                golden_remain[i+1]    <= golden_remain[i];
            end
        end
        
        always @(posedge clk or posedge reset) begin
            if (reset) begin
                clken_reg[i+1]    <= 1'b0;
            end
            else begin
                clken_reg[i+1]    <= clken_reg[i];
            end
        end
    end
    
    assign unsigned_golden_remain = golden_remain[LATENCY];
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pass         <= 1'b0;
            fail         <= 1'b0;
        end
        else if (clken_reg[LATENCY]) begin
            if (golden_quotient[LATENCY] === quotient && unsigned_golden_remain === remain) begin
                $display("Correct quotient received, %d", quotient);
                $display("Correct remain received, %d", remain);
                pass    <= 1'b1;
            end
            else begin
                pass    <= 1'b0;
            end
            
            if (golden_quotient[LATENCY] !== quotient) begin
                $display("ERROR - Wrong quotient received, %d. Expecting %d", quotient, golden_quotient[LATENCY]);
                fail    <= 1'b1;
            end
            
            if (unsigned_golden_remain !== remain) begin
                $display("ERROR - Wrong remain received, %d. Expecting %d", remain, unsigned_golden_remain);
                fail    <= 1'b1;
            end
        end
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
           count <= 0;
           numer <= 1;
           denom <= 1;
        end
        else begin
           if(clken) begin
              count <= count + 1'b1;
              if (count == 0) begin
                  numer <= 8;
                  denom <= 3;
              end 
          `ifdef SIM_MODE
              else if (count == 1)  begin
                  numer <=  15;
                  denom <=  4;
              end 
              else if (count == 2)  begin
                  numer <=  13;
                  denom <=  3;
              end 
              else if (count == 3) begin
                  numer <=  10;
                  denom <=  5;
              end
              else if (count == 4) begin
                  numer <= {WIDTHN{1'b1}};
                  denom <= 3;
              end 
              else if (count == 5)  begin
                  numer <=  15;
                  denom <=  {WIDTHD{1'b1}};
              end 
              else if (count == 6)  begin
                  numer <= {WIDTHN{1'b1}};
                  denom <= {{WIDTHD/2{1'b0}}, {WIDTHD/2{1'b1}}};
              end 
              else if (count == 7) begin
                  numer <=  {{WIDTHN/2{1'b0}}, {WIDTHN/2{1'b1}}};
                  denom <=  {WIDTHD{1'b1}};
              end
              else if (count == 8) begin
                  numer <= 16;
                  denom <= 3;
              end 
              else if (count == 9)  begin
                  numer <=  9;
                  denom <=  4;
              end 
              else if (count == 10)  begin
                  numer <=  13;
                  denom <=  12;
              end 
              else if (count == 11) begin
                  numer <=  10;
                  denom <=  5;
              end
              else if (count == 12) begin
                  numer <=  {{WIDTHN/2{1'b1}}, {WIDTHN/2{1'b0}}};
                  denom <=  {WIDTHD{1'b1}};
              end 
              else if (count == 13)  begin
                  numer <=  {WIDTHN{1'b1}};
                  denom <=  {{WIDTHD/2{1'b1}}, {WIDTHD/2{1'b0}}};
              end 
              else if (count == 14)  begin
                  numer <= {1'b0, {(WIDTHN-1){1'b1}}};
                  denom <= {1'b0, {(WIDTHD/2)-1{1'b1}}, {WIDTHD/2{1'b0}}};
              end 
              else if (count == 15) begin
                  numer <=  {1'b0, {(WIDTHN/2)-1{1'b1}}, {WIDTHN/2{1'b0}}};
                  denom <=  {1'b0, {(WIDTHD-1){1'b1}}};
              end
          `endif
              else begin
                  numer <= 0;
                  denom <= 0; 
              end
           end
        end
    end
    
    ///////////////////
    // Module Instantiation
    ///////////////////
    radio_calculator  dut_inst (
        //Output
        .quotient(quotient),
        .remain  (remain),
        //Input
        .numer   (numer),
        .denom   (denom),
        .clk     (clk),
        .reset   (reset),
        .clken   (clken)
    );
end
endgenerate

endmodule