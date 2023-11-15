module  inf_control
#(
    parameter   C_DST_IMG_WIDTH_STEP  = 11'd40  ,
    parameter   C_DST_IMG_HEIGHT_STEP = 11'd15  ,
    parameter   C_DST_IMG_WIDTH_MAX   = 11'd1600,
    parameter   C_DST_IMG_HEIGHT_MAX  = 11'd900 ,
    parameter   C_DST_IMG_WIDTH_MIN   = 11'd800 ,
    parameter   C_DST_IMG_HEIGHT_MIN  = 11'd600
)
(
    input   wire             clk       ,
    input   wire             rst_n     ,
    input   wire             inf_in    ,
       
    output  reg     [10:0]   c_dst_img_width,
    output  reg     [10:0]   c_dst_img_height,
    output  wire             repeat_led     ,
    output  reg     [2:0]    state = 3'b100, //赋初值
    output  wire             beep //低电平有效
);

localparam NEAREST      = 3'b100  ;
localparam BILINEAR     = 3'b010  ;
localparam BICUBIC      = 3'b001  ;
localparam INF_INCREASE = 8'd21   ;
localparam INF_DECREASE = 8'd7    ;
localparam INF_MODE1    = 8'd12   ;
localparam INF_MODE2    = 8'd24   ;
localparam INF_MODE3    = 8'd94   ;
localparam CNT_MAX      = 24'd12_500_000;//0.5s
localparam CNT_MAX_HALF = 24'd6_250_000; //0.25s

wire    [7:0]   data_inf;
wire            repeat_en;
wire            press_flag;
reg     [23:0]  cnt;
reg     [1:0]   beep_cnt;


always@(posedge clk or negedge rst_n)begin
    if(~rst_n)
        beep_cnt <= 2'd0;
    else begin
        case(beep_cnt)
        2'd0:  //待机状态
        begin
            if(press_flag == 1'b1 
               && (data_inf == INF_MODE1 || data_inf == INF_MODE2 || data_inf == INF_MODE3))
                beep_cnt <= 2'd1;
            else
                beep_cnt <= beep_cnt;
        end
        2'd1: //响一声
        begin
            if(cnt == CNT_MAX && data_inf == INF_MODE1)
                beep_cnt <= 2'd0;
            else if(cnt == CNT_MAX && (data_inf == INF_MODE2 || data_inf == INF_MODE3))
                beep_cnt <= 2'd2;
            else
                beep_cnt <= beep_cnt;
        end
        2'd2: //响两声
        begin
            if(cnt == CNT_MAX && data_inf == INF_MODE2)
                beep_cnt <= 2'd0;
            else if(cnt == CNT_MAX && data_inf == INF_MODE3)
                beep_cnt <= 2'd3;
            else
                beep_cnt <= beep_cnt;
        end
        2'd3: //响三声
        begin
            if(cnt == CNT_MAX && data_inf == INF_MODE3)
                beep_cnt <= 2'd0;
            else
                beep_cnt <= beep_cnt;
        end
        default:
                beep_cnt <= 2'd0;
        endcase
    end
end

always@(posedge clk or negedge rst_n)begin
    if(~rst_n)
        cnt <= 24'd0;
    else if(press_flag == 1'b1 
            && (data_inf == INF_MODE1 || data_inf == INF_MODE2 || data_inf == INF_MODE3))
        cnt <= 24'd1;
    else if(cnt > 24'd0 && cnt < CNT_MAX)
        cnt <= cnt + 1'b1;
    else if(cnt == CNT_MAX)begin
            if((beep_cnt == 2'd1 && data_inf == INF_MODE1)
               ||(beep_cnt == 2'd2 && data_inf == INF_MODE2)
               ||(beep_cnt == 2'd3 && data_inf == INF_MODE3))
                cnt <= 24'd0;
            else
                cnt <= 24'd1;
        end
    else
        cnt <= 24'd0;
end

assign  beep = (cnt > 24'b0 && cnt < CNT_MAX_HALF) ? 1'b0 : 1'b1; 


always@(posedge clk or negedge rst_n)begin
    if(~rst_n)
        state <= NEAREST;
    else if(press_flag == 1'b1)begin
        case(data_inf)
            INF_MODE1 : state <= NEAREST ;
            INF_MODE2 : state <= BILINEAR;
            INF_MODE3 : state <= BICUBIC ;
            default   : state <= state   ;
        endcase
    end
    else
        state <= state;    
end

always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        c_dst_img_width  <= 11'd1280;
        c_dst_img_height <= 11'd780;
    end
    else if(data_inf == 8'd21 && press_flag == 1'b1 
            && c_dst_img_width <= C_DST_IMG_WIDTH_MAX - C_DST_IMG_WIDTH_STEP 
            && c_dst_img_height<= C_DST_IMG_HEIGHT_MAX- C_DST_IMG_HEIGHT_STEP)begin
        c_dst_img_width  <= c_dst_img_width + C_DST_IMG_WIDTH_STEP;
        c_dst_img_height <= c_dst_img_height+ C_DST_IMG_HEIGHT_STEP;
    end
    else if(data_inf == 8'd7 && press_flag == 1'b1
            && c_dst_img_width >= C_DST_IMG_WIDTH_MIN + C_DST_IMG_WIDTH_STEP
            && c_dst_img_height>= C_DST_IMG_HEIGHT_MIN+ C_DST_IMG_HEIGHT_STEP)begin
        c_dst_img_width  <= c_dst_img_width - C_DST_IMG_WIDTH_STEP;
        c_dst_img_height <= c_dst_img_height- C_DST_IMG_HEIGHT_STEP;
    end
    else begin
        c_dst_img_width  <= c_dst_img_width ;
        c_dst_img_height <= c_dst_img_height;
    end
end


led_ctrl led_ctrl_inst
(
/*i*/.sys_clk  (clk       ),
/*i*/.sys_rst_n(rst_n     ),
/*i*/.repeat_en(repeat_en ),

/*o*/.led      (repeat_led)
);


inf_rev inf_rev_inst
(
/*i*/.sys_clk   (clk       ),
/*i*/.sys_rst_n (rst_n     ),
/*i*/.inf_in    (inf_in    ),

/*o*/.data_inf  (data_inf  ),
/*o*/.repeat_en (repeat_en ),
/*o*/.press_flag(press_flag)
);



endmodule