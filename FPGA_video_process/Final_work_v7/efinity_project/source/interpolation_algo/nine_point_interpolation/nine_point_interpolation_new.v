// *********************************************************************
// 
// Copyright (C) 2021-20xx CrazyBird Corporation
// 
// Filename     :   bilinear_interpolation.v
// Author       :   CrazyBird
// Email        :   CrazyBirdLin@qq.com
// 
// Description  :   
// 
// Modification History
// Date         By          Version         Change Description
//----------------------------------------------------------------------
// 2021/03/27   CrazyBird   1.0             Original
// 
// *********************************************************************
module nine_point_interpolation
(
    input  wire     [10:0]      c_src_img_width ,
    input  wire     [10:0]      c_src_img_height,
    input  wire     [10:0]      c_dst_img_width ,
    input  wire     [10:0]      c_dst_img_height,
    input  wire     [16:0]      c_x_radio       ,
    input  wire     [16:0]      c_y_radio       ,
    
    input  wire                 clk_in1         ,
    input  wire                 clk_in2         ,
    input  wire                 rst_n           ,
    
    //  Image data prepared to be processed
    input  wire                 per_img_vsync   ,       //  Prepared Image data vsync valid signal
    input  wire                 per_img_de      ,       //  Prepared Image data href vaild  signal
    input  wire     [7:0]       per_img_red     ,       //  Prepared Image brightness input
    input  wire     [7:0]       per_img_green   ,
    input  wire     [7:0]       per_img_blue    ,
    
    //  Image data has been processed
    output reg                  post_img_vsync  ,       //  processed Image data vsync valid signal
    output reg                  post_img_de     ,       //  processed Image data href vaild  signal
    output reg      [7:0]       post_img_red    ,        //  processed Image brightness output
    output reg      [7:0]       post_img_green  ,
    output reg      [7:0]       post_img_blue   ,
    
    input  wire     [ 7:0]      red_even_bram1_b_rdata  ,
    input  wire     [ 7:0]      red_odd_bram1_b_rdata   ,
    input  wire     [ 7:0]      red_even_bram2_b_rdata  ,
    input  wire     [ 7:0]      red_odd_bram2_b_rdata   , 


    input  wire     [ 7:0]      green_even_bram1_b_rdata,
    input  wire     [ 7:0]      green_odd_bram1_b_rdata ,
    input  wire     [ 7:0]      green_even_bram2_b_rdata,
    input  wire     [ 7:0]      green_odd_bram2_b_rdata ,


    input  wire     [ 7:0]      blue_even_bram1_b_rdata ,
    input  wire     [ 7:0]      blue_odd_bram1_b_rdata  ,
    input  wire     [ 7:0]      blue_even_bram2_b_rdata ,
    input  wire     [ 7:0]      blue_odd_bram2_b_rdata

);
//----------------------------------------------------------------------
reg                             per_img_de_dly;

always @(posedge clk_in1)
begin
    if(rst_n == 1'b0)
        per_img_de_dly <= 1'b0;
    else
        per_img_de_dly <= per_img_de;
end

wire                            per_img_de_neg;

assign per_img_de_neg = per_img_de_dly & ~per_img_de;

reg             [10:0]          img_vs_cnt;                             //  from 0 to c_src_img_height - 1

always @(posedge clk_in1)
begin
    if(rst_n == 1'b0)
        img_vs_cnt <= 11'b0;
    else
    begin
        if(per_img_vsync == 1'b0)
            img_vs_cnt <= 11'b0;
        else
        begin
            if(per_img_de_neg == 1'b1)
                img_vs_cnt <= img_vs_cnt + 1'b1;
            else
                img_vs_cnt <= img_vs_cnt;
        end
    end
end

reg             [10:0]          img_hs_cnt;                             //  from 0 to c_src_img_width - 1

always @(posedge clk_in1)
begin
    if(rst_n == 1'b0)
        img_hs_cnt <= 11'b0;
    else
    begin
        if((per_img_vsync == 1'b1)&&(per_img_de == 1'b1))
            img_hs_cnt <= img_hs_cnt + 1'b1;
        else
            img_hs_cnt <= 11'b0;
    end
end

//----------------------------------------------------------------------
reg             [7:0]           bram_a_wdata;
reg             [7:0]           green_bram_a_wdata;
reg             [7:0]           blue_bram_a_wdata;

always @(posedge clk_in1)
begin
    bram_a_wdata <= per_img_red;
    green_bram_a_wdata <= per_img_green;
    blue_bram_a_wdata <= per_img_blue;

end

reg             [11:0]          bram_a_waddr;

always @(posedge clk_in1)
begin
    bram_a_waddr <= {img_vs_cnt[2:1],10'b0} + img_hs_cnt;
end

reg                             bram1_a_wenb;

always @(posedge clk_in1)
begin
    if(rst_n == 1'b0)
        bram1_a_wenb <= 1'b0;
    else
        bram1_a_wenb <= per_img_vsync & per_img_de & ~img_vs_cnt[0];
end

reg                             bram2_a_wenb;

always @(posedge clk_in1)
begin
    if(rst_n == 1'b0)
        bram2_a_wenb <= 1'b0;
    else
        bram2_a_wenb <= per_img_vsync & per_img_de & img_vs_cnt[0];
end

reg             [10:0]          fifo_wdata;

always @(posedge clk_in1)
begin
    fifo_wdata <= img_vs_cnt;
end

reg                             fifo_wenb;

always @(posedge clk_in1)
begin
    if(rst_n == 1'b0)
        fifo_wenb <= 1'b0;
    else
    begin
        if((per_img_vsync == 1'b1)&&(per_img_de == 1'b1)&&(img_hs_cnt == c_src_img_width - 1'b1))
            fifo_wenb <= 1'b1;
        else
            fifo_wenb <= 1'b0;
    end
end

//----------------------------------------------------------------------
//  bram & fifo rw
reg             [11:0]          even_bram1_b_raddr;
reg             [11:0]          odd_bram1_b_raddr;
reg             [11:0]          even_bram2_b_raddr;
reg             [11:0]          odd_bram2_b_raddr;

/*

bram_asymmetric_r2_w1_port
#(
        .C_ADDR_WIDTH  (12) ,
        .C_DATA_WIDTH  (8) 
)
red_bram_asymmetric_r2_w1_port_inst1
(
.wclk   (clk_in1) ,
.wen    (bram1_a_wenb) ,
.waddr  (bram_a_waddr) ,
.wdata  (bram_a_wdata) ,

.rclk   (clk_in2) ,
.raddr1 (even_bram1_b_raddr) ,
.rdata1 (red_even_bram1_b_rdata) ,
.raddr2 (odd_bram1_b_raddr) ,
.rdata2 (red_odd_bram1_b_rdata) 
);



bram_asymmetric_r2_w1_port
#(
        .C_ADDR_WIDTH  (12) ,
        .C_DATA_WIDTH  (8) 
)
red_bram_asymmetric_r2_w1_port_inst2
(
.wclk   (clk_in1) ,
.wen    (bram2_a_wenb) ,
.waddr  (bram_a_waddr) ,
.wdata  (bram_a_wdata) ,

.rclk   (clk_in2) ,
.raddr1 (even_bram2_b_raddr) ,
.rdata1 (red_even_bram2_b_rdata) ,
.raddr2 (odd_bram2_b_raddr) ,
.rdata2 (red_odd_bram2_b_rdata) 
);


bram_asymmetric_r2_w1_port
#(
        .C_ADDR_WIDTH  (12) ,
        .C_DATA_WIDTH  (8) 
)
green_bram_asymmetric_r2_w1_port_inst1
(
.wclk   (clk_in1) ,
.wen    (bram1_a_wenb) ,
.waddr  (bram_a_waddr) ,
.wdata  (green_bram_a_wdata) ,

.rclk   (clk_in2) ,
.raddr1 (even_bram1_b_raddr) ,
.rdata1 (green_even_bram1_b_rdata) ,
.raddr2 (odd_bram1_b_raddr) ,
.rdata2 (green_odd_bram1_b_rdata) 
);

bram_asymmetric_r2_w1_port
#(
        .C_ADDR_WIDTH  (12) ,
        .C_DATA_WIDTH  (8) 
)
green_bram_asymmetric_r2_w1_port_inst2
(
.wclk   (clk_in1) ,
.wen    (bram2_a_wenb) ,
.waddr  (bram_a_waddr) ,
.wdata  (green_bram_a_wdata) ,

.rclk   (clk_in2) ,
.raddr1 (even_bram2_b_raddr) ,
.rdata1 (green_even_bram2_b_rdata) ,
.raddr2 (odd_bram2_b_raddr) ,
.rdata2 (green_odd_bram2_b_rdata) 
);



bram_asymmetric_r2_w1_port
#(
        .C_ADDR_WIDTH  (12) ,
        .C_DATA_WIDTH  (8) 
)
blue_bram_asymmetric_r2_w1_port_inst1
(
.wclk   (clk_in1) ,
.wen    (bram1_a_wenb) ,
.waddr  (bram_a_waddr) ,
.wdata  (blue_bram_a_wdata) ,

.rclk   (clk_in2) ,
.raddr1 (even_bram1_b_raddr) ,
.rdata1 (blue_even_bram1_b_rdata) ,
.raddr2 (odd_bram1_b_raddr) ,
.rdata2 (blue_odd_bram1_b_rdata) 
);



bram_asymmetric_r2_w1_port
#(
        .C_ADDR_WIDTH  (12) ,
        .C_DATA_WIDTH  (8) 
)
blue_bram_asymmetric_r2_w1_port_inst2
(
.wclk   (clk_in1) ,
.wen    (bram2_a_wenb) ,
.waddr  (bram_a_waddr) ,
.wdata  (blue_bram_a_wdata) ,

.rclk   (clk_in2) ,
.raddr1 (even_bram2_b_raddr) ,
.rdata1 (blue_even_bram2_b_rdata) ,
.raddr2 (odd_bram2_b_raddr) ,
.rdata2 (blue_odd_bram2_b_rdata) 
);

wire                            fifo_renb;
wire            [10:0]          fifo_rdata;
wire                            fifo_empty;
wire                            fifo_full;

*/

asyn_fifo
#(
    .C_DATA_WIDTH       (11),
    .C_FIFO_DEPTH_WIDTH (4 )
)
u_tag_fifo
(
    .wr_rst_n   (rst_n      ),
    .wr_clk     (clk_in1    ),
    .wr_en      (fifo_wenb  ),
    .wr_data    (fifo_wdata ),
    .wr_full    (fifo_full  ),
    .wr_cnt     (           ),
    .rd_rst_n   (rst_n      ),
    .rd_clk     (clk_in2    ),
    .rd_en      (fifo_renb  ),
    .rd_data    (fifo_rdata ),
    .rd_empty   (fifo_empty ),
    .rd_cnt     (           )
);

localparam S_IDLE      = 3'd0;
localparam S_Y_LOAD    = 3'd1;
localparam S_BRAM_ADDR = 3'd2;
localparam S_Y_INC     = 3'd3;
localparam S_RD_FIFO   = 3'd4;

reg             [ 2:0]          state;
reg             [26:0]          y_dec;
reg             [26:0]          x_dec;
reg             [10:0]          y_cnt;
reg             [10:0]          x_cnt;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
        state <= S_IDLE;
    else
    begin
        case(state)
            S_IDLE : 
            begin
                if(fifo_empty == 1'b0)
                begin
                    if((fifo_rdata != 11'b0)&&(y_cnt == c_dst_img_height))
                        state <= S_RD_FIFO;
                    else
                        state <= S_Y_LOAD;
                end
                else
                    state <= S_IDLE;
            end
            S_Y_LOAD : 
            begin
                if((y_dec[26:16] + 1'b1 <= fifo_rdata)||(y_cnt == c_dst_img_height - 1'b1))
                    state <= S_BRAM_ADDR;
                else
                    state <= S_RD_FIFO;
            end
            S_BRAM_ADDR : 
            begin
                if(x_cnt == c_dst_img_width - 1'b1)
                    state <= S_Y_INC;
                else
                    state <= S_BRAM_ADDR;
            end
            S_Y_INC : 
            begin
                if(y_cnt == c_dst_img_height - 1'b1)
                    state <= S_RD_FIFO;
                else
                    state <= S_Y_LOAD;
            end
            S_RD_FIFO : 
            begin
                state <= S_IDLE;
            end
            default : 
            begin
                state <= S_IDLE;
            end
        endcase
    end
end

assign fifo_renb = (state == S_RD_FIFO) ? 1'b1 : 1'b0;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
        y_dec <= 27'b0;
    else
    begin
        if((state == S_IDLE)&&(fifo_empty == 1'b0)&&(fifo_rdata == 11'b0))
            y_dec <= 27'b0;
        else if(state == S_Y_INC)
            y_dec <= y_dec + c_y_radio;
        else
            y_dec <= y_dec;
    end
end

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
        y_cnt <= 11'b0;
    else
    begin
        if((state == S_IDLE)&&(fifo_empty == 1'b0)&&(fifo_rdata == 11'b0))
            y_cnt <= 11'b0;
        else if(state == S_Y_INC)
            y_cnt <= y_cnt + 1'b1;
        else
            y_cnt <= y_cnt;
    end
end

always @(posedge clk_in2)
begin
    if(state == S_BRAM_ADDR)
        x_dec <= x_dec + c_x_radio;
    else
        x_dec <= 27'b0;
end

always @(posedge clk_in2)
begin
    if(state == S_BRAM_ADDR)
        x_cnt <= x_cnt + 1'b1;
    else
        x_cnt <= 11'b0;
end

//----------------------------------------------------------------------
//  c1
reg                             img_vs_c1;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
        img_vs_c1 <= 1'b0;
    else
    begin
        if((state == S_BRAM_ADDR)&&(x_cnt == 11'b0)&&(y_cnt == 11'b0))
            img_vs_c1 <= 1'b1;
        else if((state == S_Y_INC)&&(y_cnt == c_dst_img_height - 1'b1))
            img_vs_c1 <= 1'b0;
        else
            img_vs_c1 <= img_vs_c1;
    end
end

reg                             img_hs_c1;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
        img_hs_c1 <= 1'b0;
    else
    begin
        if(state == S_BRAM_ADDR)
            img_hs_c1 <= 1'b1;
        else
            img_hs_c1 <= 1'b0;
    end
end

reg             [10:0]          x_int_c1;
reg             [10:0]          y_int_c1;
reg             [16:0]          x_fra_c1;
reg             [16:0]          y_fra_c1;

always @(posedge clk_in2)
begin
    x_int_c1     <= x_dec[25:16];
    y_int_c1     <= y_dec[25:16];
    x_fra_c1     <= {1'b0,x_dec[15:0]};
    y_fra_c1     <= {1'b0,y_dec[15:0]};
end


//----------------------------------------------------------------------
//  c2

//九点插值法落点区域状态机

//position   为   0001 为第一个点    ，0010 为第二个点  ，    0100为第三个点     ，1000为第四个点
reg           [3:0]             position_c2;
reg                             img_vs_c2;
reg                             img_hs_c2;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c2 <= 1'b0;
        img_hs_c2 <= 1'b0;
    end
    else
    begin
        img_vs_c2 <= img_vs_c1;
        img_hs_c2 <= img_hs_c1;
    end
end

reg             [11:0]          bram_addr_c2;
reg                             bram_mode_c2;

always @(posedge clk_in2)
begin
    bram_addr_c2 <= {y_int_c1[2:1],10'b0} + x_int_c1;
    bram_mode_c2 <= y_int_c1[0];
end

reg                             right_pixel_extand_flag_c2;
reg                             bottom_pixel_extand_flag_c2;

always @(posedge clk_in2)
begin
    if(x_int_c1 == c_src_img_width - 1'b1)
        right_pixel_extand_flag_c2 <= 1'b1;
    else
        right_pixel_extand_flag_c2 <= 1'b0;
    if(y_int_c1 == c_src_img_height - 1'b1)
        bottom_pixel_extand_flag_c2 <= 1'b1;
    else
        bottom_pixel_extand_flag_c2 <= 1'b0;
end



always @(posedge clk_in2)
begin
if(rst_n == 1'b0)
        position_c2 <= 1'b0;
else if( (x_fra_c1 <= 16'd32768) && (y_fra_c1 <= 16'd32768) )//左上
    position_c2  <=   4'b0001;
else if( (x_fra_c1 > 16'd32768) && (y_fra_c1 <= 16'd32768) )//右上
    position_c2  <=   4'b0010;
else if( (x_fra_c1 <= 16'd32768) && (y_fra_c1 > 16'd32768) )//左下
    position_c2  <=   4'b0100;
else if( (x_fra_c1 > 16'd32768) && (y_fra_c1 > 16'd32768) )//右下
    position_c2  <=   4'b1000;
else
    position_c2  <= position_c2;
end




//----------------------------------------------------------------------
//  c3
reg                             img_vs_c3;
reg                             img_hs_c3;
reg          [3:0]                    position_c3;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c3 <= 1'b0;
        img_hs_c3 <= 1'b0;
        position_c3 <= 4'b0;
    end
    else
    begin
        img_vs_c3 <= img_vs_c2;
        img_hs_c3 <= img_hs_c2;
        position_c3 <= position_c2;
    end
end

always @(posedge clk_in2)
begin
    if(bram_mode_c2 == 1'b0)
    begin
        even_bram1_b_raddr <= bram_addr_c2;
        odd_bram1_b_raddr  <= bram_addr_c2 + 1'b1;
        even_bram2_b_raddr <= bram_addr_c2;
        odd_bram2_b_raddr  <= bram_addr_c2 + 1'b1;


    end
    else
    begin
        even_bram1_b_raddr <= bram_addr_c2 + 11'd1024;
        odd_bram1_b_raddr  <= bram_addr_c2 + 11'd1025;
        even_bram2_b_raddr <= bram_addr_c2;
        odd_bram2_b_raddr  <= bram_addr_c2 + 1'b1;

    end
end


reg                             bram_mode_c3;
reg                             right_pixel_extand_flag_c3;
reg                             bottom_pixel_extand_flag_c3;

always @(posedge clk_in2)
begin
    bram_mode_c3                <= bram_mode_c2;
    right_pixel_extand_flag_c3  <= right_pixel_extand_flag_c2;
    bottom_pixel_extand_flag_c3 <= bottom_pixel_extand_flag_c2;
end

//----------------------------------------------------------------------
//  c4
reg                             img_vs_c4;
reg                             img_hs_c4;
reg           [3:0]                   position_c4;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c4 <= 1'b0;
        img_hs_c4 <= 1'b0;
        position_c4<=4'b0;
    end
    else
    begin
        img_vs_c4 <= img_vs_c3;
        img_hs_c4 <= img_hs_c3;
        position_c4<=position_c3;
    end
end

reg                             bram_mode_c4;
reg                             right_pixel_extand_flag_c4;
reg                             bottom_pixel_extand_flag_c4;

always @(posedge clk_in2)
begin
    bram_mode_c4                <= bram_mode_c3;
    right_pixel_extand_flag_c4  <= right_pixel_extand_flag_c3;
    bottom_pixel_extand_flag_c4 <= bottom_pixel_extand_flag_c3;
end

//----------------------------------------------------------------------
//  c5
reg                             img_vs_c5;
reg                             img_hs_c5;
reg             [3:0]                 position_c5;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c5 <= 1'b0;
        img_hs_c5 <= 1'b0;
        position_c5<=4'b0;
    end
    else
    begin
        img_vs_c5 <= img_vs_c4;
        img_hs_c5 <= img_hs_c4;
        position_c5<=position_c4;
    end
end

reg             [7:0]           pixel_data00_c5;
reg             [7:0]           pixel_data01_c5;
reg             [7:0]           pixel_data10_c5;
reg             [7:0]           pixel_data11_c5;

reg             [7:0]           green_pixel_data00_c5;
reg             [7:0]           green_pixel_data01_c5;
reg             [7:0]           green_pixel_data10_c5;
reg             [7:0]           green_pixel_data11_c5;


reg             [7:0]           blue_pixel_data00_c5;
reg             [7:0]           blue_pixel_data01_c5;
reg             [7:0]           blue_pixel_data10_c5;
reg             [7:0]           blue_pixel_data11_c5;






always @(posedge clk_in2)
begin
    if(bram_mode_c4 == 1'b0)
    begin
        pixel_data00_c5 <= red_even_bram1_b_rdata;
        pixel_data01_c5 <= red_odd_bram1_b_rdata;
        pixel_data10_c5 <= red_even_bram2_b_rdata;
        pixel_data11_c5 <= red_odd_bram2_b_rdata;

        green_pixel_data00_c5 <= green_even_bram1_b_rdata;
        green_pixel_data01_c5 <= green_odd_bram1_b_rdata;
        green_pixel_data10_c5 <= green_even_bram2_b_rdata;
        green_pixel_data11_c5 <= green_odd_bram2_b_rdata;

        blue_pixel_data00_c5 <= blue_even_bram1_b_rdata;
        blue_pixel_data01_c5 <= blue_odd_bram1_b_rdata;
        blue_pixel_data10_c5 <= blue_even_bram2_b_rdata;
        blue_pixel_data11_c5 <= blue_odd_bram2_b_rdata;

    end
    else
    begin
        pixel_data00_c5 <= red_even_bram2_b_rdata;
        pixel_data01_c5 <= red_odd_bram2_b_rdata;
        pixel_data10_c5 <= red_even_bram1_b_rdata;
        pixel_data11_c5 <= red_odd_bram1_b_rdata;

        green_pixel_data00_c5 <= green_even_bram2_b_rdata;
        green_pixel_data01_c5 <= green_odd_bram2_b_rdata;
        green_pixel_data10_c5 <= green_even_bram1_b_rdata;
        green_pixel_data11_c5 <= green_odd_bram1_b_rdata;

        blue_pixel_data00_c5 <= blue_even_bram2_b_rdata;
        blue_pixel_data01_c5 <= blue_odd_bram2_b_rdata;
        blue_pixel_data10_c5 <= blue_even_bram1_b_rdata;
        blue_pixel_data11_c5 <= blue_odd_bram1_b_rdata;
    end
end

reg                             right_pixel_extand_flag_c5;
reg                             bottom_pixel_extand_flag_c5;

always @(posedge clk_in2)
begin
    right_pixel_extand_flag_c5  <= right_pixel_extand_flag_c4;
    bottom_pixel_extand_flag_c5 <= bottom_pixel_extand_flag_c4;
end

//----------------------------------------------------------------------
//  c6
reg                             img_vs_c6;
reg                             img_hs_c6;
reg         [3:0]                    position_c6;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c6 <= 1'b0;
        img_hs_c6 <= 1'b0;
        position_c6<=4'b0;
    end
    else
    begin
        img_vs_c6 <= img_vs_c5;
        img_hs_c6 <= img_hs_c5;
        position_c6<=position_c5;
    end
end

reg             [7:0]           pixel_data00_c6;
reg             [7:0]           pixel_data01_c6;
reg             [7:0]           pixel_data10_c6;
reg             [7:0]           pixel_data11_c6;


reg             [7:0]           green_pixel_data00_c6;
reg             [7:0]           green_pixel_data01_c6;
reg             [7:0]           green_pixel_data10_c6;
reg             [7:0]           green_pixel_data11_c6;


reg             [7:0]           blue_pixel_data00_c6;
reg             [7:0]           blue_pixel_data01_c6;
reg             [7:0]           blue_pixel_data10_c6;
reg             [7:0]           blue_pixel_data11_c6;





always @(posedge clk_in2)
begin
    case({right_pixel_extand_flag_c5,bottom_pixel_extand_flag_c5})
        2'b00 : 
        begin
            pixel_data00_c6 <= pixel_data00_c5;
            pixel_data01_c6 <= pixel_data01_c5;
            pixel_data10_c6 <= pixel_data10_c5;
            pixel_data11_c6 <= pixel_data11_c5;

            green_pixel_data00_c6 <= green_pixel_data00_c5;
            green_pixel_data01_c6 <= green_pixel_data01_c5;
            green_pixel_data10_c6 <= green_pixel_data10_c5;
            green_pixel_data11_c6 <= green_pixel_data11_c5;

            blue_pixel_data00_c6 <= blue_pixel_data00_c5;
            blue_pixel_data01_c6 <= blue_pixel_data01_c5;
            blue_pixel_data10_c6 <= blue_pixel_data10_c5;
            blue_pixel_data11_c6 <= blue_pixel_data11_c5;




        end
        2'b01 : 
        begin
            pixel_data00_c6 <= pixel_data00_c5;
            pixel_data01_c6 <= pixel_data01_c5;
            pixel_data10_c6 <= pixel_data00_c5;
            pixel_data11_c6 <= pixel_data01_c5;

            green_pixel_data00_c6 <= green_pixel_data00_c5;
            green_pixel_data01_c6 <= green_pixel_data01_c5;
            green_pixel_data10_c6 <= green_pixel_data00_c5;
            green_pixel_data11_c6 <= green_pixel_data01_c5;

            blue_pixel_data00_c6 <= blue_pixel_data00_c5;
            blue_pixel_data01_c6 <= blue_pixel_data01_c5;
            blue_pixel_data10_c6 <= blue_pixel_data00_c5;
            blue_pixel_data11_c6 <= blue_pixel_data01_c5;
        end
        2'b10 : 
        begin
            pixel_data00_c6 <= pixel_data00_c5;
            pixel_data01_c6 <= pixel_data00_c5;
            pixel_data10_c6 <= pixel_data10_c5;
            pixel_data11_c6 <= pixel_data10_c5;

            green_pixel_data00_c6 <= green_pixel_data00_c5;
            green_pixel_data01_c6 <= green_pixel_data00_c5;
            green_pixel_data10_c6 <= green_pixel_data10_c5;
            green_pixel_data11_c6 <= green_pixel_data10_c5;

            blue_pixel_data00_c6 <= blue_pixel_data00_c5;
            blue_pixel_data01_c6 <= blue_pixel_data00_c5;
            blue_pixel_data10_c6 <= blue_pixel_data10_c5;
            blue_pixel_data11_c6 <= blue_pixel_data10_c5;            

        end
        2'b11 : 
        begin
            pixel_data00_c6 <= pixel_data00_c5;
            pixel_data01_c6 <= pixel_data00_c5;
            pixel_data10_c6 <= pixel_data00_c5;
            pixel_data11_c6 <= pixel_data00_c5;

            green_pixel_data00_c6 <= green_pixel_data00_c5;
            green_pixel_data01_c6 <= green_pixel_data00_c5;
            green_pixel_data10_c6 <= green_pixel_data00_c5;
            green_pixel_data11_c6 <= green_pixel_data00_c5;

            blue_pixel_data00_c6 <= blue_pixel_data00_c5;
            blue_pixel_data01_c6 <= blue_pixel_data00_c5;
            blue_pixel_data10_c6 <= blue_pixel_data00_c5;
            blue_pixel_data11_c6 <= blue_pixel_data00_c5;                        
        end
    endcase
end


//----------------------------------------------------------------------
//  c7
reg                             img_vs_c7;
reg                             img_hs_c7;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c7 <= 1'b0;
        img_hs_c7 <= 1'b0;
    end
    else
    begin
        img_vs_c7 <= img_vs_c6;
        img_hs_c7 <= img_hs_c6;
    end
end

reg             [41:0]          cof_data00_c7;
reg             [41:0]          cof_data01_c7;
reg             [41:0]          cof_data10_c7;
reg             [41:0]          cof_data11_c7;

reg             [41:0]          green_cof_data00_c7;
reg             [41:0]          green_cof_data01_c7;
reg             [41:0]          green_cof_data10_c7;
reg             [41:0]          green_cof_data11_c7;

reg             [41:0]          blue_cof_data00_c7;
reg             [41:0]          blue_cof_data01_c7;
reg             [41:0]          blue_cof_data10_c7;
reg             [41:0]          blue_cof_data11_c7;







//0.5625 ->  16'd36864;
//0.1875 ->  16'd12288;
//0.0625 ->  16'd4096;
// frac_00_c6
// frac_01_c6
// frac_10_c6
// frac_11_c6

always @(posedge clk_in2)
begin
case(position_c6)
        4'b0000 : 
        begin
            cof_data00_c7  <=   42'd0;
            cof_data01_c7  <=   42'd0;
            cof_data10_c7  <=   42'd0;
            cof_data11_c7  <=   42'd0;

            green_cof_data00_c7  <=   42'd0;
            green_cof_data01_c7  <=   42'd0;
            green_cof_data10_c7  <=   42'd0;
            green_cof_data11_c7  <=   42'd0;

            blue_cof_data00_c7  <=   42'd0;
            blue_cof_data01_c7  <=   42'd0;
            blue_cof_data10_c7  <=   42'd0;
            blue_cof_data11_c7  <=   42'd0;
        end
        4'b0001 : 
        begin
            cof_data00_c7 <= 16'd36864 * pixel_data00_c6 ;
            cof_data01_c7 <= 16'd12288 * pixel_data01_c6 ;
            cof_data10_c7 <= 16'd12288 * pixel_data10_c6 ;
            cof_data11_c7 <= 16'd4096  * pixel_data11_c6  ;


            green_cof_data00_c7 <= 16'd36864 * green_pixel_data00_c6 ;
            green_cof_data01_c7 <= 16'd12288 * green_pixel_data01_c6 ;
            green_cof_data10_c7 <= 16'd12288 * green_pixel_data10_c6 ;
            green_cof_data11_c7 <= 16'd4096  * green_pixel_data11_c6  ;

            blue_cof_data00_c7 <= 16'd36864 * blue_pixel_data00_c6 ;
            blue_cof_data01_c7 <= 16'd12288 * blue_pixel_data01_c6 ;
            blue_cof_data10_c7 <= 16'd12288 * blue_pixel_data10_c6 ;
            blue_cof_data11_c7 <= 16'd4096  * blue_pixel_data11_c6  ;                        
        end
        4'b0010 : 
        begin
            cof_data00_c7 <= 16'd12288 *  pixel_data00_c6 ;
            cof_data01_c7 <= 16'd36864 *  pixel_data01_c6 ;
            cof_data10_c7 <= 16'd4096 *   pixel_data10_c6 ;
            cof_data11_c7 <= 16'd12288  * pixel_data11_c6  ;

            green_cof_data00_c7 <= 16'd12288 *  green_pixel_data00_c6 ;
            green_cof_data01_c7 <= 16'd36864 *  green_pixel_data01_c6 ;
            green_cof_data10_c7 <= 16'd4096 *   green_pixel_data10_c6 ;
            green_cof_data11_c7 <= 16'd12288  * green_pixel_data11_c6  ;

            blue_cof_data00_c7 <= 16'd12288 *  blue_pixel_data00_c6 ;
            blue_cof_data01_c7 <= 16'd36864 *  blue_pixel_data01_c6 ;
            blue_cof_data10_c7 <= 16'd4096 *   blue_pixel_data10_c6 ;
            blue_cof_data11_c7 <= 16'd12288  * blue_pixel_data11_c6  ;
        end
        4'b0100 : 
        begin
            cof_data00_c7 <= 16'd12288 *  pixel_data00_c6 ;
            cof_data01_c7 <= 16'd4096 *   pixel_data01_c6 ;
            cof_data10_c7 <= 16'd36864 *  pixel_data10_c6 ;
            cof_data11_c7 <= 16'd12288  * pixel_data11_c6  ;

            green_cof_data00_c7 <= 16'd12288 *  green_pixel_data00_c6 ;
            green_cof_data01_c7 <= 16'd4096 *   green_pixel_data01_c6 ;
            green_cof_data10_c7 <= 16'd36864 *  green_pixel_data10_c6 ;
            green_cof_data11_c7 <= 16'd12288  * green_pixel_data11_c6  ;

            blue_cof_data00_c7 <= 16'd12288 *  blue_pixel_data00_c6 ;
            blue_cof_data01_c7 <= 16'd4096 *   blue_pixel_data01_c6 ;
            blue_cof_data10_c7 <= 16'd36864 *  blue_pixel_data10_c6 ;
            blue_cof_data11_c7 <= 16'd12288  * blue_pixel_data11_c6  ;            

        end
        4'b1000 :
        begin
            cof_data00_c7 <= 16'd4096   * pixel_data00_c6 ;
            cof_data01_c7 <= 16'd12288  * pixel_data01_c6 ;
            cof_data10_c7 <= 16'd12288  * pixel_data10_c6 ;
            cof_data11_c7 <= 16'd36864  * pixel_data11_c6  ;            

            green_cof_data00_c7 <= 16'd4096   * green_pixel_data00_c6 ;
            green_cof_data01_c7 <= 16'd12288  * green_pixel_data01_c6 ;
            green_cof_data10_c7 <= 16'd12288  * green_pixel_data10_c6 ;
            green_cof_data11_c7 <= 16'd36864  * green_pixel_data11_c6  ;     

            blue_cof_data00_c7 <= 16'd4096   * blue_pixel_data00_c6 ;
            blue_cof_data01_c7 <= 16'd12288  * blue_pixel_data01_c6 ;
            blue_cof_data10_c7 <= 16'd12288  * blue_pixel_data10_c6 ;
            blue_cof_data11_c7 <= 16'd36864  * blue_pixel_data11_c6  ;     



        end
    endcase
end

//----------------------------------------------------------------------
//  c8
reg                             img_vs_c8;
reg                             img_hs_c8;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c8 <= 1'b0;
        img_hs_c8 <= 1'b0;
    end
    else
    begin
        img_vs_c8 <= img_vs_c7;
        img_hs_c8 <= img_hs_c7;
    end
end

reg             [42:0]          gray_data_tmp1_c8;
reg             [42:0]          gray_data_tmp2_c8;

reg             [42:0]          green_gray_data_tmp1_c8;
reg             [42:0]          green_gray_data_tmp2_c8;

reg             [42:0]          blue_gray_data_tmp1_c8;
reg             [42:0]          blue_gray_data_tmp2_c8;



always @(posedge clk_in2)
begin
    gray_data_tmp1_c8 <= cof_data00_c7 + cof_data01_c7;
    gray_data_tmp2_c8 <= cof_data10_c7 + cof_data11_c7;


    green_gray_data_tmp1_c8 <= green_cof_data00_c7 + green_cof_data01_c7;
    green_gray_data_tmp2_c8 <= green_cof_data10_c7 + green_cof_data11_c7;

    blue_gray_data_tmp1_c8 <= blue_cof_data00_c7 + blue_cof_data01_c7;
    blue_gray_data_tmp2_c8 <= blue_cof_data10_c7 + blue_cof_data11_c7;


end

//----------------------------------------------------------------------
//  c9
reg                             img_vs_c9;
reg                             img_hs_c9;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c9 <= 1'b0;
        img_hs_c9 <= 1'b0;
    end
    else
    begin
        img_vs_c9 <= img_vs_c8;
        img_hs_c9 <= img_hs_c8;
    end
end

reg             [43:0]          gray_data_c9;
reg             [43:0]          green_gray_data_c9;
reg             [43:0]          blue_gray_data_c9;



always @(posedge clk_in2)
begin
    gray_data_c9 <= gray_data_tmp1_c8 + gray_data_tmp2_c8;
    green_gray_data_c9 <= green_gray_data_tmp1_c8 + green_gray_data_tmp2_c8;
    blue_gray_data_c9 <= blue_gray_data_tmp1_c8 + blue_gray_data_tmp2_c8;

end

//----------------------------------------------------------------------
//  c10
reg                             img_vs_c10;
reg                             img_hs_c10;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c10 <= 1'b0;
        img_hs_c10 <= 1'b0;
    end
    else
    begin
        img_vs_c10 <= img_vs_c9;
        img_hs_c10 <= img_hs_c9;
    end
end

reg             [11:0]          gray_data_c10;

reg             [11:0]          green_gray_data_c10;

reg             [11:0]          blue_gray_data_c10;

always @(posedge clk_in2)
begin
    gray_data_c10 <= gray_data_c9[37:16] + gray_data_c9[15];
    green_gray_data_c10 <= green_gray_data_c9[37:16] + green_gray_data_c9[15];
    blue_gray_data_c10 <= blue_gray_data_c9[37:16] + blue_gray_data_c9[15];
end

//----------------------------------------------------------------------
//  signals output
always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        post_img_vsync <= 1'b0;
        post_img_de  <= 1'b0;
    end
    else
    begin
        post_img_vsync <= img_vs_c10;
        post_img_de  <= img_hs_c10;
    end
end


always @(posedge clk_in2)
begin
    if(gray_data_c10 > 12'd255)
    begin
        post_img_red <= 8'd255;
        post_img_green <= 8'd255;
        post_img_blue <= 8'd255;
    end

    else
    begin
        post_img_red <= gray_data_c10[7:0];
        post_img_green <= green_gray_data_c10[7:0];
        post_img_blue <= blue_gray_data_c10[7:0];
    end

end

endmodule