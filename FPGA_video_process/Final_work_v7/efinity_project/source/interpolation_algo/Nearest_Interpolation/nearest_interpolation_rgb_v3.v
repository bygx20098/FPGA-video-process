/*
v1:variable w/h
v2:add color
v3:even/odd bram
*/


module nearest_interpolation_rgb_v3
(
    input  wire     [10:0]      src_img_width   ,
    input  wire     [10:0]      src_img_height  ,
    input  wire     [10:0]      dst_img_width   ,
    input  wire     [10:0]      dst_img_height  ,
    input  wire     [15:0]      x_radio         ,
    input  wire     [15:0]      y_radio         ,   
    
    input  wire                 clk_in1         ,
    input  wire                 clk_in2         ,
    input  wire                 rst_n           ,
    
    //  Image data prepared to be processed
    input  wire                 per_img_vsync   ,       //  Prepared Image data vsync valid signal
    input  wire                 per_img_de      ,       //  Prepared Image data href vaild  signal
    input  wire     [7:0]       per_img_r       ,       //  Prepared Image brightness input
    input  wire     [7:0]       per_img_g       ,
    input  wire     [7:0]       per_img_b       ,
    
    //  Image data has been processed
    output reg                  post_img_vsync  ,       //  processed Image data vsync valid signal
    output reg                  post_img_de     ,       //  processed Image data href vaild  signal
    output reg      [7:0]       post_img_r      ,       //  processed Image brightness output
    output reg      [7:0]       post_img_g      ,
    output reg      [7:0]       post_img_b
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

reg             [10:0]          img_vs_cnt;                             //  from 0 to src_img_height - 1

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

reg             [10:0]          img_hs_cnt;                             //  from 0 to src_img_width - 1

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
reg             [7:0]           bram_a_wdata_r;
reg             [7:0]           bram_a_wdata_g;
reg             [7:0]           bram_a_wdata_b;

always @(posedge clk_in1)
begin
    bram_a_wdata_r <= per_img_r;
    bram_a_wdata_g <= per_img_g;
    bram_a_wdata_b <= per_img_b;
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
        if((per_img_vsync == 1'b1)&&(per_img_de == 1'b1)&&(img_hs_cnt == src_img_width - 1'b1))
            fifo_wenb <= 1'b1;
        else
            fifo_wenb <= 1'b0;
    end
end

//----------------------------------------------------------------------
//  bram & fifo rw
reg             [11:0]          even_bram1_raddr;
reg             [11:0]          odd_bram1_raddr;
reg             [11:0]          even_bram2_raddr;
reg             [11:0]          odd_bram2_raddr;
wire            [ 7:0]          even_bram1_r_rdata;
wire            [ 7:0]          odd_bram1_r_rdata;
wire            [ 7:0]          even_bram2_r_rdata;
wire            [ 7:0]          odd_bram2_r_rdata;
wire            [ 7:0]          even_bram1_g_rdata;
wire            [ 7:0]          odd_bram1_g_rdata;
wire            [ 7:0]          even_bram2_g_rdata;
wire            [ 7:0]          odd_bram2_g_rdata;
wire            [ 7:0]          even_bram1_b_rdata;
wire            [ 7:0]          odd_bram1_b_rdata;
wire            [ 7:0]          even_bram2_b_rdata;
wire            [ 7:0]          odd_bram2_b_rdata;

/*---------------------------------------------
-----------------RED---------------------------
-----------------------------------------------*/
bram_asymmetric_r2_w1_port   //输出起点1
#(
    .C_ADDR_WIDTH(12),
    .C_DATA_WIDTH(8)
)bram_asymmetric_r2_w1_port_even_red
(
    .wclk    (clk_in1),
    .wen     (bram1_a_wenb),
    .waddr   (bram_a_waddr),
    .wdata   (bram_a_wdata_r),

    .rclk    (clk_in2),
    .raddr1  (even_bram1_raddr),
    .rdata1  (even_bram1_r_rdata),
    .raddr2  (odd_bram1_raddr),
    .rdata2  (odd_bram1_r_rdata)
);

bram_asymmetric_r2_w1_port   //输出起点2
#(
    .C_ADDR_WIDTH(12),
    .C_DATA_WIDTH(8)
)bram_asymmetric_r2_w1_port_odd_red
(
    .wclk    (clk_in1),
    .wen     (bram2_a_wenb),
    .waddr   (bram_a_waddr),
    .wdata   (bram_a_wdata_r),

    .rclk    (clk_in2),
    .raddr1  (even_bram2_raddr),
    .rdata1  (even_bram2_r_rdata),
    .raddr2  (odd_bram2_raddr),
    .rdata2  (odd_bram2_r_rdata)
);
/*---------------------------------------------
-----------------GREEN-------------------------
-----------------------------------------------*/
bram_asymmetric_r2_w1_port   //输出起点1
#(
    .C_ADDR_WIDTH(12),
    .C_DATA_WIDTH(8)
)bram_asymmetric_r2_w1_port_even_green
(
    .wclk    (clk_in1),
    .wen     (bram1_a_wenb),
    .waddr   (bram_a_waddr),
    .wdata   (bram_a_wdata_g),

    .rclk    (clk_in2),
    .raddr1  (even_bram1_raddr),
    .rdata1  (even_bram1_g_rdata),
    .raddr2  (odd_bram1_raddr),
    .rdata2  (odd_bram1_g_rdata)
);

bram_asymmetric_r2_w1_port   //输出起点2
#(
    .C_ADDR_WIDTH(12),
    .C_DATA_WIDTH(8)
)bram_asymmetric_r2_w1_port_odd_green
(
    .wclk    (clk_in1),
    .wen     (bram2_a_wenb),
    .waddr   (bram_a_waddr),
    .wdata   (bram_a_wdata_g),

    .rclk    (clk_in2),
    .raddr1  (even_bram2_raddr),
    .rdata1  (even_bram2_g_rdata),
    .raddr2  (odd_bram2_raddr),
    .rdata2  (odd_bram2_g_rdata)
);
/*---------------------------------------------
-----------------BLUE--------------------------
-----------------------------------------------*/
bram_asymmetric_r2_w1_port   //输出起点1
#(
    .C_ADDR_WIDTH(12),
    .C_DATA_WIDTH(8)
)bram_asymmetric_r2_w1_port_even_blue
(
    .wclk    (clk_in1),
    .wen     (bram1_a_wenb),
    .waddr   (bram_a_waddr),
    .wdata   (bram_a_wdata_b),

    .rclk    (clk_in2),
    .raddr1  (even_bram1_raddr),
    .rdata1  (even_bram1_b_rdata),
    .raddr2  (odd_bram1_raddr),
    .rdata2  (odd_bram1_b_rdata)
);

bram_asymmetric_r2_w1_port   //输出起点2
#(
    .C_ADDR_WIDTH(12),
    .C_DATA_WIDTH(8)
)bram_asymmetric_r2_w1_port_odd_blue
(
    .wclk    (clk_in1),
    .wen     (bram2_a_wenb),
    .waddr   (bram_a_waddr),
    .wdata   (bram_a_wdata_b),

    .rclk    (clk_in2),
    .raddr1  (even_bram2_raddr),
    .rdata1  (even_bram2_b_rdata),
    .raddr2  (odd_bram2_raddr),
    .rdata2  (odd_bram2_b_rdata)
);

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
                    if((fifo_rdata != 11'b0)&&(y_cnt == dst_img_height))
                        state <= S_RD_FIFO;
                    else
                        state <= S_Y_LOAD;
                end
                else
                    state <= S_IDLE;
            end
            S_Y_LOAD : 
            begin
                if((y_dec[26:16] + 1'b1 <= fifo_rdata)||(y_cnt == dst_img_height - 1'b1))
                    state <= S_BRAM_ADDR;
                else
                    state <= S_RD_FIFO;
            end
            S_BRAM_ADDR : 
            begin
                if(x_cnt == dst_img_width - 1'b1)
                    state <= S_Y_INC;
                else
                    state <= S_BRAM_ADDR;
            end
            S_Y_INC : 
            begin
                if(y_cnt == dst_img_height - 1'b1)
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
            y_dec <= y_dec + y_radio;
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
        x_dec <= x_dec + x_radio;
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
        else if((state == S_Y_INC)&&(y_cnt == dst_img_height - 1'b1))
            img_vs_c1 <= 1'b0;
        else
            img_vs_c1 <= img_vs_c1;
    end
end

reg                             img_de_c1;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
        img_de_c1 <= 1'b0;
    else
    begin
        if(state == S_BRAM_ADDR)
            img_de_c1 <= 1'b1;
        else
            img_de_c1 <= 1'b0;
    end
end

reg             [10:0]          x_int_c1;
reg             [10:0]          y_int_c1;
reg                             x_dec_half_c1;
reg                             y_dec_half_c1;

always @(posedge clk_in2)
begin
    x_int_c1     <= x_dec[25:16];  //左上角像素级坐标
    y_int_c1     <= y_dec[25:16];
    x_dec_half_c1<= x_dec[15];
    y_dec_half_c1<= y_dec[15];
end

//----------------------------------------------------------------------
//  c2
reg                             img_vs_c2;
reg                             img_de_c2;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c2 <= 1'b0;
        img_de_c2 <= 1'b0;
    end
    else
    begin
        img_vs_c2 <= img_vs_c1;
        img_de_c2 <= img_de_c1;
    end
end

reg             [11:0]          bram_addr_c2;
reg                             bram_mode_c2;
reg                             x_dec_half_c2;
reg                             y_dec_half_c2;


always @(posedge clk_in2)
begin
    bram_addr_c2 <= {y_int_c1[2:1],10'b0} + x_int_c1;//转化为一维形式的地址
    bram_mode_c2 <= y_int_c1[0];
    x_dec_half_c2<= x_dec_half_c1;
    y_dec_half_c2<= y_dec_half_c1;
end

reg                             right_pixel_extand_flag_c2;
reg                             bottom_pixel_extand_flag_c2;

always @(posedge clk_in2)         //边界flag
begin
    if(x_int_c1 == src_img_width - 1'b1)
        right_pixel_extand_flag_c2 <= 1'b1;
    else
        right_pixel_extand_flag_c2 <= 1'b0;
    if(y_int_c1 == src_img_height - 1'b1)
        bottom_pixel_extand_flag_c2 <= 1'b1;
    else
        bottom_pixel_extand_flag_c2 <= 1'b0;
end

//----------------------------------------------------------------------
//  c3
reg                             img_vs_c3;
reg                             img_de_c3;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c3 <= 1'b0;
        img_de_c3 <= 1'b0;
    end
    else
    begin
        img_vs_c3 <= img_vs_c2;
        img_de_c3 <= img_de_c2;
    end
end

always @(posedge clk_in2)            //转化为bram内部真实的地址
begin
    if(bram_mode_c2 == 1'b0)
    begin
        even_bram1_raddr <= bram_addr_c2;
        odd_bram1_raddr  <= bram_addr_c2 + 1'b1;
        even_bram2_raddr <= bram_addr_c2;
        odd_bram2_raddr  <= bram_addr_c2 + 1'b1;
    end
    else
    begin
        even_bram1_raddr <= bram_addr_c2 + 11'd1024;
        odd_bram1_raddr  <= bram_addr_c2 + 11'd1025;
        even_bram2_raddr <= bram_addr_c2;
        odd_bram2_raddr  <= bram_addr_c2 + 1'b1;
    end
end

reg                             bram_mode_c3;
reg                             right_pixel_extand_flag_c3;
reg                             bottom_pixel_extand_flag_c3;
reg                             x_dec_half_c3;
reg                             y_dec_half_c3;

always @(posedge clk_in2)
begin
    bram_mode_c3                <= bram_mode_c2;
    right_pixel_extand_flag_c3  <= right_pixel_extand_flag_c2;
    bottom_pixel_extand_flag_c3 <= bottom_pixel_extand_flag_c2;
    x_dec_half_c3 <= x_dec_half_c2;
    y_dec_half_c3 <= y_dec_half_c2;
end

//----------------------------------------------------------------------
//  c4
reg                             img_vs_c4;
reg                             img_de_c4;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c4 <= 1'b0;
        img_de_c4 <= 1'b0;
    end
    else
    begin
        img_vs_c4 <= img_vs_c3;
        img_de_c4 <= img_de_c3;
    end
end

reg                             bram_mode_c4;
reg                             right_pixel_extand_flag_c4;
reg                             bottom_pixel_extand_flag_c4;
reg                             x_dec_half_c4;
reg                             y_dec_half_c4;


always @(posedge clk_in2)
begin
    bram_mode_c4                <= bram_mode_c3;
    right_pixel_extand_flag_c4  <= right_pixel_extand_flag_c3;
    bottom_pixel_extand_flag_c4 <= bottom_pixel_extand_flag_c3;
    x_dec_half_c4 <= x_dec_half_c3;
    y_dec_half_c4 <= y_dec_half_c3;
end

//----------------------------------------------------------------------
//  c5
reg                             img_vs_c5;
reg                             img_de_c5;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c5 <= 1'b0;
        img_de_c5 <= 1'b0;
    end
    else
    begin
        img_vs_c5 <= img_vs_c4;
        img_de_c5 <= img_de_c4;
    end
end

reg             [7:0]           pixel_r_data00_c5;
reg             [7:0]           pixel_r_data01_c5;
reg             [7:0]           pixel_r_data10_c5;
reg             [7:0]           pixel_r_data11_c5;
reg             [7:0]           pixel_g_data00_c5;
reg             [7:0]           pixel_g_data01_c5;
reg             [7:0]           pixel_g_data10_c5;
reg             [7:0]           pixel_g_data11_c5;
reg             [7:0]           pixel_b_data00_c5;
reg             [7:0]           pixel_b_data01_c5;
reg             [7:0]           pixel_b_data10_c5;
reg             [7:0]           pixel_b_data11_c5;


always @(posedge clk_in2)  //奇偶模式选择
begin
    if(bram_mode_c4 == 1'b0)
    begin
        pixel_r_data00_c5 <= even_bram1_r_rdata;
        pixel_r_data01_c5 <= odd_bram1_r_rdata;
        pixel_r_data10_c5 <= even_bram2_r_rdata;
        pixel_r_data11_c5 <= odd_bram2_r_rdata;
        pixel_g_data00_c5 <= even_bram1_g_rdata;
        pixel_g_data01_c5 <= odd_bram1_g_rdata;
        pixel_g_data10_c5 <= even_bram2_g_rdata;
        pixel_g_data11_c5 <= odd_bram2_g_rdata;
        pixel_b_data00_c5 <= even_bram1_b_rdata;
        pixel_b_data01_c5 <= odd_bram1_b_rdata;
        pixel_b_data10_c5 <= even_bram2_b_rdata;
        pixel_b_data11_c5 <= odd_bram2_b_rdata;
    end
    else
    begin
        pixel_r_data00_c5 <= even_bram2_r_rdata;
        pixel_r_data01_c5 <= odd_bram2_r_rdata;
        pixel_r_data10_c5 <= even_bram1_r_rdata;
        pixel_r_data11_c5 <= odd_bram1_r_rdata;
        pixel_g_data00_c5 <= even_bram2_g_rdata;
        pixel_g_data01_c5 <= odd_bram2_g_rdata;
        pixel_g_data10_c5 <= even_bram1_g_rdata;
        pixel_g_data11_c5 <= odd_bram1_g_rdata;
        pixel_b_data00_c5 <= even_bram2_b_rdata;
        pixel_b_data01_c5 <= odd_bram2_b_rdata;
        pixel_b_data10_c5 <= even_bram1_b_rdata;
        pixel_b_data11_c5 <= odd_bram1_b_rdata;
    end
end

reg                             right_pixel_extand_flag_c5;
reg                             bottom_pixel_extand_flag_c5;
reg                             x_dec_half_c5;
reg                             y_dec_half_c5;

always @(posedge clk_in2)
begin
    right_pixel_extand_flag_c5  <= right_pixel_extand_flag_c4;
    bottom_pixel_extand_flag_c5 <= bottom_pixel_extand_flag_c4;
    x_dec_half_c5 <= x_dec_half_c4;
    y_dec_half_c5 <= y_dec_half_c4;
end

//----------------------------------------------------------------------
//  c6
reg                             img_vs_c6;
reg                             img_de_c6;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c6 <= 1'b0;
        img_de_c6 <= 1'b0;
    end
    else
    begin
        img_vs_c6 <= img_vs_c5;
        img_de_c6 <= img_de_c5;
    end
end

reg             [7:0]           pixel_r_data00_c6;
reg             [7:0]           pixel_r_data01_c6;
reg             [7:0]           pixel_r_data10_c6;
reg             [7:0]           pixel_r_data11_c6;
reg             [7:0]           pixel_g_data00_c6;
reg             [7:0]           pixel_g_data01_c6;
reg             [7:0]           pixel_g_data10_c6;
reg             [7:0]           pixel_g_data11_c6;
reg             [7:0]           pixel_b_data00_c6;
reg             [7:0]           pixel_b_data01_c6;
reg             [7:0]           pixel_b_data10_c6;
reg             [7:0]           pixel_b_data11_c6;


always @(posedge clk_in2) //边界镜像复制
begin
    case({right_pixel_extand_flag_c5,bottom_pixel_extand_flag_c5})
        2'b00 : 
        begin
            pixel_r_data00_c6 <= pixel_r_data00_c5;
            pixel_r_data01_c6 <= pixel_r_data01_c5;
            pixel_r_data10_c6 <= pixel_r_data10_c5;
            pixel_r_data11_c6 <= pixel_r_data11_c5;
            pixel_g_data00_c6 <= pixel_g_data00_c5;
            pixel_g_data01_c6 <= pixel_g_data01_c5;
            pixel_g_data10_c6 <= pixel_g_data10_c5;
            pixel_g_data11_c6 <= pixel_g_data11_c5;
            pixel_b_data00_c6 <= pixel_b_data00_c5;
            pixel_b_data01_c6 <= pixel_b_data01_c5;
            pixel_b_data10_c6 <= pixel_b_data10_c5;
            pixel_b_data11_c6 <= pixel_b_data11_c5;
        end
        2'b01 : 
        begin
            pixel_r_data00_c6 <= pixel_r_data00_c5;
            pixel_r_data01_c6 <= pixel_r_data01_c5;
            pixel_r_data10_c6 <= pixel_r_data00_c5;
            pixel_r_data11_c6 <= pixel_r_data01_c5;
            pixel_g_data00_c6 <= pixel_g_data00_c5;
            pixel_g_data01_c6 <= pixel_g_data01_c5;
            pixel_g_data10_c6 <= pixel_g_data00_c5;
            pixel_g_data11_c6 <= pixel_g_data01_c5;
            pixel_b_data00_c6 <= pixel_b_data00_c5;
            pixel_b_data01_c6 <= pixel_b_data01_c5;
            pixel_b_data10_c6 <= pixel_b_data00_c5;
            pixel_b_data11_c6 <= pixel_b_data01_c5;
        end
        2'b10 : 
        begin
            pixel_r_data00_c6 <= pixel_r_data00_c5;
            pixel_r_data01_c6 <= pixel_r_data00_c5;
            pixel_r_data10_c6 <= pixel_r_data10_c5;
            pixel_r_data11_c6 <= pixel_r_data10_c5;
            pixel_g_data00_c6 <= pixel_g_data00_c5;
            pixel_g_data01_c6 <= pixel_g_data00_c5;
            pixel_g_data10_c6 <= pixel_g_data10_c5;
            pixel_g_data11_c6 <= pixel_g_data10_c5;
            pixel_b_data00_c6 <= pixel_b_data00_c5;
            pixel_b_data01_c6 <= pixel_b_data00_c5;
            pixel_b_data10_c6 <= pixel_b_data10_c5;
            pixel_b_data11_c6 <= pixel_b_data10_c5;
        end
        2'b11 : 
        begin
            pixel_r_data00_c6 <= pixel_r_data00_c5;
            pixel_r_data01_c6 <= pixel_r_data00_c5;
            pixel_r_data10_c6 <= pixel_r_data00_c5;
            pixel_r_data11_c6 <= pixel_r_data00_c5;
            pixel_g_data00_c6 <= pixel_g_data00_c5;
            pixel_g_data01_c6 <= pixel_g_data00_c5;
            pixel_g_data10_c6 <= pixel_g_data00_c5;
            pixel_g_data11_c6 <= pixel_g_data00_c5;
            pixel_b_data00_c6 <= pixel_b_data00_c5;
            pixel_b_data01_c6 <= pixel_b_data00_c5;
            pixel_b_data10_c6 <= pixel_b_data00_c5;
            pixel_b_data11_c6 <= pixel_b_data00_c5;
        end
    endcase
end

reg                             x_dec_half_c6;
reg                             y_dec_half_c6;

always @(posedge clk_in2) 
begin
    x_dec_half_c6 <= x_dec_half_c5;
    y_dec_half_c6 <= y_dec_half_c5;
end



//----------------------------------------------------------------------
//  output


always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        post_img_vsync <= 1'b0;
        post_img_de    <= 1'b0;
    end
    else
    begin
        post_img_vsync <= img_vs_c6;
        post_img_de    <= img_de_c6;
    end
end  


always @(posedge clk_in2)
begin
    case({x_dec_half_c6,y_dec_half_c6})
    2'b00:begin
        post_img_r <= pixel_r_data00_c6;
        post_img_g <= pixel_g_data00_c6;
        post_img_b <= pixel_b_data00_c6;
    end
    2'b01:begin
        post_img_r <= pixel_r_data10_c6;
        post_img_g <= pixel_g_data10_c6;
        post_img_b <= pixel_b_data10_c6;
    end
    2'b10:begin
        post_img_r <= pixel_r_data01_c6;
        post_img_g <= pixel_g_data01_c6;
        post_img_b <= pixel_b_data01_c6;
    end
    2'b11:begin
        post_img_r <= pixel_r_data11_c6;
        post_img_g <= pixel_g_data11_c6;
        post_img_b <= pixel_b_data11_c6;
    end
    default:begin
        post_img_r <= pixel_r_data00_c6;
        post_img_g <= pixel_g_data00_c6;
        post_img_b <= pixel_b_data00_c6;
    end
    endcase
end




endmodule