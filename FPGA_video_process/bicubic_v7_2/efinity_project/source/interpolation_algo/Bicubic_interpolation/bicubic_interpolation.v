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


module bicubic_interpolation
/* #(
    parameter C_SRC_IMG_WIDTH  = 11'd640    ,
    parameter C_SRC_IMG_HEIGHT = 11'd480    ,
    parameter C_DST_IMG_WIDTH  = 11'd1024   ,
    parameter C_DST_IMG_HEIGHT = 11'd768    ,
    parameter C_X_RATIO        = 16'd40960  ,           //  floor(C_SRC_IMG_WIDTH/C_DST_IMG_WIDTH*2^16)
    parameter C_Y_RATIO        = 16'd40960              //  floor(C_SRC_IMG_HEIGHT/C_DST_IMG_HEIGHT*2^16)
) */
(
    input   wire    [10:0]      C_SRC_IMG_WIDTH   ,
    input   wire    [10:0]      C_SRC_IMG_HEIGHT  ,
    input   wire    [10:0]      C_DST_IMG_WIDTH   ,
    input   wire    [10:0]      C_DST_IMG_HEIGHT  ,
    input   wire    [15:0]      C_X_RATIO         ,
    input   wire    [15:0]      C_Y_RATIO         ,

    input  wire                 clk_in1         ,
    input  wire                 clk_in2         ,
    input  wire                 clk_in2_4x      ,
    input  wire                 rst_n           ,
    
    //  Image data prepared to be processed
    input  wire                 per_img_vsync   ,       //  Prepared Image data vsync valid signal
    input  wire                 per_img_href    ,       //  Prepared Image data href vaild  signal
    input  wire     [7:0]       per_img_red    ,       //  Prepared Image brightness input
    input  wire     [7:0]       per_img_green    ,
    input  wire     [7:0]       per_img_blue    ,
    //  Image data has been processed
    output reg                  post_img_vsync  ,       //  processed Image data vsync valid signal
    output reg                  post_img_href   ,       //  processed Image data href vaild  signal
    output wire      [7:0]      post_img_red    ,       //  processed Image brightness output
    output wire      [7:0]      post_img_green    ,
    output wire      [7:0]      post_img_blue            
);
//----------------------------------------------------------------------
reg                             per_img_href_dly;
//使能信号延时
always @(posedge clk_in1)
begin
    if(rst_n == 1'b0)
        per_img_href_dly <= 1'b0;
    else
        per_img_href_dly <= per_img_href;
end

//
wire                            per_img_href_neg;

assign per_img_href_neg = per_img_href_dly & ~per_img_href;

reg             [10:0]          img_vs_cnt;                             //  from 0 to C_SRC_IMG_HEIGHT - 1

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
            if(per_img_href_neg == 1'b1)
                img_vs_cnt <= img_vs_cnt + 1'b1;
            else
                img_vs_cnt <= img_vs_cnt;
        end
    end
end

reg             [10:0]          img_hs_cnt;                             //  from 0 to C_SRC_IMG_WIDTH - 1

always @(posedge clk_in1)
begin
    if(rst_n == 1'b0)
        img_hs_cnt <= 11'b0;
    else
    begin
        if((per_img_vsync == 1'b1)&&(per_img_href == 1'b1))
            img_hs_cnt <= img_hs_cnt + 1'b1;
        else
            img_hs_cnt <= 11'b0;
    end
end

//----------------------------------------------------------------------
//bram信号值赋值，需要修改
reg             [7:0]           bram_a_wdata;
reg             [7:0]           green_bram_a_wdata;
reg             [7:0]           blue_bram_a_wdata;


always @(posedge clk_in1)
begin
    bram_a_wdata <= per_img_red;
    green_bram_a_wdata <=  per_img_green;
    blue_bram_a_wdata <= per_img_blue;
end

reg             [11:0]          bram_a_waddr;


//bram地址计算
always @(posedge clk_in1)
begin
    bram_a_waddr <= {img_vs_cnt[2:1],10'b0} + img_hs_cnt;
end

reg                             bram1_a_wenb;

//奇数行bram写使能赋值
always @(posedge clk_in1)
begin
    if(rst_n == 1'b0)
        bram1_a_wenb <= 1'b0;
    else
        bram1_a_wenb <= per_img_vsync & per_img_href & ~img_vs_cnt[0];
end

//偶数行bram写使能赋值
reg                             bram2_a_wenb;

always @(posedge clk_in1)
begin
    if(rst_n == 1'b0)
        bram2_a_wenb <= 1'b0;
    else
        bram2_a_wenb <= per_img_vsync & per_img_href & img_vs_cnt[0];
end


//fifo写入标签数据
reg             [10:0]          fifo_wdata;

always @(posedge clk_in1)
begin
    fifo_wdata <= img_vs_cnt;
end

//每行结束，场同步信号为高时说明一行结束，进行行数赋值
reg                             fifo_wenb;

always @(posedge clk_in1)
begin
    if(rst_n == 1'b0)
        fifo_wenb <= 1'b0;
    else
    begin
        if((per_img_vsync == 1'b1)&&(per_img_href == 1'b1)&&(img_hs_cnt == C_SRC_IMG_WIDTH - 1'b1))
            fifo_wenb <= 1'b1;
        else
            fifo_wenb <= 1'b0;
    end
end

//----------------------------------------------------------------------
//  bram & fifo rw
reg             [11:0]          even_bram1_b_raddr;
reg             [11:0]          odd_bram1_b_raddr;
reg             [11:0]          even_bram1_b_raddr_left_1;
reg             [11:0]          odd_bram1_b_raddr_right_1;
reg             [11:0]          top_01_raddr;
reg             [11:0]          top_02_raddr;
reg             [11:0]          top_03_raddr;
reg             [11:0]          top_04_raddr;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////




reg             [11:0]          even_bram2_b_raddr;
reg             [11:0]          odd_bram2_b_raddr;
reg             [11:0]          even_bram2_b_raddr_left_1;
reg             [11:0]          odd_bram2_b_raddr_right_1;
reg             [11:0]          bottom_01_raddr;
reg             [11:0]          bottom_02_raddr;
reg             [11:0]          bottom_03_raddr;
reg             [11:0]          bottom_04_raddr;



///////////////////////////////////////////////////////////////////////////////////////////////////


wire             [7:0]          even_bram1_b_rdata;
wire             [7:0]          odd_bram1_b_rdata;
wire             [7:0]          even_bram1_b_rdata_left_1;
wire             [7:0]          odd_bram1_b_rdata_right_1;

wire             [7:0]          green_even_bram1_b_rdata;
wire             [7:0]          green_odd_bram1_b_rdata;
wire             [7:0]          green_even_bram1_b_rdata_left_1;
wire             [7:0]          green_odd_bram1_b_rdata_right_1;

wire             [7:0]          blue_even_bram1_b_rdata;
wire             [7:0]          blue_odd_bram1_b_rdata;
wire             [7:0]          blue_even_bram1_b_rdata_left_1;
wire             [7:0]          blue_odd_bram1_b_rdata_right_1;

////////////////////////////////////////////////////////////////////////////////////////////////////


wire             [7:0]          even_bram2_b_rdata;
wire             [7:0]          odd_bram2_b_rdata;
wire             [7:0]          even_bram2_b_rdata_left_1;
wire             [7:0]          odd_bram2_b_rdata_right_1;

wire             [7:0]          green_even_bram2_b_rdata;
wire             [7:0]          green_odd_bram2_b_rdata;
wire             [7:0]          green_even_bram2_b_rdata_left_1;
wire             [7:0]          green_odd_bram2_b_rdata_right_1;

wire             [7:0]          blue_even_bram2_b_rdata;
wire             [7:0]          blue_odd_bram2_b_rdata;
wire             [7:0]          blue_even_bram2_b_rdata_left_1;
wire             [7:0]          blue_odd_bram2_b_rdata_right_1;


////////////////////////////////////////////////////////////////////////////////////////////////////////////

wire             [11:0]          odd_01_raddr;
wire             [11:0]          odd_02_raddr;
wire             [11:0]          odd_03_raddr;
wire             [11:0]          odd_04_raddr;


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

wire             [7:0]          odd_01_rdata;
wire             [7:0]          odd_02_rdata;
wire             [7:0]          odd_03_rdata;
wire             [7:0]          odd_04_rdata;

wire             [7:0]          green_odd_01_rdata;
wire             [7:0]          green_odd_02_rdata;
wire             [7:0]          green_odd_03_rdata;
wire             [7:0]          green_odd_04_rdata;

wire             [7:0]          blue_odd_01_rdata;
wire             [7:0]          blue_odd_02_rdata;
wire             [7:0]          blue_odd_03_rdata;
wire             [7:0]          blue_odd_04_rdata;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


wire             [11:0]          even_01_raddr;
wire             [11:0]          even_02_raddr;
wire             [11:0]          even_03_raddr;
wire             [11:0]          even_04_raddr;


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



wire             [7:0]          even_01_rdata;
wire             [7:0]          even_02_rdata;
wire             [7:0]          even_03_rdata;
wire             [7:0]          even_04_rdata;

wire             [7:0]          green_even_01_rdata;
wire             [7:0]          green_even_02_rdata;
wire             [7:0]          green_even_03_rdata;
wire             [7:0]          green_even_04_rdata;

wire             [7:0]          blue_even_01_rdata;
wire             [7:0]          blue_even_02_rdata;
wire             [7:0]          blue_even_03_rdata;
wire             [7:0]          blue_even_04_rdata;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



reg                             img_vs_c1;




//八端口非对称bram1______red

high_speed_ram_controller
#(
.C_ADDR_WIDTH(12),
.C_DATA_WIDTH(8)
)
high_speed_ram_controller_inst_red1
(
    .wclk   (clk_in1) ,
    .wen    (bram1_a_wenb) ,
    .waddr  (bram_a_waddr) ,
    .wdata  (bram_a_wdata) ,
    
    .vs     (img_vs_c1),
    .rclk_4x(clk_in2_4x),
    .rclk   (clk_in2) ,
    .raddr0 (even_bram1_b_raddr) ,
    .rdata0 (even_bram1_b_rdata) ,
    .raddr1 (odd_bram1_b_raddr) ,
    .rdata1 (odd_bram1_b_rdata) ,
    .raddr2 (even_bram1_b_raddr_left_1) ,
    .rdata2 (even_bram1_b_rdata_left_1) ,
    .raddr3 (odd_bram1_b_raddr_right_1) ,
    .rdata3 (odd_bram1_b_rdata_right_1) ,
    .raddr4 (odd_01_raddr) ,
    .rdata4 (odd_01_rdata) ,
    .raddr5 (odd_02_raddr) ,
    .rdata5 (odd_02_rdata) ,
    .raddr6 (odd_03_raddr) ,
    .rdata6 (odd_03_rdata) ,
    .raddr7 (odd_04_raddr) ,
    .rdata7 (odd_04_rdata) 
);


//八端口非对称bram1

high_speed_ram_controller
#(
.C_ADDR_WIDTH(12),
.C_DATA_WIDTH(8)
)
high_speed_ram_controller_inst_red2
(
    .wclk   (clk_in1) ,
    .wen    (bram2_a_wenb) ,
    .waddr  (bram_a_waddr) ,
    .wdata  (bram_a_wdata) ,
    
    .vs     (img_vs_c1),
    .rclk_4x(clk_in2_4x),
    .rclk   (clk_in2) ,
    .raddr0 (even_bram2_b_raddr) ,
    .rdata0 (even_bram2_b_rdata) ,
    .raddr1 (odd_bram2_b_raddr) ,
    .rdata1 (odd_bram2_b_rdata) ,
    .raddr2 (even_bram2_b_raddr_left_1) ,
    .rdata2 (even_bram2_b_rdata_left_1) ,
    .raddr3 (odd_bram2_b_raddr_right_1) ,
    .rdata3 (odd_bram2_b_rdata_right_1) ,
    .raddr4 (even_01_raddr) ,
    .rdata4 (even_01_rdata) ,
    .raddr5 (even_02_raddr) ,
    .rdata5 (even_02_rdata) ,
    .raddr6 (even_03_raddr) ,
    .rdata6 (even_03_rdata) ,
    .raddr7 (even_04_raddr) ,
    .rdata7 (even_04_rdata) 
);
/////////////////////////////////////////////////////////////////////////////////////////
//八端口非对称bram1______green

high_speed_ram_controller
#(
.C_ADDR_WIDTH(12),
.C_DATA_WIDTH(8)
)
high_speed_ram_controller_inst_green1
(
    .wclk   (clk_in1) ,
    .wen    (bram1_a_wenb) ,
    .waddr  (bram_a_waddr) ,
    .wdata  (green_bram_a_wdata) ,

    .vs     (img_vs_c1),
    .rclk_4x(clk_in2_4x),    
    .rclk   (clk_in2) ,
    .raddr0 (even_bram1_b_raddr) ,
    .rdata0 (green_even_bram1_b_rdata) ,
    .raddr1 (odd_bram1_b_raddr) ,
    .rdata1 (green_odd_bram1_b_rdata) ,
    .raddr2 (even_bram1_b_raddr_left_1) ,
    .rdata2 (green_even_bram1_b_rdata_left_1) ,
    .raddr3 (odd_bram1_b_raddr_right_1) ,
    .rdata3 (green_odd_bram1_b_rdata_right_1) ,
    .raddr4 (odd_01_raddr) ,
    .rdata4 (green_odd_01_rdata) ,
    .raddr5 (odd_02_raddr) ,
    .rdata5 (green_odd_02_rdata) ,
    .raddr6 (odd_03_raddr) ,
    .rdata6 (green_odd_03_rdata) ,
    .raddr7 (odd_04_raddr) ,
    .rdata7 (green_odd_04_rdata) 
);



//八端口非对称bram1

high_speed_ram_controller
#(
.C_ADDR_WIDTH(12),
.C_DATA_WIDTH(8)
)
high_speed_ram_controller_inst_green2
(
    .wclk   (clk_in1) ,
    .wen    (bram2_a_wenb) ,
    .waddr  (bram_a_waddr) ,
    .wdata  (green_bram_a_wdata) ,

    .vs     (img_vs_c1),
    .rclk_4x(clk_in2_4x),    
    .rclk   (clk_in2) ,
    .raddr0 (even_bram2_b_raddr) ,
    .rdata0 (green_even_bram2_b_rdata) ,
    .raddr1 (odd_bram2_b_raddr) ,
    .rdata1 (green_odd_bram2_b_rdata) ,
    .raddr2 (even_bram2_b_raddr_left_1) ,
    .rdata2 (green_even_bram2_b_rdata_left_1) ,
    .raddr3 (odd_bram2_b_raddr_right_1) ,
    .rdata3 (green_odd_bram2_b_rdata_right_1) ,
    .raddr4 (even_01_raddr) ,
    .rdata4 (green_even_01_rdata) ,
    .raddr5 (even_02_raddr) ,
    .rdata5 (green_even_02_rdata) ,
    .raddr6 (even_03_raddr) ,
    .rdata6 (green_even_03_rdata) ,
    .raddr7 (even_04_raddr) ,
    .rdata7 (green_even_04_rdata) 
);

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//八端口非对称bram1______blue

high_speed_ram_controller
#(
.C_ADDR_WIDTH(12),
.C_DATA_WIDTH(8)
)
high_speed_ram_controller_inst_blue1
(
    .wclk   (clk_in1) ,
    .wen    (bram1_a_wenb) ,
    .waddr  (bram_a_waddr) ,
    .wdata  (blue_bram_a_wdata) ,

    .vs     (img_vs_c1),
    .rclk_4x(clk_in2_4x),    
    .rclk   (clk_in2) ,
    .raddr0 (even_bram1_b_raddr) ,
    .rdata0 (blue_even_bram1_b_rdata) ,
    .raddr1 (odd_bram1_b_raddr) ,
    .rdata1 (blue_odd_bram1_b_rdata) ,
    .raddr2 (even_bram1_b_raddr_left_1) ,
    .rdata2 (blue_even_bram1_b_rdata_left_1) ,
    .raddr3 (odd_bram1_b_raddr_right_1) ,
    .rdata3 (blue_odd_bram1_b_rdata_right_1) ,
    .raddr4 (odd_01_raddr) ,
    .rdata4 (blue_odd_01_rdata) ,
    .raddr5 (odd_02_raddr) ,
    .rdata5 (blue_odd_02_rdata) ,
    .raddr6 (odd_03_raddr) ,
    .rdata6 (blue_odd_03_rdata) ,
    .raddr7 (odd_04_raddr) ,
    .rdata7 (blue_odd_04_rdata) 
);



//八端口非对称bram1

high_speed_ram_controller
#(
.C_ADDR_WIDTH(12),
.C_DATA_WIDTH(8)
)
high_speed_ram_controller_inst_blue2
(
    .wclk   (clk_in1) ,
    .wen    (bram2_a_wenb) ,
    .waddr  (bram_a_waddr) ,
    .wdata  (blue_bram_a_wdata) ,

    .vs     (img_vs_c1),
    .rclk_4x(clk_in2_4x),    
    .rclk   (clk_in2) ,
    .raddr0 (even_bram2_b_raddr) ,
    .rdata0 (blue_even_bram2_b_rdata) ,
    .raddr1 (odd_bram2_b_raddr) ,
    .rdata1 (blue_odd_bram2_b_rdata) ,
    .raddr2 (even_bram2_b_raddr_left_1) ,
    .rdata2 (blue_even_bram2_b_rdata_left_1) ,
    .raddr3 (odd_bram2_b_raddr_right_1) ,
    .rdata3 (blue_odd_bram2_b_rdata_right_1) ,
    .raddr4 (even_01_raddr) ,
    .rdata4 (blue_even_01_rdata) ,
    .raddr5 (even_02_raddr) ,
    .rdata5 (blue_even_02_rdata) ,
    .raddr6 (even_03_raddr) ,
    .rdata6 (blue_even_03_rdata) ,
    .raddr7 (even_04_raddr) ,
    .rdata7 (blue_even_04_rdata) 
);


///////////////////////////////////////////////////////////////////////////////////////////////////////////
























/////////////////////////////////////////////////////////////////////////////////

wire                            fifo_renb;
wire            [10:0]          fifo_rdata;
wire                            fifo_empty;
wire                            fifo_full;

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
                    if((fifo_rdata != 11'b0)&&(y_cnt == C_DST_IMG_HEIGHT))
                        state <= S_RD_FIFO;
                    else
                        state <= S_Y_LOAD;
                end
                else
                    state <= S_IDLE;
            end
            S_Y_LOAD : 
            begin
                if((y_dec[26:16] + 2'd1 <= fifo_rdata)||(y_cnt == C_DST_IMG_HEIGHT - 2'd1))//完成两行缓存
                    state <= S_BRAM_ADDR;
                else
                    state <= S_RD_FIFO;
            end
            S_BRAM_ADDR : 
            begin
                if(x_cnt == C_DST_IMG_WIDTH - 1'b1)
                    state <= S_Y_INC;
                else
                    state <= S_BRAM_ADDR;
            end
            S_Y_INC : 
            begin
                if(y_cnt == C_DST_IMG_HEIGHT - 1'b1)
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

//原始图像坐标的赋值
always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
        y_dec <= 27'b0;
    else
    begin
        if((state == S_IDLE)&&(fifo_empty == 1'b0)&&(fifo_rdata == 11'b0))
            y_dec <= 27'b0;
        else if(state == S_Y_INC)
            y_dec <= y_dec + C_Y_RATIO;
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
        x_dec <= x_dec + C_X_RATIO;
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


//帧标志flag信号
always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
        img_vs_c1 <= 1'b0;
    else
    begin
        if((state == S_BRAM_ADDR)&&(x_cnt == 11'b0)&&(y_cnt == 11'b0))//一帧开始的时候，进行拉高
            img_vs_c1 <= 1'b1;
        else if((state == S_Y_INC)&&(y_cnt == C_DST_IMG_HEIGHT - 1'b1))//一帧结束的时候拉低两个输出时钟周期
            img_vs_c1 <= 1'b0;
        else
            img_vs_c1 <= img_vs_c1;//其余情况不变
    end
end

reg                             img_hs_c1;

//行标志flag信号
always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
        img_hs_c1 <= 1'b0;
    else
    begin
        if(state == S_BRAM_ADDR)
            img_hs_c1 <= 1'b1;//处于行计算时拉高
        else
            img_hs_c1 <= 1'b0;//不在行计算时拉低
    end
end

reg             [10:0]          x_int_c1;
reg             [10:0]          y_int_c1;
reg             [16:0]          x_fra_c1;
reg             [16:0]          inv_x_fra_c1;
reg             [16:0]          y_fra_c1;
reg             [16:0]          inv_y_fra_c1;






//重要!!!左上角坐标的获取和差值的获取
always @(posedge clk_in2)
begin
    x_int_c1     <= x_dec[25:16];//取亚像素坐标的整数x部分，即为左上角像素的x坐标值
    y_int_c1     <= y_dec[25:16];//取亚像素坐标的整数y部分，即为左上角像素的y坐标值
    x_fra_c1     <= {1'b0,x_dec[15:0]};//构造标定小数，整数部分为0，小数部分为16位信号,x与左最近邻像素相距的亚像素值
    inv_x_fra_c1 <= 17'h10000 - {1'b0,x_dec[15:0]};//1-x_fra_c1
    y_fra_c1     <= {1'b0,y_dec[15:0]};//构造标定小数，整数部分为0，小数部分为16位信号,y与左最近邻像素相距的亚像素值
    inv_y_fra_c1 <= 17'h10000 - {1'b0,y_dec[15:0]};//1-y_fra_c1
end




//----------------------------------------------------------------------
//  c2
//标志信号打拍一个时钟周期
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

//quanzontg
reg             [11:0]          bram_addr_c2;
reg             [16:0]          x_fra_c2;
reg             [16:0]          y_fra_c2;
reg                             bram_mode_c2;

//重点！！！权重计算
always @(posedge clk_in2)
begin
    bram_addr_c2 <= {y_int_c1[2:1],10'b0} + x_int_c1;
    x_fra_c2     <= x_fra_c1;
    y_fra_c2     <= y_fra_c1;
    bram_mode_c2 <= y_int_c1[0];
end




//边缘检测信号
reg                             right_pixel_extand_flag_c2;
reg                             bottom_pixel_extand_flag_c2;

always @(posedge clk_in2)
begin
    if(x_int_c1 == C_SRC_IMG_WIDTH - 1'b1)
        right_pixel_extand_flag_c2 <= 1'b1;//右边缘检测信号
    else
        right_pixel_extand_flag_c2 <= 1'b0;
    if(y_int_c1 == C_SRC_IMG_HEIGHT - 1'b1)//底边缘检测信号
        bottom_pixel_extand_flag_c2 <= 1'b1;
    else
        bottom_pixel_extand_flag_c2 <= 1'b0;
end

//----------------------------------------------------------------------
//  c3
//帧行标志信号打拍
reg                             img_vs_c3;
reg                             img_hs_c3;
always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c3 <= 1'b0;
        img_hs_c3 <= 1'b0;
    end
    else
    begin
        img_vs_c3 <= img_vs_c2;
        img_hs_c3 <= img_hs_c2;
    end
end





//////////////////////////////////////////////////////////////////////////////////////////////////////////
//重点！！！原始像素值的获取
wire          [11:0]       bram_addr_c2_pre;
wire          [11:0]       bram_addr_c2_next;



assign       bram_addr_c2_pre = (y_int_c1 == 1'b0)?(bram_addr_c2):(bram_addr_c2 -12'b01_00000_00000) ;//如果左上最近邻像素位于第一排，则不计算上一手
assign       bram_addr_c2_next = (y_int_c1 == C_SRC_IMG_HEIGHT - 1'b1)?(bram_addr_c2):(bram_addr_c2 + 12'b01_00000_00000) ;//如果左上最近邻像素位于最后一排，则不计算下一手



always @(posedge clk_in2)
begin
    if(bram_mode_c2 == 1'b0)
    begin
        even_bram1_b_raddr        <= bram_addr_c2;
        odd_bram1_b_raddr         <= bram_addr_c2 + 1'b1;
        even_bram1_b_raddr_left_1 <= bram_addr_c2 - 1'b1;
        odd_bram1_b_raddr_right_1 <= bram_addr_c2 + 2'd2;
        top_01_raddr              <= bram_addr_c2_pre -1'b1 ;
        top_02_raddr              <= bram_addr_c2_pre  ;
        top_03_raddr              <= bram_addr_c2_pre + 1'b1 ;
        top_04_raddr              <= bram_addr_c2_pre + 2'd2 ;

        even_bram2_b_raddr <= bram_addr_c2;
        odd_bram2_b_raddr  <= bram_addr_c2 + 1'b1;
        even_bram2_b_raddr_left_1 <=  bram_addr_c2 - 1'b1;
        odd_bram2_b_raddr_right_1 <=  bram_addr_c2 + 2'd2;
        bottom_01_raddr    <=    bram_addr_c2_next - 1'b1;
        bottom_02_raddr    <=    bram_addr_c2_next ;
        bottom_03_raddr    <=    bram_addr_c2_next + 1'b1 ;
        bottom_04_raddr    <=    bram_addr_c2_next + 2'd2;
    end
    else
    begin
        even_bram1_b_raddr <= bram_addr_c2 + 11'd1024;
        odd_bram1_b_raddr  <= bram_addr_c2 + 11'd1025;
        even_bram1_b_raddr_left_1 <= bram_addr_c2 + 11'd1023;
        odd_bram1_b_raddr_right_1  <= bram_addr_c2 + 11'd1026;
        top_01_raddr              <= bram_addr_c2 -1'b1 ;  //与奇数不同的是，这里不加pre，因为上一行的和左上最近邻在同一手
        top_02_raddr              <= bram_addr_c2  ;
        top_03_raddr              <= bram_addr_c2 + 1'b1 ;
        top_04_raddr              <= bram_addr_c2 + 2'd2 ;


        even_bram2_b_raddr <= bram_addr_c2;
        odd_bram2_b_raddr  <= bram_addr_c2 + 1'b1;
        even_bram2_b_raddr_left_1  <= bram_addr_c2 - 1'b1 ;
        odd_bram2_b_raddr_right_1  <= bram_addr_c2 +2'd2 ;
        bottom_01_raddr    <=    bram_addr_c2_next - 1'b1;
        bottom_02_raddr    <=    bram_addr_c2_next ;
        bottom_03_raddr    <=    bram_addr_c2_next + 1'b1 ;
        bottom_04_raddr    <=    bram_addr_c2_next + 2'd2;

    end
end
 
assign    odd_01_raddr     =  (~bram_mode_c2) ? (bottom_01_raddr)  :  (top_01_raddr);//左上角最近邻位于奇数行模式下，奇数bram中对应的是底部的数据
assign    odd_02_raddr     =  (~bram_mode_c2) ? (bottom_02_raddr)  :  (top_02_raddr);//左上角最近邻位于奇数行模式下，奇数bram中对应的是底部的数据
assign    odd_03_raddr     =  (~bram_mode_c2) ? (bottom_03_raddr)  :  (top_03_raddr);//左上角最近邻位于奇数行模式下，奇数bram中对应的是底部的数据
assign    odd_04_raddr     =  (~bram_mode_c2) ? (bottom_04_raddr)  :  (top_04_raddr);//左上角最近邻位于奇数行模式下，奇数bram中对应的是底部的数据

assign    even_01_raddr    =  (~bram_mode_c2) ? (top_01_raddr) : (bottom_01_raddr);//左上角最近邻位于偶数数行模式下，偶数数bram中对应的是顶部的数据
assign    even_02_raddr    =  (~bram_mode_c2) ? (top_02_raddr) : (bottom_02_raddr);//左上角最近邻位于偶数数行模式下，偶数数bram中对应的是顶部的数据
assign    even_03_raddr    =  (~bram_mode_c2) ? (top_03_raddr) : (bottom_03_raddr);//左上角最近邻位于偶数数行模式下，偶数数bram中对应的是顶部的数据
assign    even_04_raddr    =  (~bram_mode_c2) ? (top_04_raddr) : (bottom_04_raddr);//左上角最近邻位于偶数数行模式下，偶数数bram中对应的是顶部的数据





////








///////////////////////////////////////////////////////////////////////////////////////////////////////////



reg             [16:0]          x_fra_c3;
reg             [16:0]          y_fra_c3;


reg                             bram_mode_c3;
reg                             right_pixel_extand_flag_c3;
reg                             bottom_pixel_extand_flag_c3;

//打拍
always @(posedge clk_in2)
begin
    x_fra_c3     <= x_fra_c2;
    y_fra_c3     <= y_fra_c2;
    bram_mode_c3                <= bram_mode_c2;
    right_pixel_extand_flag_c3  <= right_pixel_extand_flag_c2;
    bottom_pixel_extand_flag_c3 <= bottom_pixel_extand_flag_c2;
end

//----------------------------------------------------------------------
//  c4
reg                             img_vs_c4;
reg                             img_hs_c4;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c4 <= 1'b0;
        img_hs_c4 <= 1'b0;
    end
    else
    begin
        img_vs_c4 <= img_vs_c3;
        img_hs_c4 <= img_hs_c3;
    end
end



reg             [16:0]          x_fra_c4;
reg             [16:0]          y_fra_c4;
reg                             bram_mode_c4;
reg                             right_pixel_extand_flag_c4;
reg                             bottom_pixel_extand_flag_c4;

always @(posedge clk_in2)
begin
    x_fra_c4     <= x_fra_c3;
    y_fra_c4     <= y_fra_c3;
    bram_mode_c4                <= bram_mode_c3;
    right_pixel_extand_flag_c4  <= right_pixel_extand_flag_c3;
    bottom_pixel_extand_flag_c4 <= bottom_pixel_extand_flag_c3;
end

//----------------------------------------------------------------------
//  c5
reg                             img_vs_c5;
reg                             img_hs_c5;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c5 <= 1'b0;
        img_hs_c5 <= 1'b0;
    end
    else
    begin
        img_vs_c5 <= img_vs_c4;
        img_hs_c5 <= img_hs_c4;
    end
end
//////////////////////////////////////////////////////////////////////////////////////////////
//重要！！！像素的获取
reg             [7:0]           pixel_data00_c5     ;
reg             [7:0]           pixel_data01_c5     ;
reg             [7:0]           pixel_data10_c5     ;
reg             [7:0]           pixel_data11_c5     ;
reg             [7:0]           toppix_01_data      ;
reg             [7:0]           toppix_02_data      ;
reg             [7:0]           toppix_03_data      ;
reg             [7:0]           toppix_04_data      ;
reg             [7:0]           bottompix_01_data   ;
reg             [7:0]           bottompix_02_data   ;
reg             [7:0]           bottompix_03_data   ;
reg             [7:0]           bottompix_04_data   ;
reg             [7:0]           pixel_data00_c5_left   ;
reg             [7:0]           pixel_data01_c5_right  ;
reg             [7:0]           pixel_data02_c5_left   ;
reg             [7:0]           pixel_data03_c5_right  ;


reg             [7:0]           green_pixel_data00_c5     ;
reg             [7:0]           green_pixel_data01_c5     ;
reg             [7:0]           green_pixel_data10_c5     ;
reg             [7:0]           green_pixel_data11_c5     ;
reg             [7:0]           green_toppix_01_data      ;
reg             [7:0]           green_toppix_02_data      ;
reg             [7:0]           green_toppix_03_data      ;
reg             [7:0]           green_toppix_04_data      ;
reg             [7:0]           green_bottompix_01_data   ;
reg             [7:0]           green_bottompix_02_data   ;
reg             [7:0]           green_bottompix_03_data   ;
reg             [7:0]           green_bottompix_04_data   ;
reg             [7:0]           green_pixel_data00_c5_left   ;
reg             [7:0]           green_pixel_data01_c5_right  ;
reg             [7:0]           green_pixel_data02_c5_left   ;
reg             [7:0]           green_pixel_data03_c5_right  ;


reg             [7:0]           blue_pixel_data00_c5     ;
reg             [7:0]           blue_pixel_data01_c5     ;
reg             [7:0]           blue_pixel_data10_c5     ;
reg             [7:0]           blue_pixel_data11_c5     ;
reg             [7:0]           blue_toppix_01_data      ;
reg             [7:0]           blue_toppix_02_data      ;
reg             [7:0]           blue_toppix_03_data      ;
reg             [7:0]           blue_toppix_04_data      ;
reg             [7:0]           blue_bottompix_01_data   ;
reg             [7:0]           blue_bottompix_02_data   ;
reg             [7:0]           blue_bottompix_03_data   ;
reg             [7:0]           blue_bottompix_04_data   ;
reg             [7:0]           blue_pixel_data00_c5_left   ;
reg             [7:0]           blue_pixel_data01_c5_right  ;
reg             [7:0]           blue_pixel_data02_c5_left   ;
reg             [7:0]           blue_pixel_data03_c5_right  ;


reg bram_mode_c5;

always@(posedge clk_in2) bram_mode_c5 <= bram_mode_c4;


always @(posedge clk_in2)
begin
    if(bram_mode_c5 == 1'b0)
    begin
        pixel_data00_c5        <= even_bram1_b_rdata;
        pixel_data01_c5        <= odd_bram1_b_rdata;
        pixel_data10_c5        <= even_bram2_b_rdata;
        pixel_data11_c5        <= odd_bram2_b_rdata;
        pixel_data00_c5_left   <= even_bram1_b_rdata_left_1;
        pixel_data01_c5_right  <= odd_bram1_b_rdata_right_1;
        pixel_data02_c5_left   <= even_bram2_b_rdata_left_1 ;
        pixel_data03_c5_right  <= odd_bram2_b_rdata_right_1 ;
        toppix_01_data         <= even_01_rdata;
        toppix_02_data         <= even_02_rdata;
        toppix_03_data         <= even_03_rdata;
        toppix_04_data         <= even_04_rdata;
        bottompix_01_data      <= odd_01_rdata;
        bottompix_02_data      <= odd_02_rdata;
        bottompix_03_data      <= odd_03_rdata;
        bottompix_04_data      <= odd_04_rdata;

        green_pixel_data00_c5        <= green_even_bram1_b_rdata;
        green_pixel_data01_c5        <= green_odd_bram1_b_rdata;
        green_pixel_data10_c5        <= green_even_bram2_b_rdata;
        green_pixel_data11_c5        <= green_odd_bram2_b_rdata;
        green_pixel_data00_c5_left   <= green_even_bram1_b_rdata_left_1;
        green_pixel_data01_c5_right  <= green_odd_bram1_b_rdata_right_1;
        green_pixel_data02_c5_left   <= green_even_bram2_b_rdata_left_1 ;
        green_pixel_data03_c5_right  <= green_odd_bram2_b_rdata_right_1 ;
        green_toppix_01_data         <= green_even_01_rdata;
        green_toppix_02_data         <= green_even_02_rdata;
        green_toppix_03_data         <= green_even_03_rdata;
        green_toppix_04_data         <= green_even_04_rdata;
        green_bottompix_01_data      <= green_odd_01_rdata;
        green_bottompix_02_data      <= green_odd_02_rdata;
        green_bottompix_03_data      <= green_odd_03_rdata;
        green_bottompix_04_data      <= green_odd_04_rdata;


        blue_pixel_data00_c5        <= blue_even_bram1_b_rdata;
        blue_pixel_data01_c5        <= blue_odd_bram1_b_rdata;
        blue_pixel_data10_c5        <= blue_even_bram2_b_rdata;
        blue_pixel_data11_c5        <= blue_odd_bram2_b_rdata;
        blue_pixel_data00_c5_left   <= blue_even_bram1_b_rdata_left_1;
        blue_pixel_data01_c5_right  <= blue_odd_bram1_b_rdata_right_1;
        blue_pixel_data02_c5_left   <= blue_even_bram2_b_rdata_left_1 ;
        blue_pixel_data03_c5_right  <= blue_odd_bram2_b_rdata_right_1 ;
        blue_toppix_01_data         <= blue_even_01_rdata;
        blue_toppix_02_data         <= blue_even_02_rdata;
        blue_toppix_03_data         <= blue_even_03_rdata;
        blue_toppix_04_data         <= blue_even_04_rdata;
        blue_bottompix_01_data      <= blue_odd_01_rdata;
        blue_bottompix_02_data      <= blue_odd_02_rdata;
        blue_bottompix_03_data      <= blue_odd_03_rdata;
        blue_bottompix_04_data      <= blue_odd_04_rdata;


    end
    else
    begin
        pixel_data00_c5        <= even_bram2_b_rdata;
        pixel_data01_c5        <= odd_bram2_b_rdata;
        pixel_data10_c5        <= even_bram1_b_rdata;
        pixel_data11_c5        <= odd_bram1_b_rdata;
        pixel_data00_c5_left   <= even_bram2_b_rdata_left_1 ;
        pixel_data01_c5_right  <= odd_bram2_b_rdata_right_1 ;
        pixel_data02_c5_left   <= even_bram1_b_rdata_left_1 ;
        pixel_data03_c5_right  <= odd_bram1_b_rdata_right_1 ;     
        toppix_01_data         <= odd_01_rdata;
        toppix_02_data         <= odd_02_rdata;
        toppix_03_data         <= odd_03_rdata;
        toppix_04_data         <= odd_04_rdata;
        bottompix_01_data      <= even_01_rdata;
        bottompix_02_data      <= even_02_rdata;
        bottompix_03_data      <= even_03_rdata;
        bottompix_04_data      <= even_04_rdata;

        green_pixel_data00_c5        <= green_even_bram2_b_rdata;
        green_pixel_data01_c5        <= green_odd_bram2_b_rdata;
        green_pixel_data10_c5        <= green_even_bram1_b_rdata;
        green_pixel_data11_c5        <= green_odd_bram1_b_rdata;
        green_pixel_data00_c5_left   <= green_even_bram2_b_rdata_left_1 ;
        green_pixel_data01_c5_right  <= green_odd_bram2_b_rdata_right_1 ;
        green_pixel_data02_c5_left   <= green_even_bram1_b_rdata_left_1 ;
        green_pixel_data03_c5_right  <= green_odd_bram1_b_rdata_right_1 ;     
        green_toppix_01_data         <= green_odd_01_rdata;
        green_toppix_02_data         <= green_odd_02_rdata;
        green_toppix_03_data         <= green_odd_03_rdata;
        green_toppix_04_data         <= green_odd_04_rdata;
        green_bottompix_01_data      <= green_even_01_rdata;
        green_bottompix_02_data      <= green_even_02_rdata;
        green_bottompix_03_data      <= green_even_03_rdata;
        green_bottompix_04_data      <= green_even_04_rdata;

        blue_pixel_data00_c5        <= blue_even_bram2_b_rdata;
        blue_pixel_data01_c5        <= blue_odd_bram2_b_rdata;
        blue_pixel_data10_c5        <= blue_even_bram1_b_rdata;
        blue_pixel_data11_c5        <= blue_odd_bram1_b_rdata;
        blue_pixel_data00_c5_left   <= blue_even_bram2_b_rdata_left_1 ;
        blue_pixel_data01_c5_right  <= blue_odd_bram2_b_rdata_right_1 ;
        blue_pixel_data02_c5_left   <= blue_even_bram1_b_rdata_left_1 ;
        blue_pixel_data03_c5_right  <= blue_odd_bram1_b_rdata_right_1 ;     
        blue_toppix_01_data         <= blue_odd_01_rdata;
        blue_toppix_02_data         <= blue_odd_02_rdata;
        blue_toppix_03_data         <= blue_odd_03_rdata;
        blue_toppix_04_data         <= blue_odd_04_rdata;
        blue_bottompix_01_data      <= blue_even_01_rdata;
        blue_bottompix_02_data      <= blue_even_02_rdata;
        blue_bottompix_03_data      <= blue_even_03_rdata;
        blue_bottompix_04_data      <= blue_even_04_rdata;

         
    end
end



reg             [16:0]          x_fra_c5;
reg             [16:0]          y_fra_c5;

reg                             right_pixel_extand_flag_c5;
reg                             bottom_pixel_extand_flag_c5;
reg                             right_pixel_extand_flag_c6;
reg                             bottom_pixel_extand_flag_c6;

///////////////////////////////////////////////////////////////////////



always @(posedge clk_in2)
begin
    x_fra_c5     <= x_fra_c4;
    y_fra_c5     <= y_fra_c4;
    right_pixel_extand_flag_c5  <= right_pixel_extand_flag_c4 ;
    bottom_pixel_extand_flag_c5 <= bottom_pixel_extand_flag_c4;
    right_pixel_extand_flag_c6  <= right_pixel_extand_flag_c5 ;
    bottom_pixel_extand_flag_c6 <= bottom_pixel_extand_flag_c5;
end

//----------------------------------------------------------------------
//  c6
reg                             img_vs_c6;
reg                             img_hs_c6;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c6 <= 1'b0;
        img_hs_c6 <= 1'b0;
    end
    else
    begin
        img_vs_c6 <= img_vs_c5;
        img_hs_c6 <= img_hs_c5;
    end
end




reg             [7:0]           pixel_data00_c6;
reg             [7:0]           pixel_data01_c6;
reg             [7:0]           pixel_data10_c6;
reg             [7:0]           pixel_data11_c6;
reg             [7:0]           pixel_data00_c5_left_c6; 
reg             [7:0]           pixel_data01_c5_right_c6;
reg             [7:0]           pixel_data02_c5_left_c6;
reg             [7:0]           pixel_data03_c5_right_c6;
reg             [7:0]           toppix_01_data_c6;       
reg             [7:0]           toppix_02_data_c6;       
reg             [7:0]           toppix_03_data_c6;       
reg             [7:0]           toppix_04_data_c6;       
reg             [7:0]           bottompix_01_data_c6;    
reg             [7:0]           bottompix_02_data_c6;    
reg             [7:0]           bottompix_03_data_c6;    
reg             [7:0]           bottompix_04_data_c6;               
           
           

reg             [7:0]           green_pixel_data00_c6;
reg             [7:0]           green_pixel_data01_c6;
reg             [7:0]           green_pixel_data10_c6;
reg             [7:0]           green_pixel_data11_c6;
reg             [7:0]           green_pixel_data00_c5_left_c6; 
reg             [7:0]           green_pixel_data01_c5_right_c6;
reg             [7:0]           green_pixel_data02_c5_left_c6;
reg             [7:0]           green_pixel_data03_c5_right_c6;
reg             [7:0]           green_toppix_01_data_c6;       
reg             [7:0]           green_toppix_02_data_c6;       
reg             [7:0]           green_toppix_03_data_c6;       
reg             [7:0]           green_toppix_04_data_c6;       
reg             [7:0]           green_bottompix_01_data_c6;    
reg             [7:0]           green_bottompix_02_data_c6;    
reg             [7:0]           green_bottompix_03_data_c6;    
reg             [7:0]           green_bottompix_04_data_c6;                          
           
           

reg             [7:0]           blue_pixel_data00_c6;
reg             [7:0]           blue_pixel_data01_c6;
reg             [7:0]           blue_pixel_data10_c6;
reg             [7:0]           blue_pixel_data11_c6;
reg             [7:0]           blue_pixel_data00_c5_left_c6; 
reg             [7:0]           blue_pixel_data01_c5_right_c6;
reg             [7:0]           blue_pixel_data02_c5_left_c6;
reg             [7:0]           blue_pixel_data03_c5_right_c6;
reg             [7:0]           blue_toppix_01_data_c6;       
reg             [7:0]           blue_toppix_02_data_c6;       
reg             [7:0]           blue_toppix_03_data_c6;       
reg             [7:0]           blue_toppix_04_data_c6;       
reg             [7:0]           blue_bottompix_01_data_c6;    
reg             [7:0]           blue_bottompix_02_data_c6;    
reg             [7:0]           blue_bottompix_03_data_c6;    
reg             [7:0]           blue_bottompix_04_data_c6;                          
           


always @(posedge clk_in2)
begin
    case({right_pixel_extand_flag_c6,bottom_pixel_extand_flag_c6})//如果在边缘，则直接复制，不进行差值运算
        2'b00 : 
        begin
            pixel_data00_c6             <=          pixel_data00_c5         ;
            pixel_data01_c6             <=          pixel_data01_c5         ;
            pixel_data10_c6             <=          pixel_data10_c5         ;
            pixel_data11_c6             <=          pixel_data11_c5         ;
            pixel_data00_c5_left_c6     <=          pixel_data00_c5_left    ;
            pixel_data01_c5_right_c6     <=         pixel_data01_c5_right   ;
            pixel_data02_c5_left_c6     <=          pixel_data02_c5_left    ;
            pixel_data03_c5_right_c6     <=         pixel_data03_c5_right   ;
            toppix_01_data_c6           <=          toppix_01_data          ;
            toppix_02_data_c6           <=          toppix_02_data          ;
            toppix_03_data_c6           <=          toppix_03_data          ;
            toppix_04_data_c6           <=          toppix_04_data          ;
            bottompix_01_data_c6        <=          bottompix_01_data       ;
            bottompix_02_data_c6        <=          bottompix_02_data       ;
            bottompix_03_data_c6        <=          bottompix_03_data       ;
            bottompix_04_data_c6        <=          bottompix_04_data       ;

            green_pixel_data00_c6             <=          green_pixel_data00_c5         ;
            green_pixel_data01_c6             <=          green_pixel_data01_c5         ;
            green_pixel_data10_c6             <=          green_pixel_data10_c5         ;
            green_pixel_data11_c6             <=          green_pixel_data11_c5         ;
            green_pixel_data00_c5_left_c6     <=          green_pixel_data00_c5_left    ;
            green_pixel_data01_c5_right_c6     <=         green_pixel_data01_c5_right   ;
            green_pixel_data02_c5_left_c6     <=          green_pixel_data02_c5_left    ;
            green_pixel_data03_c5_right_c6     <=         green_pixel_data03_c5_right   ;
            green_toppix_01_data_c6           <=          green_toppix_01_data          ;
            green_toppix_02_data_c6           <=          green_toppix_02_data          ;
            green_toppix_03_data_c6           <=          green_toppix_03_data          ;
            green_toppix_04_data_c6           <=          green_toppix_04_data          ;
            green_bottompix_01_data_c6        <=          green_bottompix_01_data       ;
            green_bottompix_02_data_c6        <=          green_bottompix_02_data       ;
            green_bottompix_03_data_c6        <=          green_bottompix_03_data       ;
            green_bottompix_04_data_c6        <=          green_bottompix_04_data       ;

            blue_pixel_data00_c6             <=          blue_pixel_data00_c5         ;
            blue_pixel_data01_c6             <=          blue_pixel_data01_c5         ;
            blue_pixel_data10_c6             <=          blue_pixel_data10_c5         ;
            blue_pixel_data11_c6             <=          blue_pixel_data11_c5         ;
            blue_pixel_data00_c5_left_c6     <=          blue_pixel_data00_c5_left    ;
            blue_pixel_data01_c5_right_c6     <=         blue_pixel_data01_c5_right   ;
            blue_pixel_data02_c5_left_c6     <=          blue_pixel_data02_c5_left    ;
            blue_pixel_data03_c5_right_c6     <=         blue_pixel_data03_c5_right   ;
            blue_toppix_01_data_c6           <=          blue_toppix_01_data          ;
            blue_toppix_02_data_c6           <=          blue_toppix_02_data          ;
            blue_toppix_03_data_c6           <=          blue_toppix_03_data          ;
            blue_toppix_04_data_c6           <=          blue_toppix_04_data          ;
            blue_bottompix_01_data_c6        <=          blue_bottompix_01_data       ;
            blue_bottompix_02_data_c6        <=          blue_bottompix_02_data       ;
            blue_bottompix_03_data_c6        <=          blue_bottompix_03_data       ;
            blue_bottompix_04_data_c6        <=          blue_bottompix_04_data       ;












        end
        2'b01 : 
        begin
            pixel_data00_c6 <=                      pixel_data00_c5;
            pixel_data01_c6 <=                      pixel_data01_c5;
            pixel_data10_c6 <=                      pixel_data00_c5;
            pixel_data11_c6 <=                      pixel_data01_c5;
            pixel_data00_c5_left_c6     <=          pixel_data00_c5_left    ;
            pixel_data01_c5_right_c6    <=          pixel_data01_c5_right   ;
            pixel_data02_c5_left_c6     <=          pixel_data00_c5_left    ;
            pixel_data03_c5_right_c6    <=          pixel_data01_c5_right   ;
            toppix_01_data_c6           <=          toppix_01_data          ;
            toppix_02_data_c6           <=          toppix_02_data          ;
            toppix_03_data_c6           <=          toppix_03_data          ;
            toppix_04_data_c6           <=          toppix_04_data          ;
            bottompix_01_data_c6        <=          toppix_01_data       ;
            bottompix_02_data_c6        <=          toppix_02_data       ;
            bottompix_03_data_c6        <=          toppix_03_data       ;
            bottompix_04_data_c6        <=          toppix_04_data       ;

            green_pixel_data00_c6 <=                      green_pixel_data00_c5;
            green_pixel_data01_c6 <=                      green_pixel_data01_c5;
            green_pixel_data10_c6 <=                      green_pixel_data00_c5;
            green_pixel_data11_c6 <=                      green_pixel_data01_c5;
            green_pixel_data00_c5_left_c6     <=          green_pixel_data00_c5_left    ;
            green_pixel_data01_c5_right_c6    <=          green_pixel_data01_c5_right   ;
            green_pixel_data02_c5_left_c6     <=          green_pixel_data00_c5_left    ;
            green_pixel_data03_c5_right_c6    <=          green_pixel_data01_c5_right   ;
            green_toppix_01_data_c6           <=          green_toppix_01_data          ;
            green_toppix_02_data_c6           <=          green_toppix_02_data          ;
            green_toppix_03_data_c6           <=          green_toppix_03_data          ;
            green_toppix_04_data_c6           <=          green_toppix_04_data          ;
            green_bottompix_01_data_c6        <=          green_toppix_01_data       ;
            green_bottompix_02_data_c6        <=          green_toppix_02_data       ;
            green_bottompix_03_data_c6        <=          green_toppix_03_data       ;
            green_bottompix_04_data_c6        <=          green_toppix_04_data       ;


            blue_pixel_data00_c6 <=                      blue_pixel_data00_c5;
            blue_pixel_data01_c6 <=                      blue_pixel_data01_c5;
            blue_pixel_data10_c6 <=                      blue_pixel_data00_c5;
            blue_pixel_data11_c6 <=                      blue_pixel_data01_c5;
            blue_pixel_data00_c5_left_c6     <=          blue_pixel_data00_c5_left    ;
            blue_pixel_data01_c5_right_c6    <=          blue_pixel_data01_c5_right   ;
            blue_pixel_data02_c5_left_c6     <=          blue_pixel_data00_c5_left    ;
            blue_pixel_data03_c5_right_c6    <=          blue_pixel_data01_c5_right   ;
            blue_toppix_01_data_c6           <=          blue_toppix_01_data          ;
            blue_toppix_02_data_c6           <=          blue_toppix_02_data          ;
            blue_toppix_03_data_c6           <=          blue_toppix_03_data          ;
            blue_toppix_04_data_c6           <=          blue_toppix_04_data          ;
            blue_bottompix_01_data_c6        <=          blue_toppix_01_data       ;
            blue_bottompix_02_data_c6        <=          blue_toppix_02_data       ;
            blue_bottompix_03_data_c6        <=          blue_toppix_03_data       ;
            blue_bottompix_04_data_c6        <=          blue_toppix_04_data       ;




        end
        2'b10 : 
        begin
            pixel_data00_c6             <=          pixel_data00_c5;
            pixel_data01_c6             <=          pixel_data00_c5;
            pixel_data10_c6             <=          pixel_data10_c5;
            pixel_data11_c6             <=          pixel_data10_c5;
            pixel_data00_c5_left_c6     <=          pixel_data00_c5_left    ;
            pixel_data01_c5_right_c6    <=          pixel_data00_c5_left   ;
            pixel_data02_c5_left_c6     <=          pixel_data02_c5_left    ;
            pixel_data03_c5_right_c6    <=          pixel_data02_c5_left   ;
            toppix_01_data_c6           <=          toppix_01_data   ;
            toppix_02_data_c6           <=          toppix_02_data   ;
            toppix_03_data_c6           <=          toppix_02_data   ;
            toppix_04_data_c6           <=          toppix_01_data   ;
            bottompix_01_data_c6        <=          bottompix_01_data   ;
            bottompix_02_data_c6        <=          bottompix_02_data   ;
            bottompix_03_data_c6        <=          bottompix_02_data   ;
            bottompix_04_data_c6        <=          bottompix_01_data   ;


            green_pixel_data00_c6             <=          green_pixel_data00_c5;
            green_pixel_data01_c6             <=          green_pixel_data00_c5;
            green_pixel_data10_c6             <=          green_pixel_data10_c5;
            green_pixel_data11_c6             <=          green_pixel_data10_c5;
            green_pixel_data00_c5_left_c6     <=          green_pixel_data00_c5_left    ;
            green_pixel_data01_c5_right_c6    <=          green_pixel_data00_c5_left   ;
            green_pixel_data02_c5_left_c6     <=          green_pixel_data02_c5_left    ;
            green_pixel_data03_c5_right_c6    <=          green_pixel_data02_c5_left   ;
            green_toppix_01_data_c6           <=          green_toppix_01_data   ;
            green_toppix_02_data_c6           <=          green_toppix_02_data   ;
            green_toppix_03_data_c6           <=          green_toppix_02_data   ;
            green_toppix_04_data_c6           <=          green_toppix_01_data   ;
            green_bottompix_01_data_c6        <=          green_bottompix_01_data   ;
            green_bottompix_02_data_c6        <=          green_bottompix_02_data   ;
            green_bottompix_03_data_c6        <=          green_bottompix_02_data   ;
            green_bottompix_04_data_c6        <=          green_bottompix_01_data   ;


            blue_pixel_data00_c6             <=          blue_pixel_data00_c5;
            blue_pixel_data01_c6             <=          blue_pixel_data00_c5;
            blue_pixel_data10_c6             <=          blue_pixel_data10_c5;
            blue_pixel_data11_c6             <=          blue_pixel_data10_c5;
            blue_pixel_data00_c5_left_c6     <=          blue_pixel_data00_c5_left    ;
            blue_pixel_data01_c5_right_c6    <=          blue_pixel_data00_c5_left   ;
            blue_pixel_data02_c5_left_c6     <=          blue_pixel_data02_c5_left    ;
            blue_pixel_data03_c5_right_c6    <=          blue_pixel_data02_c5_left   ;
            blue_toppix_01_data_c6           <=          blue_toppix_01_data   ;
            blue_toppix_02_data_c6           <=          blue_toppix_02_data   ;
            blue_toppix_03_data_c6           <=          blue_toppix_02_data   ;
            blue_toppix_04_data_c6           <=          blue_toppix_01_data   ;
            blue_bottompix_01_data_c6        <=          blue_bottompix_01_data   ;
            blue_bottompix_02_data_c6        <=          blue_bottompix_02_data   ;
            blue_bottompix_03_data_c6        <=          blue_bottompix_02_data   ;
            blue_bottompix_04_data_c6        <=          blue_bottompix_01_data   ;


        end
        2'b11 : //若左上角为左下角，则全部赋值左上角灰度值
        begin
            pixel_data00_c6             <=          pixel_data00_c5   ;
            pixel_data01_c6             <=          pixel_data00_c5   ;
            pixel_data10_c6             <=          pixel_data00_c5   ;
            pixel_data11_c6             <=          pixel_data00_c5   ;
            pixel_data00_c5_left_c6     <=          pixel_data00_c5   ;
            pixel_data01_c5_right_c6    <=          pixel_data00_c5   ;
            pixel_data02_c5_left_c6     <=          pixel_data00_c5   ;
            pixel_data03_c5_right_c6    <=          pixel_data00_c5   ;
            toppix_01_data_c6           <=          pixel_data00_c5   ;
            toppix_02_data_c6           <=          pixel_data00_c5   ;
            toppix_03_data_c6           <=          pixel_data00_c5   ;
            toppix_04_data_c6           <=          pixel_data00_c5   ;
            bottompix_01_data_c6        <=          pixel_data00_c5   ;
            bottompix_02_data_c6        <=          pixel_data00_c5   ;
            bottompix_03_data_c6        <=          pixel_data00_c5   ;
            bottompix_04_data_c6        <=          pixel_data00_c5   ;


            green_pixel_data00_c6             <=          green_pixel_data00_c5   ;
            green_pixel_data01_c6             <=          green_pixel_data00_c5   ;
            green_pixel_data10_c6             <=          green_pixel_data00_c5   ;
            green_pixel_data11_c6             <=          green_pixel_data00_c5   ;
            green_pixel_data00_c5_left_c6     <=          green_pixel_data00_c5   ;
            green_pixel_data01_c5_right_c6    <=          green_pixel_data00_c5   ;
            green_pixel_data02_c5_left_c6     <=          green_pixel_data00_c5   ;
            green_pixel_data03_c5_right_c6    <=          green_pixel_data00_c5   ;
            green_toppix_01_data_c6           <=          green_pixel_data00_c5   ;
            green_toppix_02_data_c6           <=          green_pixel_data00_c5   ;
            green_toppix_03_data_c6           <=          green_pixel_data00_c5   ;
            green_toppix_04_data_c6           <=          green_pixel_data00_c5   ;
            green_bottompix_01_data_c6        <=          green_pixel_data00_c5   ;
            green_bottompix_02_data_c6        <=          green_pixel_data00_c5   ;
            green_bottompix_03_data_c6        <=          green_pixel_data00_c5   ;
            green_bottompix_04_data_c6        <=          green_pixel_data00_c5   ;


            blue_pixel_data00_c6             <=          blue_pixel_data00_c5   ;
            blue_pixel_data01_c6             <=          blue_pixel_data00_c5   ;
            blue_pixel_data10_c6             <=          blue_pixel_data00_c5   ;
            blue_pixel_data11_c6             <=          blue_pixel_data00_c5   ;
            blue_pixel_data00_c5_left_c6     <=          blue_pixel_data00_c5   ;
            blue_pixel_data01_c5_right_c6    <=          blue_pixel_data00_c5   ;
            blue_pixel_data02_c5_left_c6     <=          blue_pixel_data00_c5   ;
            blue_pixel_data03_c5_right_c6    <=          blue_pixel_data00_c5   ;
            blue_toppix_01_data_c6           <=          blue_pixel_data00_c5   ;
            blue_toppix_02_data_c6           <=          blue_pixel_data00_c5   ;
            blue_toppix_03_data_c6           <=          blue_pixel_data00_c5   ;
            blue_toppix_04_data_c6           <=          blue_pixel_data00_c5   ;
            blue_bottompix_01_data_c6        <=          blue_pixel_data00_c5   ;
            blue_bottompix_02_data_c6        <=          blue_pixel_data00_c5   ;
            blue_bottompix_03_data_c6        <=          blue_pixel_data00_c5   ;
            blue_bottompix_04_data_c6        <=          blue_pixel_data00_c5   ;


        end
    endcase
end

wire      [127:0]    data_delay;
reg       [127:0]    data_delay_1;
reg       [127:0]    data_delay_2;
reg       [127:0]    data_delay_3;
reg       [127:0]    data_delay_4;
reg       [127:0]    data_delay_5;
reg       [127:0]    data_delay_6;
reg       [127:0]    data_delay_7;
reg       [127:0]    data_delay_8;
reg       [127:0]    data_delay_9;
reg       [127:0]    data_delay_10;
reg       [127:0]    data_delay_11;

wire      [127:0]    green_data_delay;
reg       [127:0]    green_data_delay_1;
reg       [127:0]    green_data_delay_2;
reg       [127:0]    green_data_delay_3;
reg       [127:0]    green_data_delay_4;
reg       [127:0]    green_data_delay_5;
reg       [127:0]    green_data_delay_6;
reg       [127:0]    green_data_delay_7;
reg       [127:0]    green_data_delay_8;
reg       [127:0]    green_data_delay_9;
reg       [127:0]    green_data_delay_10;
reg       [127:0]    green_data_delay_11;


wire      [127:0]    blue_data_delay;
reg       [127:0]    blue_data_delay_1;
reg       [127:0]    blue_data_delay_2;
reg       [127:0]    blue_data_delay_3;
reg       [127:0]    blue_data_delay_4;
reg       [127:0]    blue_data_delay_5;
reg       [127:0]    blue_data_delay_6;
reg       [127:0]    blue_data_delay_7;
reg       [127:0]    blue_data_delay_8;
reg       [127:0]    blue_data_delay_9;
reg       [127:0]    blue_data_delay_10;


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//打11拍

assign  data_delay ={toppix_01_data_c6,toppix_02_data_c6,toppix_03_data_c6,toppix_04_data_c6,pixel_data00_c5_left_c6,pixel_data00_c6,pixel_data01_c6,pixel_data01_c5_right_c6,pixel_data02_c5_left_c6,pixel_data10_c6,pixel_data11_c6,pixel_data03_c5_right_c6,bottompix_01_data_c6,bottompix_02_data_c6,bottompix_03_data_c6,bottompix_04_data_c6};    
assign  green_data_delay ={green_toppix_01_data_c6,green_toppix_02_data_c6,green_toppix_03_data_c6,green_toppix_04_data_c6,green_pixel_data00_c5_left_c6,green_pixel_data00_c6,green_pixel_data01_c6,green_pixel_data01_c5_right_c6,green_pixel_data02_c5_left_c6,green_pixel_data10_c6,green_pixel_data11_c6,green_pixel_data03_c5_right_c6,green_bottompix_01_data_c6,green_bottompix_02_data_c6,green_bottompix_03_data_c6,green_bottompix_04_data_c6};
assign  blue_data_delay ={blue_toppix_01_data_c6,blue_toppix_02_data_c6,blue_toppix_03_data_c6,blue_toppix_04_data_c6,blue_pixel_data00_c5_left_c6,blue_pixel_data00_c6,blue_pixel_data01_c6,blue_pixel_data01_c5_right_c6,blue_pixel_data02_c5_left_c6,blue_pixel_data10_c6,blue_pixel_data11_c6,blue_pixel_data03_c5_right_c6,blue_bottompix_01_data_c6,blue_bottompix_02_data_c6,blue_bottompix_03_data_c6,blue_bottompix_04_data_c6};



always @(posedge clk_in2)
begin
    data_delay_1 <= data_delay;
    green_data_delay_1 <= green_data_delay; 
    blue_data_delay_1 <= blue_data_delay;      
end

always @(posedge clk_in2)
begin
    data_delay_2 <= data_delay_1;
    green_data_delay_2 <= green_data_delay_1; 
    blue_data_delay_2 <= blue_data_delay_1;      
end

always @(posedge clk_in2)
begin
    data_delay_3 <= data_delay_2;
    green_data_delay_3 <= green_data_delay_2; 
    blue_data_delay_3 <= blue_data_delay_2;      
end

always @(posedge clk_in2)
begin
    data_delay_4 <= data_delay_3;
    green_data_delay_4 <= green_data_delay_3; 
    blue_data_delay_4 <= blue_data_delay_3;      
end

always @(posedge clk_in2)
begin
    data_delay_5 <= data_delay_4;
    green_data_delay_5 <= green_data_delay_4; 
    blue_data_delay_5 <= blue_data_delay_4;      
end

always @(posedge clk_in2)
begin
    data_delay_6 <= data_delay_5;
    green_data_delay_6 <= green_data_delay_5; 
    blue_data_delay_6 <= blue_data_delay_5;      
end

always @(posedge clk_in2)
begin
    data_delay_7 <= data_delay_6;
    green_data_delay_7 <= green_data_delay_6; 
    blue_data_delay_7 <= blue_data_delay_6;      
end

always @(posedge clk_in2)
begin
    data_delay_8 <= data_delay_7;
    green_data_delay_8 <= green_data_delay_7; 
    blue_data_delay_8 <= blue_data_delay_7;      
end

always @(posedge clk_in2)
begin
    data_delay_9 <= data_delay_8;
    green_data_delay_9 <= green_data_delay_8; 
    blue_data_delay_9 <= blue_data_delay_8;      
end

always @(posedge clk_in2)
begin
    data_delay_10 <= data_delay_9;
    green_data_delay_10 <= green_data_delay_9; 
    blue_data_delay_10 <= blue_data_delay_9;      
end




reg    [7:0]    pixel_data00_delay_11          ;
reg    [7:0]    pixel_data01_delay_11          ;
reg    [7:0]    pixel_data10_delay_11          ;
reg    [7:0]    pixel_data11_delay_11          ;
reg    [7:0]    pixel_data00_c5_left_delay_11  ;
reg    [7:0]    pixel_data01_c5_right_delay_11 ;
reg    [7:0]    pixel_data02_c5_left_delay_11  ;
reg    [7:0]    pixel_data03_c5_right_delay_11 ;
reg    [7:0]    toppix_01_data_delay_11        ;
reg    [7:0]    toppix_02_data_delay_11        ;
reg    [7:0]    toppix_03_data_delay_11        ;
reg    [7:0]    toppix_04_data_delay_11        ;
reg    [7:0]    bottompix_01_data_delay_11     ;
reg    [7:0]    bottompix_02_data_delay_11     ;
reg    [7:0]    bottompix_03_data_delay_11     ;
reg    [7:0]    bottompix_04_data_delay_11     ; 


reg    [7:0]    green_pixel_data00_delay_11          ;
reg    [7:0]    green_pixel_data01_delay_11          ;
reg    [7:0]    green_pixel_data10_delay_11          ;
reg    [7:0]    green_pixel_data11_delay_11          ;
reg    [7:0]    green_pixel_data00_c5_left_delay_11  ;
reg    [7:0]    green_pixel_data01_c5_right_delay_11 ;
reg    [7:0]    green_pixel_data02_c5_left_delay_11  ;
reg    [7:0]    green_pixel_data03_c5_right_delay_11 ;
reg    [7:0]    green_toppix_01_data_delay_11        ;
reg    [7:0]    green_toppix_02_data_delay_11        ;
reg    [7:0]    green_toppix_03_data_delay_11        ;
reg    [7:0]    green_toppix_04_data_delay_11        ;
reg    [7:0]    green_bottompix_01_data_delay_11     ;
reg    [7:0]    green_bottompix_02_data_delay_11     ;
reg    [7:0]    green_bottompix_03_data_delay_11     ;
reg    [7:0]    green_bottompix_04_data_delay_11     ;


reg    [7:0]    blue_pixel_data00_delay_11          ;
reg    [7:0]    blue_pixel_data01_delay_11          ;
reg    [7:0]    blue_pixel_data10_delay_11          ;
reg    [7:0]    blue_pixel_data11_delay_11          ;
reg    [7:0]    blue_pixel_data00_c5_left_delay_11  ;
reg    [7:0]    blue_pixel_data01_c5_right_delay_11 ;
reg    [7:0]    blue_pixel_data02_c5_left_delay_11  ;
reg    [7:0]    blue_pixel_data03_c5_right_delay_11 ;
reg    [7:0]    blue_toppix_01_data_delay_11        ;
reg    [7:0]    blue_toppix_02_data_delay_11        ;
reg    [7:0]    blue_toppix_03_data_delay_11        ;
reg    [7:0]    blue_toppix_04_data_delay_11        ;
reg    [7:0]    blue_bottompix_01_data_delay_11     ;
reg    [7:0]    blue_bottompix_02_data_delay_11     ;
reg    [7:0]    blue_bottompix_03_data_delay_11     ;
reg    [7:0]    blue_bottompix_04_data_delay_11     ;




always @(posedge clk_in2)
begin
        toppix_01_data_delay_11            <=    data_delay_10[127:120];
        toppix_02_data_delay_11            <=    data_delay_10[119:112];
        toppix_03_data_delay_11            <=    data_delay_10[111:104];
        toppix_04_data_delay_11            <=    data_delay_10[103:96];
        pixel_data00_c5_left_delay_11      <=    data_delay_10[95:88];
        pixel_data00_delay_11              <=    data_delay_10[87:80];
        pixel_data01_delay_11              <=    data_delay_10[79:72];
        pixel_data01_c5_right_delay_11     <=    data_delay_10[71:64];
        pixel_data02_c5_left_delay_11      <=    data_delay_10[63:56];
        pixel_data10_delay_11              <=    data_delay_10[55:48];
        pixel_data11_delay_11              <=    data_delay_10[47:40];
        pixel_data03_c5_right_delay_11     <=    data_delay_10[39:32];
        bottompix_01_data_delay_11         <=    data_delay_10[31:24];
        bottompix_02_data_delay_11         <=    data_delay_10[23:16];
        bottompix_03_data_delay_11         <=    data_delay_10[15:8];
        bottompix_04_data_delay_11         <=    data_delay_10[7:0];

        green_toppix_01_data_delay_11            <=    green_data_delay_10[127:120];
        green_toppix_02_data_delay_11            <=    green_data_delay_10[119:112];
        green_toppix_03_data_delay_11            <=    green_data_delay_10[111:104];
        green_toppix_04_data_delay_11            <=    green_data_delay_10[103:96];
        green_pixel_data00_c5_left_delay_11      <=    green_data_delay_10[95:88];
        green_pixel_data00_delay_11              <=    green_data_delay_10[87:80];
        green_pixel_data01_delay_11              <=    green_data_delay_10[79:72];
        green_pixel_data01_c5_right_delay_11     <=    green_data_delay_10[71:64];
        green_pixel_data02_c5_left_delay_11      <=    green_data_delay_10[63:56];
        green_pixel_data10_delay_11              <=    green_data_delay_10[55:48];
        green_pixel_data11_delay_11              <=    green_data_delay_10[47:40];
        green_pixel_data03_c5_right_delay_11     <=    green_data_delay_10[39:32];
        green_bottompix_01_data_delay_11         <=    green_data_delay_10[31:24];
        green_bottompix_02_data_delay_11         <=    green_data_delay_10[23:16];
        green_bottompix_03_data_delay_11         <=    green_data_delay_10[15:8];
        green_bottompix_04_data_delay_11         <=    green_data_delay_10[7:0];


        blue_toppix_01_data_delay_11            <=    blue_data_delay_10[127:120];
        blue_toppix_02_data_delay_11            <=    blue_data_delay_10[119:112];
        blue_toppix_03_data_delay_11            <=    blue_data_delay_10[111:104];
        blue_toppix_04_data_delay_11            <=    blue_data_delay_10[103:96];
        blue_pixel_data00_c5_left_delay_11      <=    blue_data_delay_10[95:88];
        blue_pixel_data00_delay_11              <=    blue_data_delay_10[87:80];
        blue_pixel_data01_delay_11              <=    blue_data_delay_10[79:72];
        blue_pixel_data01_c5_right_delay_11     <=    blue_data_delay_10[71:64];
        blue_pixel_data02_c5_left_delay_11      <=    blue_data_delay_10[63:56];
        blue_pixel_data10_delay_11              <=    blue_data_delay_10[55:48];
        blue_pixel_data11_delay_11              <=    blue_data_delay_10[47:40];
        blue_pixel_data03_c5_right_delay_11     <=    blue_data_delay_10[39:32];
        blue_bottompix_01_data_delay_11         <=    blue_data_delay_10[31:24];
        blue_bottompix_02_data_delay_11         <=    blue_data_delay_10[23:16];
        blue_bottompix_03_data_delay_11         <=    blue_data_delay_10[15:8];
        blue_bottompix_04_data_delay_11         <=    blue_data_delay_10[7:0];


end




reg             [16:0]          x_fra_c6;
reg             [16:0]          y_fra_c6;



always @(posedge clk_in2)
begin
    x_fra_c6     <= x_fra_c5;
    y_fra_c6     <= y_fra_c5;

end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//双立方差值开始
//xBlend = 
//计算X\Y坐标局部权重系数
localparam	FRACTION_BITS =			8;
localparam	COEFF_WIDTH =			FRACTION_BITS + 1;
localparam	DATA_WIDTH =			8;
localparam	CHANNELS =				1;


wire [COEFF_WIDTH-1:0]	coeffOne  = {1'b1, {(COEFF_WIDTH-1){1'b0}}};
//边长的一半(0.5<<8)
wire [COEFF_WIDTH-1:0]	coeffHalf = {2'b01, {(COEFF_WIDTH-2){1'b0}}};
//BiCubic函数a值(0.5<<8)
wire [COEFF_WIDTH-1:0]  bi_a      = {2'b01, {(COEFF_WIDTH-2){1'b0}}};

wire [COEFF_WIDTH-1:0]  xBlend = {1'b0,x_fra_c1[7:0]};
wire [COEFF_WIDTH-1:0]  yBlend = {1'b0,y_fra_c1[7:0]};
/*l*/

wire [COEFF_WIDTH-1:0]	coeff00_0;
wire [COEFF_WIDTH-1:0]	coeff01_0;
wire [COEFF_WIDTH-1:0]	coeff02_0;
wire [COEFF_WIDTH-1:0]	coeff03_0;
wire [COEFF_WIDTH-1:0]	coeff10_0;
wire [COEFF_WIDTH-1:0]	coeff11_0;
wire [COEFF_WIDTH-1:0]	coeff12_0;
wire [COEFF_WIDTH-1:0]	coeff13_0;
wire [COEFF_WIDTH-1:0]	coeff20_0;
wire [COEFF_WIDTH-1:0]	coeff21_0;
wire [COEFF_WIDTH-1:0]	coeff22_0;
wire [COEFF_WIDTH-1:0]	coeff23_0;
wire [COEFF_WIDTH-1:0]	coeff30_0;
wire [COEFF_WIDTH-1:0]	coeff31_0;
wire [COEFF_WIDTH-1:0]	coeff32_0;
wire [COEFF_WIDTH-1:0]	coeff33_0;

wire [COEFF_WIDTH-1:0]	bi_y0;
wire [COEFF_WIDTH-1:0]	bi_y1;
wire [COEFF_WIDTH-1:0]	bi_y2;
wire [COEFF_WIDTH-1:0]	bi_y3;
wire [COEFF_WIDTH-1:0]	bi_x0;
wire [COEFF_WIDTH-1:0]	bi_x1;
wire [COEFF_WIDTH-1:0]	bi_x2;
wire [COEFF_WIDTH-1:0]	bi_x3;


reg [COEFF_WIDTH*CHANNELS-1:0]                 dOut_shift;
reg [(DATA_WIDTH+COEFF_WIDTH+4)*CHANNELS-1:0]  dOut_sum;
reg [(DATA_WIDTH+COEFF_WIDTH+4)*CHANNELS-1:0]  dOut_add;
reg [(DATA_WIDTH+COEFF_WIDTH+4)*CHANNELS-1:0]  dOut_sub;
reg [(DATA_WIDTH+COEFF_WIDTH+3)*CHANNELS-1:0]  dOut_add_0;
reg [(DATA_WIDTH+COEFF_WIDTH+3)*CHANNELS-1:0]  dOut_add_1;
reg [(DATA_WIDTH+COEFF_WIDTH+3)*CHANNELS-1:0]  dOut_sub_0;
reg [(DATA_WIDTH+COEFF_WIDTH+3)*CHANNELS-1:0]  dOut_sub_1;


reg [COEFF_WIDTH*CHANNELS-1:0]                 green_dOut_shift;
reg [(DATA_WIDTH+COEFF_WIDTH+4)*CHANNELS-1:0]  green_dOut_sum;
reg [(DATA_WIDTH+COEFF_WIDTH+4)*CHANNELS-1:0]  green_dOut_add;
reg [(DATA_WIDTH+COEFF_WIDTH+4)*CHANNELS-1:0]  green_dOut_sub;
reg [(DATA_WIDTH+COEFF_WIDTH+3)*CHANNELS-1:0]  green_dOut_add_0;
reg [(DATA_WIDTH+COEFF_WIDTH+3)*CHANNELS-1:0]  green_dOut_add_1;
reg [(DATA_WIDTH+COEFF_WIDTH+3)*CHANNELS-1:0]  green_dOut_sub_0;
reg [(DATA_WIDTH+COEFF_WIDTH+3)*CHANNELS-1:0]  green_dOut_sub_1;



reg [COEFF_WIDTH*CHANNELS-1:0]                 blue_dOut_shift;
reg [(DATA_WIDTH+COEFF_WIDTH+4)*CHANNELS-1:0]  blue_dOut_sum;
reg [(DATA_WIDTH+COEFF_WIDTH+4)*CHANNELS-1:0]  blue_dOut_add;
reg [(DATA_WIDTH+COEFF_WIDTH+4)*CHANNELS-1:0]  blue_dOut_sub;
reg [(DATA_WIDTH+COEFF_WIDTH+3)*CHANNELS-1:0]  blue_dOut_add_0;
reg [(DATA_WIDTH+COEFF_WIDTH+3)*CHANNELS-1:0]  blue_dOut_add_1;
reg [(DATA_WIDTH+COEFF_WIDTH+3)*CHANNELS-1:0]  blue_dOut_sub_0;
reg [(DATA_WIDTH+COEFF_WIDTH+3)*CHANNELS-1:0]  blue_dOut_sub_1;

reg [DATA_WIDTH*CHANNELS-1:0]  dOut;
reg [DATA_WIDTH*CHANNELS-1:0]  green_dOut;
reg [DATA_WIDTH*CHANNELS-1:0]  blue_dOut;

BiCubic BiCubic_inst(
	.clk        (clk_in2),
	.rst_n      (rst_n),
	.coeffHalf  (coeffHalf),
	.coeffOne   (coeffOne),
	.yBlend     (yBlend),
	.bi_a       (bi_a),
	.xBlend     (xBlend),
	.bi_y0      (bi_y0),
	.bi_y1      (bi_y1),
	.bi_y2      (bi_y2),
	.bi_y3      (bi_y3),
	.bi_x0      (bi_x0),
	.bi_x1      (bi_x1),
	.bi_x2      (bi_x2),
	.bi_x3      (bi_x3)
);

//计算16个点权值系数
coefficient #(
	.FRACTION_BITS  (FRACTION_BITS),
	.COEFF_WIDTH    (COEFF_WIDTH)
)coefficient_inst(
	.clk        (clk_in2),
	.rst_n      (rst_n),
	.coeffHalf  (coeffHalf),
	.bi_y0      (bi_y0),
	.bi_y1      (bi_y1),
	.bi_y2      (bi_y2),
	.bi_y3      (bi_y3),
	.bi_x0      (bi_x0),
	.bi_x1      (bi_x1),
	.bi_x2      (bi_x2),
	.bi_x3      (bi_x3),
	.coeff00    (coeff00_0),
	.coeff01    (coeff01_0),
	.coeff02    (coeff02_0),
	.coeff03    (coeff03_0),
	.coeff10    (coeff10_0),
	.coeff11    (coeff11_0),
	.coeff12    (coeff12_0),
	.coeff13    (coeff13_0),
	.coeff20    (coeff20_0),
	.coeff21    (coeff21_0),
	.coeff22    (coeff22_0),
	.coeff23    (coeff23_0),
	.coeff30    (coeff30_0),
	.coeff31    (coeff31_0),
	.coeff32    (coeff32_0),
	.coeff33    (coeff33_0)
);





reg [(DATA_WIDTH+COEFF_WIDTH)*CHANNELS-1:0]	product00, product01, product02, product03,product10, product11, product12, product13,product20, product21, product22, product23,product30, product31, product32, product33;
reg [(DATA_WIDTH+COEFF_WIDTH)*CHANNELS-1:0]	green_product00, green_product01, green_product02, green_product03,green_product10, green_product11, green_product12, green_product13,green_product20, green_product21, green_product22, green_product23,green_product30, green_product31, green_product32, green_product33;
reg [(DATA_WIDTH+COEFF_WIDTH)*CHANNELS-1:0]	blue_product00, blue_product01, blue_product02, blue_product03,blue_product10, blue_product11, blue_product12, blue_product13,blue_product20, blue_product21, blue_product22, blue_product23,blue_product30, blue_product31, blue_product32, blue_product33;
generate
genvar channel;
	for(channel = 0; channel < CHANNELS; channel = channel + 1)
		begin : blend_mult_generate
			always @(posedge clk_in2 or posedge rst_n)
			begin
				if(!rst_n)
				begin
					//productxx[channel] <= 0;
					product00[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product01[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product02[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product03[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product10[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product11[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product12[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product13[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product20[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product21[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product22[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product23[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product30[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product31[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product32[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					product33[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
					dOut_add_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <= 0;
					dOut_add_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <= 0;
					dOut_sub_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <= 0;
					dOut_sub_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <= 0;
					dOut_add[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <= 0;
					dOut_sub[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <= 0;				
					dOut_sum[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <= 0;
					dOut_shift[ COEFF_WIDTH*(channel+1)-1 : COEFF_WIDTH*channel ] <= 0;
					dOut[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel]<= 0;
				
                    green_product00[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    green_product01[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    green_product02[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    green_product03[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    green_product10[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    green_product11[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    green_product12[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    green_product13[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    green_product20[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    green_product21[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    green_product22[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    green_product23[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    green_product30[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    green_product31[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    green_product32[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    green_product33[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    green_dOut_add_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <= 0;
                    green_dOut_add_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <= 0;
                    green_dOut_sub_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <= 0;
                    green_dOut_sub_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <= 0;
                    green_dOut_add[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <= 0;
                    green_dOut_sub[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <= 0;				
                    green_dOut_sum[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <= 0;
                    green_dOut_shift[ COEFF_WIDTH*(channel+1)-1 : COEFF_WIDTH*channel ] <= 0;
                    green_dOut[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel]<= 0;


                    blue_product00[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    blue_product01[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    blue_product02[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    blue_product03[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    blue_product10[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    blue_product11[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    blue_product12[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    blue_product13[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    blue_product20[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    blue_product21[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    blue_product22[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    blue_product23[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    blue_product30[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    blue_product31[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    blue_product32[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    blue_product33[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
                    blue_dOut_add_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <= 0;
                    blue_dOut_add_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <= 0;
                    blue_dOut_sub_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <= 0;
                    blue_dOut_sub_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <= 0;
                    blue_dOut_add[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <= 0;
                    blue_dOut_sub[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <= 0;				
                    blue_dOut_sum[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <= 0;
                    blue_dOut_shift[ COEFF_WIDTH*(channel+1)-1 : COEFF_WIDTH*channel ] <= 0;
                    blue_dOut[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel]<= 0;

				end
				else
				begin
					/* 
					                       >>>>>>>>>>列地址>>>>>>>>>>>
					           -------------------------------------------------
					  第0行   |readData00  | readData01 | readData02 |readData03|
	                ----------|------------|------------|------------|----------|
					  第1行   |readData10  | readData11 | readData12 |readData13|
					----------|------------|------------|------------|----------|
					  第2行	  |readData20  | readData21 | readData22 |readData23|
					----------|------------|------------|------------|----------|
					  第3行	  |readData30  | readData31 | readData32 |readData33|
							   -------------------------------------------------  
					*/
					//productxx[channel] <= readDataxx[channel] * coeffxx
					product00[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= toppix_01_data_delay_11        [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff00_0;
					product01[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= toppix_02_data_delay_11        [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff01_0;
					product02[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= toppix_03_data_delay_11        [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff02_0;
					product03[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= toppix_04_data_delay_11        [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff03_0;
					product10[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= pixel_data00_c5_left_delay_11  [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff10_0;
					product11[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= pixel_data00_delay_11          [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff11_0;
					product12[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= pixel_data01_delay_11          [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff12_0;
					product13[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= pixel_data01_c5_right_delay_11 [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff13_0;
					product20[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= pixel_data02_c5_left_delay_11  [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff20_0;
					product21[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= pixel_data10_delay_11          [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff21_0;
					product22[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= pixel_data11_delay_11          [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff22_0;
					product23[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= pixel_data03_c5_right_delay_11 [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff23_0;
					product30[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= bottompix_01_data_delay_11     [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff30_0;
					product31[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= bottompix_02_data_delay_11     [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff31_0;
					product32[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= bottompix_03_data_delay_11     [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff32_0;
					product33[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= bottompix_04_data_delay_11     [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff33_0;

					green_product00[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= green_toppix_01_data_delay_11        [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff00_0;
					green_product01[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= green_toppix_02_data_delay_11        [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff01_0;
					green_product02[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= green_toppix_03_data_delay_11        [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff02_0;
					green_product03[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= green_toppix_04_data_delay_11        [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff03_0;
					green_product10[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= green_pixel_data00_c5_left_delay_11  [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff10_0;
					green_product11[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= green_pixel_data00_delay_11          [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff11_0;
					green_product12[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= green_pixel_data01_delay_11          [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff12_0;
					green_product13[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= green_pixel_data01_c5_right_delay_11 [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff13_0;
					green_product20[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= green_pixel_data02_c5_left_delay_11  [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff20_0;
					green_product21[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= green_pixel_data10_delay_11          [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff21_0;
					green_product22[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= green_pixel_data11_delay_11          [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff22_0;
					green_product23[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= green_pixel_data03_c5_right_delay_11 [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff23_0;
					green_product30[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= green_bottompix_01_data_delay_11     [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff30_0;
					green_product31[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= green_bottompix_02_data_delay_11     [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff31_0;
					green_product32[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= green_bottompix_03_data_delay_11     [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff32_0;
					green_product33[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= green_bottompix_04_data_delay_11     [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff33_0;

					blue_product00[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= blue_toppix_01_data_delay_11        [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff00_0;
					blue_product01[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= blue_toppix_02_data_delay_11        [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff01_0;
					blue_product02[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= blue_toppix_03_data_delay_11        [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff02_0;
					blue_product03[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= blue_toppix_04_data_delay_11        [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff03_0;
					blue_product10[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= blue_pixel_data00_c5_left_delay_11  [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff10_0;
					blue_product11[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= blue_pixel_data00_delay_11          [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff11_0;
					blue_product12[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= blue_pixel_data01_delay_11          [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff12_0;
					blue_product13[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= blue_pixel_data01_c5_right_delay_11 [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff13_0;
					blue_product20[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= blue_pixel_data02_c5_left_delay_11  [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff20_0;
					blue_product21[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= blue_pixel_data10_delay_11          [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff21_0;
					blue_product22[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= blue_pixel_data11_delay_11          [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff22_0;
					blue_product23[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= blue_pixel_data03_c5_right_delay_11 [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff23_0;
					blue_product30[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= blue_bottompix_01_data_delay_11     [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff30_0;
					blue_product31[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= blue_bottompix_02_data_delay_11     [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff31_0;
					blue_product32[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= blue_bottompix_03_data_delay_11     [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff32_0;
					blue_product33[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel] <= blue_bottompix_04_data_delay_11     [ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel ] * coeff33_0;



					//局部正数部分和
					dOut_add_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <=
						(product00[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product03[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product11[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product12[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel]);
						
					//局部正数部分和
					dOut_add_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <=
						(product21[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product22[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product30[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product33[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel]);
						
					//局部负数部分和
					dOut_sub_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <=
						(product01[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product02[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product10[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product13[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel]);
						
					//局部负数部分和
					dOut_sub_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <=
						(product20[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product23[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product31[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
						(product32[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel]);
					

                    //局部正数部分和
                    green_dOut_add_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <=
                        (green_product00[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (green_product03[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (green_product11[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (green_product12[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel]);

                    //局部正数部分和
                    green_dOut_add_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <=
                        (green_product21[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (green_product22[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (green_product30[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (green_product33[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel]);

                    //局部负数部分和
                    green_dOut_sub_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <=
                        (green_product01[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (green_product02[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (green_product10[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (green_product13[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel]);

                    //局部负数部分和
                    green_dOut_sub_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <=
                        (green_product20[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (green_product23[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (green_product31[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (green_product32[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel]);



                    //局部正数部分和
                    blue_dOut_add_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <=
                        (blue_product00[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (blue_product03[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (blue_product11[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (blue_product12[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel]);

                    //局部正数部分和
                    blue_dOut_add_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <=
                        (blue_product21[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (blue_product22[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (blue_product30[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (blue_product33[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel]);

                    //局部负数部分和
                    blue_dOut_sub_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <=
                        (blue_product01[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (blue_product02[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (blue_product10[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (blue_product13[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel]);

                    //局部负数部分和
                    blue_dOut_sub_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] <=
                        (blue_product20[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (blue_product23[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (blue_product31[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel])+
                        (blue_product32[ (DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH)*channel]);


					//计算正数部分和
					dOut_add[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <=
						  dOut_add_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] + dOut_add_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ];
							
					//计算负数部分和
					dOut_sub[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <=
						  dOut_sub_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] + dOut_sub_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ];
					
					//计算加权和(正数部分和 - 负数部分和  or 负数部分和 - 正数部分和)
					dOut_sum[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <= (dOut_add[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] >= dOut_sub[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ]) ? dOut_add[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] - dOut_sub[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] : dOut_sub[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] - dOut_add[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ];
					
					//加权和结果移位
					dOut_shift[ COEFF_WIDTH*(channel+1)-1 : COEFF_WIDTH*channel ] <= (dOut_sum[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] >> 8) & ({ {(DATA_WIDTH+4){1'b0}}, {COEFF_WIDTH{1'b1}} });
					
					//最终结果异常判断(判断是否大于255,否则取低八位)
					dOut[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel]<= (dOut_shift[ COEFF_WIDTH*(channel+1)-1 : COEFF_WIDTH*channel] > 9'd255)? 8'd255 : dOut_shift[ COEFF_WIDTH*(channel+1)-2 : COEFF_WIDTH*channel];



					//计算正数部分和
					green_dOut_add[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <=
						  green_dOut_add_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] + green_dOut_add_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ];
							
					//计算负数部分和
					green_dOut_sub[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <=
						  green_dOut_sub_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] + green_dOut_sub_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ];
					
					//计算加权和(正数部分和 - 负数部分和  or 负数部分和 - 正数部分和)
					green_dOut_sum[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <= (green_dOut_add[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] >= green_dOut_sub[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ]) ? green_dOut_add[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] - green_dOut_sub[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] : green_dOut_sub[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] - green_dOut_add[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ];
					
					//加权和结果移位
					green_dOut_shift[ COEFF_WIDTH*(channel+1)-1 : COEFF_WIDTH*channel ] <= (green_dOut_sum[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] >> 8) & ({ {(DATA_WIDTH+4){1'b0}}, {COEFF_WIDTH{1'b1}} });
					
					//最终结果异常判断(判断是否大于255,否则取低八位)
					green_dOut[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel]<= (green_dOut_shift[ COEFF_WIDTH*(channel+1)-1 : COEFF_WIDTH*channel] > 9'd255)? 8'd255 : green_dOut_shift[ COEFF_WIDTH*(channel+1)-2 : COEFF_WIDTH*channel];




					//计算正数部分和
					blue_dOut_add[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <=
						  blue_dOut_add_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] + blue_dOut_add_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ];
							
					//计算负数部分和
					blue_dOut_sub[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <=
						  blue_dOut_sub_0[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ] + blue_dOut_sub_1[ (DATA_WIDTH+COEFF_WIDTH+3)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+3)*channel ];
					
					//计算加权和(正数部分和 - 负数部分和  or 负数部分和 - 正数部分和)
					blue_dOut_sum[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] <= (blue_dOut_add[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] >= blue_dOut_sub[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ]) ? blue_dOut_add[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] - blue_dOut_sub[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] : blue_dOut_sub[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] - blue_dOut_add[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ];
					
					//加权和结果移位
					blue_dOut_shift[ COEFF_WIDTH*(channel+1)-1 : COEFF_WIDTH*channel ] <= (blue_dOut_sum[ (DATA_WIDTH+COEFF_WIDTH+4)*(channel+1)-1 : (DATA_WIDTH+COEFF_WIDTH+4)*channel ] >> 8) & ({ {(DATA_WIDTH+4){1'b0}}, {COEFF_WIDTH{1'b1}} });
					
					//最终结果异常判断(判断是否大于255,否则取低八位)
					blue_dOut[ DATA_WIDTH*(channel+1)-1 : DATA_WIDTH*channel]<= (blue_dOut_shift[ COEFF_WIDTH*(channel+1)-1 : COEFF_WIDTH*channel] > 9'd255)? 8'd255 : blue_dOut_shift[ COEFF_WIDTH*(channel+1)-2 : COEFF_WIDTH*channel];

				end
			end
		end
endgenerate

assign    post_img_red  =  dOut ;
assign    post_img_green  =  green_dOut ;
assign    post_img_blue  =  blue_dOut ;

//////////////////重要！！！！！行场同步信号的打拍！！！！！！最终结果的限幅！！！！！！！！！！！！！！！！！！！！！

reg    [6:0]    img_hs_delay;
reg    [6:0]    img_vs_delay;


always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        post_img_vsync <= 1'b0;
        post_img_href  <= 1'b0;
    end
    else
    begin 
        img_vs_delay  <= {img_vs_delay[5:0],img_vs_c6};
        img_hs_delay  <= {img_hs_delay[5:0],img_hs_c6};
        post_img_vsync  <= img_vs_delay[5];
        post_img_href  <= img_hs_delay[5];
    end
end









endmodule