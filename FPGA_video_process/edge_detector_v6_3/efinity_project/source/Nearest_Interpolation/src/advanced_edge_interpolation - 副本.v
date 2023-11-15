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
module advanced_edge_interpolation
(

    input  wire                 edge_signal   ,  

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
reg                             edge_bram_a_wdata;

always @(posedge clk_in1)
begin
    bram_a_wdata_r <= per_img_r;
    bram_a_wdata_g <= per_img_g;
    bram_a_wdata_b <= per_img_b;
    edge_bram_a_wdata <=  edge_signal;
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


wire                      edge_even_bram1_rdata;
wire                      edge_odd_bram1_rdata;
wire                      edge_even_bram2_rdata;
wire                      edge_odd_bram2_rdata;


/*---------------------------------------------
-----------------EDGE---------------------------
-----------------------------------------------*/




bram_asymmetric_r2_w1_port   //输出起点1
#(
    .C_ADDR_WIDTH(12),
    .C_DATA_WIDTH(1)
)bram_asymmetric_r2_w1_port_even_edge
(
    .wclk    (clk_in1),
    .wen     (bram1_a_wenb),
    .waddr   (bram_a_waddr),
    .wdata   (edge_bram_a_wdata),

    .rclk    (clk_in2),
    .raddr1  (even_bram1_raddr),
    .rdata1  (edge_even_bram1_rdata),
    .raddr2  (odd_bram1_raddr),
    .rdata2  (edge_odd_bram1_rdata)
);


bram_asymmetric_r2_w1_port   //输出起点2
#(
    .C_ADDR_WIDTH(12),
    .C_DATA_WIDTH(1)
)bram_asymmetric_r2_w1_port_odd_edge
(
    .wclk    (clk_in1),
    .wen     (bram2_a_wenb),
    .waddr   (bram_a_waddr),
    .wdata   (edge_bram_a_wdata),

    .rclk    (clk_in2),
    .raddr1  (even_bram2_raddr),
    .rdata1  (edge_even_bram2_rdata),
    .raddr2  (odd_bram2_raddr),
    .rdata2  (edge_odd_bram2_rdata)
);



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
reg             [16:0]          x_fra_c1;
reg             [16:0]          inv_x_fra_c1;
reg             [16:0]          y_fra_c1;
reg             [16:0]          inv_y_fra_c1;

always @(posedge clk_in2)
begin
    x_int_c1     <= x_dec[25:16];
    y_int_c1     <= y_dec[25:16];
    x_fra_c1     <= {1'b0,x_dec[15:0]};
    inv_x_fra_c1 <= 17'h10000 - {1'b0,x_dec[15:0]};
    y_fra_c1     <= {1'b0,y_dec[15:0]};
    inv_y_fra_c1 <= 17'h10000 - {1'b0,y_dec[15:0]};
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
reg             [33:0]          frac_00_c2;
reg             [33:0]          frac_01_c2;
reg             [33:0]          frac_10_c2;
reg             [33:0]          frac_11_c2;
reg                             bram_mode_c2;

reg             [16:0]         x_fra_c2;
reg             [16:0]         y_fra_c2;


always @(posedge clk_in2)
begin
    bram_addr_c2 <= {y_int_c1[2:1],10'b0} + x_int_c1;
    frac_00_c2   <= inv_x_fra_c1 * inv_y_fra_c1;
    frac_01_c2   <= x_fra_c1 * inv_y_fra_c1;
    frac_10_c2   <= inv_x_fra_c1 * y_fra_c1;
    frac_11_c2   <= x_fra_c1 * y_fra_c1;
    bram_mode_c2 <= y_int_c1[0];
    x_fra_c2     <= x_fra_c1;
    y_fra_c2     <= y_fra_c1;



end

reg                             right_pixel_extand_flag_c2;
reg                             bottom_pixel_extand_flag_c2;

always @(posedge clk_in2)
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

always @(posedge clk_in2)
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

reg             [33:0]          frac_00_c3;
reg             [33:0]          frac_01_c3;
reg             [33:0]          frac_10_c3;
reg             [33:0]          frac_11_c3;
reg             [16:0]          x_fra_c3;
reg             [16:0]          y_fra_c3;

reg                             bram_mode_c3;
reg                             right_pixel_extand_flag_c3;
reg                             bottom_pixel_extand_flag_c3;

always @(posedge clk_in2)
begin
    frac_00_c3                  <= frac_00_c2;
    frac_01_c3                  <= frac_01_c2;
    frac_10_c3                  <= frac_10_c2;
    frac_11_c3                  <= frac_11_c2;
    x_fra_c3                    <= x_fra_c2;
    y_fra_c3                    <= y_fra_c2;

    bram_mode_c3                <= bram_mode_c2;
    right_pixel_extand_flag_c3  <= right_pixel_extand_flag_c2;
    bottom_pixel_extand_flag_c3 <= bottom_pixel_extand_flag_c2;
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

reg             [33:0]          frac_00_c4;
reg             [33:0]          frac_01_c4;
reg             [33:0]          frac_10_c4;
reg             [33:0]          frac_11_c4;
reg             [16:0]          x_fra_c4;
reg             [16:0]          y_fra_c4;
reg                             bram_mode_c4;
reg                             right_pixel_extand_flag_c4;
reg                             bottom_pixel_extand_flag_c4;

always @(posedge clk_in2)
begin
    frac_00_c4                  <= frac_00_c3;
    frac_01_c4                  <= frac_01_c3;
    frac_10_c4                  <= frac_10_c3;
    frac_11_c4                  <= frac_11_c3;
    x_fra_c4                    <= x_fra_c3;
    y_fra_c4                    <= y_fra_c3;
    bram_mode_c4                <= bram_mode_c3;
    right_pixel_extand_flag_c4  <= right_pixel_extand_flag_c3;
    bottom_pixel_extand_flag_c4 <= bottom_pixel_extand_flag_c3;
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

reg                             edge_pixel_data00_c5;
reg                             edge_pixel_data01_c5;
reg                             edge_pixel_data10_c5;
reg                             edge_pixel_data11_c5;



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

        edge_pixel_data00_c5 <= edge_even_bram1_rdata;
        edge_pixel_data01_c5 <= edge_odd_bram1_rdata;
        edge_pixel_data10_c5 <= edge_even_bram2_rdata;
        edge_pixel_data11_c5 <= edge_odd_bram2_rdata;


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

        edge_pixel_data00_c5 <= edge_even_bram2_rdata;
        edge_pixel_data01_c5 <= edge_odd_bram2_rdata;
        edge_pixel_data10_c5 <= edge_even_bram1_rdata;
        edge_pixel_data11_c5 <= edge_odd_bram1_rdata;


    end
end

reg             [33:0]          frac_00_c5;
reg             [33:0]          frac_01_c5;
reg             [33:0]          frac_10_c5;
reg             [33:0]          frac_11_c5;
reg             [16:0]          x_fra_c5;
reg             [16:0]          y_fra_c5;
reg                             right_pixel_extand_flag_c5;
reg                             bottom_pixel_extand_flag_c5;

always @(posedge clk_in2)
begin
    frac_00_c5                  <= frac_00_c4;
    frac_01_c5                  <= frac_01_c4;
    frac_10_c5                  <= frac_10_c4;
    frac_11_c5                  <= frac_11_c4;
    x_fra_c5                    <= x_fra_c4;
    y_fra_c5                    <= y_fra_c4;

    right_pixel_extand_flag_c5  <= right_pixel_extand_flag_c4;
    bottom_pixel_extand_flag_c5 <= bottom_pixel_extand_flag_c4;
end

//----------------------------------------------------------------------
//  c6
reg                             img_vs_c6;
reg                             img_de_c6;
reg                             edge_flag_c6;


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






always @(posedge clk_in2) //边界判断
begin
    if(rst_n == 1'b0)
        edge_flag_c6 <= 1'b0;
    else if({edge_pixel_data00_c5,edge_pixel_data01_c5,edge_pixel_data10_c5,edge_pixel_data11_c5})
        edge_flag_c6 <= 1'b1;
    else
        edge_flag_c6 <= 1'b0;
end




reg             [33:0]          frac_00_c6;
reg             [33:0]          frac_01_c6;
reg             [33:0]          frac_10_c6;
reg             [33:0]          frac_11_c6;
reg             [16:0]          x_fra_c6;
reg             [16:0]          y_fra_c6;



always @(posedge clk_in2)
begin
    frac_00_c6 <= frac_00_c5;
    frac_01_c6 <= frac_01_c5;
    frac_10_c6 <= frac_10_c5;
    frac_11_c6 <= frac_11_c5;
    x_fra_c6                    <= x_fra_c5;
    y_fra_c6                    <= y_fra_c5;


end

//----------------------------------------------------------------------
//  c7
reg                             img_vs_c7;
reg                             img_de_c7;
reg                             edge_flag_c7;


always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c7 <= 1'b0;
        img_de_c7 <= 1'b0;
        edge_flag_c7 <= 1'b0;
    end
    else
    begin
        img_vs_c7 <= img_vs_c6;
        img_de_c7 <= img_de_c6;
        edge_flag_c7 <= edge_flag_c6;
    end
end

reg             [41:0]          r_data00_c7;
reg             [41:0]          r_data01_c7;
reg             [41:0]          r_data10_c7;
reg             [41:0]          r_data11_c7;
reg             [41:0]          g_data00_c7;
reg             [41:0]          g_data01_c7;
reg             [41:0]          g_data10_c7;
reg             [41:0]          g_data11_c7;
reg             [41:0]          b_data00_c7;
reg             [41:0]          b_data01_c7;
reg             [41:0]          b_data10_c7;
reg             [41:0]          b_data11_c7;
reg             [7:0]           post_red_c7;
reg             [7:0]           post_blue_c7;
reg             [7:0]           post_green_c7;




always @(posedge clk_in2)  //乘上权重
case(edge_flag_c6)
        1'b1 : 
        begin
            if((x_fra_c6[15] == 1'b0) && (y_fra_c6[15] == 1'b0))
            begin
                post_red_c7   <= pixel_r_data00_c6;
                post_green_c7 <= pixel_g_data00_c6;
                post_blue_c7  <= pixel_b_data00_c6;
            end
            else if((x_fra_c6[15] == 1'b1) && (y_fra_c6[15] == 1'b0))
            begin
                post_red_c7    <= pixel_r_data01_c6;
                post_green_c7  <= pixel_g_data01_c6;
                post_blue_c7   <= pixel_b_data01_c6;
            end
            else if((x_fra_c6[15] == 1'b0) && (y_fra_c6[15] == 1'b1))
            begin
                post_red_c7    <= pixel_r_data10_c6;
                post_green_c7  <= pixel_g_data10_c6;
                post_blue_c7   <= pixel_b_data10_c6;
            end
            else
            begin
                post_red_c7    <= pixel_r_data11_c6;
                post_green_c7  <= pixel_g_data11_c6;
                post_blue_c7   <= pixel_b_data11_c6;
            end
        end
        1'b0 : 
        begin
            begin
                r_data00_c7 <= frac_00_c6 * pixel_r_data00_c6;
                r_data01_c7 <= frac_01_c6 * pixel_r_data01_c6;
                r_data10_c7 <= frac_10_c6 * pixel_r_data10_c6;
                r_data11_c7 <= frac_11_c6 * pixel_r_data11_c6;
                g_data00_c7 <= frac_00_c6 * pixel_g_data00_c6;
                g_data01_c7 <= frac_01_c6 * pixel_g_data01_c6;
                g_data10_c7 <= frac_10_c6 * pixel_g_data10_c6;
                g_data11_c7 <= frac_11_c6 * pixel_g_data11_c6;
                b_data00_c7 <= frac_00_c6 * pixel_b_data00_c6;
                b_data01_c7 <= frac_01_c6 * pixel_b_data01_c6;
                b_data10_c7 <= frac_10_c6 * pixel_b_data10_c6;
                b_data11_c7 <= frac_11_c6 * pixel_b_data11_c6;
            end
        end
    endcase



//----------------------------------------------------------------------
//  c8
reg                             img_vs_c8;
reg                             img_de_c8;
reg             [7:0]           post_red_c8;
reg             [7:0]           post_green_c8;
reg             [7:0]           post_blue_c8;
reg                             edge_flag_c8;


always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c8 <= 1'b0;
        img_de_c8 <= 1'b0;
        edge_flag_c8 <= 1'b0;
    end
    else
    begin
        img_vs_c8 <= img_vs_c7;
        img_de_c8 <= img_de_c7;
        edge_flag_c8 <= edge_flag_c7;
    end
end

reg             [42:0]          r_data_tmp1_c8;
reg             [42:0]          r_data_tmp2_c8;
reg             [42:0]          g_data_tmp1_c8;
reg             [42:0]          g_data_tmp2_c8;
reg             [42:0]          b_data_tmp1_c8;
reg             [42:0]          b_data_tmp2_c8;

always @(posedge clk_in2)   //横向相加
begin
    r_data_tmp1_c8 <= r_data00_c7 + r_data01_c7;
    r_data_tmp2_c8 <= r_data10_c7 + r_data11_c7;
    g_data_tmp1_c8 <= g_data00_c7 + g_data01_c7;
    g_data_tmp2_c8 <= g_data10_c7 + g_data11_c7;
    b_data_tmp1_c8 <= b_data00_c7 + b_data01_c7;
    b_data_tmp2_c8 <= b_data10_c7 + b_data11_c7;
    post_red_c8    <= post_red_c7;
    post_green_c8    <= post_green_c7;
    post_blue_c8    <= post_blue_c7;
end

//----------------------------------------------------------------------
//  c9
reg                             img_vs_c9;
reg                             img_de_c9;
reg             [7:0]           post_red_c9;
reg             [7:0]           post_green_c9;
reg             [7:0]           post_blue_c9;
reg                             edge_flag_c9;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c9 <= 1'b0;
        img_de_c9 <= 1'b0;
        edge_flag_c9 <= 1'b0;
    end
    else
    begin
        img_vs_c9 <= img_vs_c8;
        img_de_c9 <= img_de_c8;
        edge_flag_c9 <= edge_flag_c8;
    end
end

reg             [43:0]          r_data_c9;
reg             [43:0]          g_data_c9;
reg             [43:0]          b_data_c9;

always @(posedge clk_in2)  //纵向相加
begin
    r_data_c9 <= r_data_tmp1_c8 + r_data_tmp2_c8;
    g_data_c9 <= g_data_tmp1_c8 + g_data_tmp2_c8;
    b_data_c9 <= b_data_tmp1_c8 + b_data_tmp2_c8;
    post_red_c9    <=     post_red_c8;
    post_green_c9    <=     post_green_c8;
    post_blue_c9    <=     post_blue_c8;
end

//----------------------------------------------------------------------
//  c10
reg                             img_vs_c10;
reg                             img_de_c10;
reg             [7:0]           post_red_c10;
reg             [7:0]           post_green_c10;
reg             [7:0]           post_blue_c10;
reg                             edge_flag_c10;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c10 <= 1'b0;
        img_de_c10 <= 1'b0;
        edge_flag_c10 <= 1'b0;
    end
    else
    begin
        img_vs_c10 <= img_vs_c9;
        img_de_c10 <= img_de_c9;
        edge_flag_c10 <= edge_flag_c9;
    end
end

reg             [11:0]          r_data_c10;
reg             [11:0]          g_data_c10;
reg             [11:0]          b_data_c10;

always @(posedge clk_in2)
begin
    r_data_c10 <= r_data_c9[43:32] + r_data_c9[31];  //四舍五入
    g_data_c10 <= g_data_c9[43:32] + g_data_c9[31];
    b_data_c10 <= b_data_c9[43:32] + b_data_c9[31];
    post_red_c10    <=     post_red_c9;
    post_green_c10    <=     post_green_c9;
    post_blue_c10    <=     post_blue_c9;
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
        post_img_de  <= img_de_c10;
    end
end

always @(posedge clk_in2)  //溢出保护
begin

    if(edge_flag_c10)
        post_img_r <= post_red_c10;
    else if(r_data_c10 > 12'd255)
        post_img_r <= 8'd255;
    else
        post_img_r <= r_data_c10[7:0];
end

always @(posedge clk_in2)  //溢出保护
begin
    if(edge_flag_c10)
        post_img_g <= post_green_c10;
    else if(g_data_c10 > 12'd255)
        post_img_g <= 8'd255;
    else
        post_img_g <= g_data_c10[7:0];
end

always @(posedge clk_in2)  //溢出保护
begin
    if(edge_flag_c10)
        post_img_b <= post_blue_c10;
    else if(b_data_c10 > 12'd255)
        post_img_b <= 8'd255;
    else
        post_img_b <= b_data_c10[7:0];
end






endmodule