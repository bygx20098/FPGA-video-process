// *********************************************************************
// 
// Copyright (C) 2021-20xx CrazyBird Corporation
// 
// Filename     :   nearest_interpolation.v
// Author       :   CrazyBird
// Email        :   CrazyBirdLin@qq.com
// 
// Description  :   
// 
// Modification History
// Date         By          Version         Change Description
//----------------------------------------------------------------------
// 2022/03/20   CrazyBird   1.0             Original
// 
// *********************************************************************
module nearest_interpolation
(
    input  wire     [10:0]      src_img_width ,
    input  wire     [10:0]      src_img_height,
    input  wire     [10:0]      dst_img_width ,
    input  wire     [10:0]      dst_img_height,
    input  wire     [15:0]      x_radio       ,
    input  wire     [15:0]      y_radio       ,
        
    input  wire                 clk_in1         ,
    input  wire                 clk_in2         ,
    input  wire                 rst_n           ,
    
    //  Image data prepared to be processed
    input  wire                 per_img_vsync   ,                       //  Prepared Image data vsync valid signal
    input  wire                 per_img_href    ,                       //  Prepared Image data href vaild  signal
    input  wire     [7:0]       per_img_gray    ,                       //  Prepared Image brightness input
    
    //  Image data has been processed
    output reg                  post_img_vsync  ,                       //  processed Image data vsync valid signal
    output reg                  post_img_href   ,                       //  processed Image data href vaild  signal
    output wire     [7:0]       post_img_gray                           //  processed Image brightness output
);
//----------------------------------------------------------------------
reg                             per_img_href_dly;

always @(posedge clk_in1)
begin
    if(rst_n == 1'b0)
        per_img_href_dly <= 1'b0;
    else
        per_img_href_dly <= per_img_href;
end

wire                            per_img_href_neg;

assign per_img_href_neg = per_img_href_dly & ~per_img_href;

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
            if(per_img_href_neg == 1'b1)
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
        if((per_img_vsync == 1'b1)&&(per_img_href == 1'b1))
            img_hs_cnt <= img_hs_cnt + 1'b1;
        else
            img_hs_cnt <= 11'b0;
    end
end

//----------------------------------------------------------------------
reg             [7:0]           bram_a_wdata;

always @(posedge clk_in1)
begin
    bram_a_wdata <= per_img_gray;
end

reg             [11:0]          bram_a_waddr;

always @(posedge clk_in1)
begin
    bram_a_waddr <= {img_vs_cnt[1:0],10'b0} + img_hs_cnt;
end

reg                             bram_a_wenb;

always @(posedge clk_in1)
begin
    if(rst_n == 1'b0)
        bram_a_wenb <= 1'b0;
    else
        bram_a_wenb <= per_img_vsync & per_img_href;
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
        if((per_img_vsync == 1'b1)&&(per_img_href == 1'b1)&&(img_hs_cnt == src_img_width - 1'b1))
            fifo_wenb <= 1'b1;
        else
            fifo_wenb <= 1'b0;
    end
end

//----------------------------------------------------------------------
//  bram & fifo rw
reg             [11:0]          bram_b_raddr;
wire            [ 7:0]          bram_b_rdata;

bram_ture_dual_port
#(
    .C_ADDR_WIDTH(12),
    .C_DATA_WIDTH(8 )
)
u0_image_data_bram1
(
    .clka   (clk_in1        ),
    .wea    (bram_a_wenb    ),
    .addra  (bram_a_waddr   ),
    .dina   (bram_a_wdata   ),
    .douta  (               ),
    .clkb   (clk_in2        ),
    .web    (1'b0           ),
    .addrb  (bram_b_raddr   ),
    .dinb   (8'b0           ),
    .doutb  (bram_b_rdata   )
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

always @(posedge clk_in2)
begin
    x_int_c1 <= x_dec[26:16] + x_dec[15];
    y_int_c1 <= y_dec[26:16] + y_dec[15];
end

//----------------------------------------------------------------------
//  c2
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

always @(posedge clk_in2)
begin
    bram_b_raddr <= {y_int_c1[1:0],10'b0} + x_int_c1;
end

//----------------------------------------------------------------------
//  signals output
reg                             img_vs_c3;
reg                             img_hs_c3;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        post_img_vsync <= 1'b0;
        post_img_href  <= 1'b0;
    end
    else
    begin
        post_img_vsync <= img_vs_c2;
        post_img_href  <= img_hs_c2;
    end
end

assign post_img_gray = bram_b_rdata;

endmodule