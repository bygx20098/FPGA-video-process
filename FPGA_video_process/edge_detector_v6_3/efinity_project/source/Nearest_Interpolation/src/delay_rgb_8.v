module delay_rgb_8
(
    input  wire                 clk         ,
    input  wire                 rst_n           ,
    
    //  Image data prepared to be processed
    input  wire     [7:0]       before_img_red    ,                       //  Prepared Image data vsync valid signal
    input  wire     [7:0]       before_img_green    ,                       //  Prepared Image data href vaild  signal
    input  wire     [7:0]       before_img_blue    ,                       //  Prepared Image brightness input
    
    //  Image data has been processed
    output wire     [7:0]       after_img_red     ,                     //  processed Image data vsync valid signal
    output wire     [7:0]       after_img_green   ,                      //  processed Image data href vaild  signal
    output wire     [7:0]       after_img_blue                              //  processed Image brightness output
);



reg     [7:0]      img_red_c1;  
reg     [7:0]      img_green_c1;
reg     [7:0]      img_blue_c1;

reg     [7:0]      img_red_c2;  
reg     [7:0]      img_green_c2;
reg     [7:0]      img_blue_c2;

reg     [7:0]      img_red_c3;  
reg     [7:0]      img_green_c3;
reg     [7:0]      img_blue_c3;

reg     [7:0]      img_red_c4;  
reg     [7:0]      img_green_c4;
reg     [7:0]      img_blue_c4;

reg     [7:0]      img_red_c5;  
reg     [7:0]      img_green_c5;
reg     [7:0]      img_blue_c5;

reg     [7:0]      img_red_c6;  
reg     [7:0]      img_green_c6;
reg     [7:0]      img_blue_c6;

reg     [7:0]      img_red_c7;  
reg     [7:0]      img_green_c7;
reg     [7:0]      img_blue_c7;

reg     [7:0]      img_red_c8;  
reg     [7:0]      img_green_c8;
reg     [7:0]      img_blue_c8;




always @( posedge clk )
begin
if(rst_n == 1'b0)
    begin
        img_red_c1   <=  8'd0;
        img_green_c1 <=  8'd0;
        img_blue_c1  <=  8'd0;
    end
else
    begin
        img_red_c1    <=    before_img_red  ;
        img_green_c1  <=    before_img_green;
        img_blue_c1   <=    before_img_blue ;
    end
end 

always @( posedge clk )
begin
if(rst_n == 1'b0)
    begin
        img_red_c2    <=  8'd0;
        img_green_c2  <=  8'd0;
        img_blue_c2   <=  8'd0;
    end
else
    begin
        img_red_c2    <=    img_red_c1  ;
        img_green_c2  <=    img_green_c1;
        img_blue_c2   <=    img_blue_c1 ;
    end
end 


always @( posedge clk )
begin
if(rst_n == 1'b0)
    begin
        img_red_c3    <=  8'd0;
        img_green_c3  <=  8'd0;
        img_blue_c3   <=  8'd0;
    end
else
    begin
        img_red_c3    <=    img_red_c2   ;
        img_green_c3  <=    img_green_c2 ;
        img_blue_c3   <=    img_blue_c2  ;
    end
end 



always @( posedge clk )
begin
if(rst_n == 1'b0)
    begin
        img_red_c4    <=  8'd0;
        img_green_c4  <=  8'd0;
        img_blue_c4   <=  8'd0;
    end
else
    begin
        img_red_c4    <=    img_red_c3  ;
        img_green_c4  <=    img_green_c3;
        img_blue_c4   <=    img_blue_c3 ;
    end
end 


always @( posedge clk )
begin
if(rst_n == 1'b0)
    begin
        img_red_c5   <=  8'd0;
        img_green_c5 <=  8'd0;
        img_blue_c5  <=  8'd0;
    end
else
    begin
        img_red_c5    <=    img_red_c4  ;
        img_green_c5  <=    img_green_c4;
        img_blue_c5   <=    img_blue_c4 ;
    end
end 


 always @( posedge clk )
 begin
 if(rst_n == 1'b0)
     begin
         img_red_c6    <=  8'd0;
         img_green_c6  <=  8'd0;
         img_blue_c6   <=  8'd0;
     end
 else
     begin
         img_red_c6    <=    img_red_c5  ;
         img_green_c6  <=    img_green_c5;
         img_blue_c6   <=    img_blue_c5 ;
     end
 end 


// always @( posedge clk )
// begin
// if(rst_n == 1'b0)
//     begin
//         img_red_c7    <=  8'd0;
//         img_green_c7  <=  8'd0;
//         img_blue_c7   <=  8'd0;
//     end
// else
//     begin
//         img_red_c7    <=    img_red_c6  ;
//         img_green_c7  <=    img_green_c6;
//         img_blue_c7   <=    img_blue_c6 ;
//     end
// end 


// always @( posedge clk )
// begin
// if(rst_n == 1'b0)
//     begin
//         img_red_c8    <=  8'd0;
//         img_green_c8  <=  8'd0;
//         img_blue_c8   <=  8'd0;
//     end
// else
//     begin
//         img_red_c8    <=    img_red_c7  ;
//         img_green_c8  <=    img_green_c7;
//         img_blue_c8   <=    img_blue_c7 ;
//     end
// end 


assign  after_img_red    = img_red_c6  ;
assign  after_img_green  = img_green_c6;
assign  after_img_blue   = img_blue_c6 ;



endmodule