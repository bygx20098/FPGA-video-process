module  inf_rev
(
    input   wire            sys_clk  ,
    input   wire            sys_rst_n,
    input   wire            inf_in   ,
    
    output  reg     [7:0]   data_inf ,
    output  wire            repeat_en,
    output  reg             press_flag
);

parameter   TIME_0_56ms =  19'd1_3999,
            TIME_1_69ms =  19'd4_2249,
            TIME_2_25ms =  19'd5_6249,
            TIME_4_5ms  = 19'd11_2499,
            TIME_9ms    = 19'd22_4999,
            ERROR_RANGE =    19'd7500; //+-0.2ms 
            
parameter   IDLE  = 5'b00001,
            _9MS  = 5'b00010,
            ARBIT = 5'b00100,
            DATA  = 5'b01000,
            REPEAT= 5'b10000;
 
reg     [4:0]  state;
wire    rise_flag;
wire    fall_flag;
wire    flag_9ms;
wire    flag_4_5ms;
wire    flag_2_25ms;
wire    flag_1_69ms;
wire    flag_0_56ms;
wire    finish_flag;
reg     press_flag_reg;
reg     [18:0]  cnt;
reg     [31:0]  data;
reg     [5:0]   data_state;

//状态机
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 0)
        state <= IDLE;
    else    case(state)
                IDLE:   if(fall_flag == 1)
                            state <= _9MS;
                        else
                            state <= IDLE;
                            
                _9MS:   if((rise_flag == 1) && (flag_9ms == 1))
                            state <= ARBIT;
                        else    if((rise_flag == 1) && (flag_9ms == 0))
                            state <= IDLE;
                        else    
                            state <= _9MS;
                            
                ARBIT:  if((fall_flag == 1) && (flag_4_5ms == 1))
                            state <= DATA;
                        else    if((fall_flag == 1) && (flag_2_25ms == 1))
                            state <= REPEAT;
                        else    if((fall_flag == 1) && (flag_4_5ms == 0) && (flag_2_25ms == 0))
                            state <= IDLE;
                        else
                            state <= ARBIT;
                            
                DATA:   if((finish_flag == 1) ||
                           ((rise_flag == 1) && (flag_0_56ms == 0)) ||
                           ((fall_flag == 1) && (flag_0_56ms == 0) && (flag_1_69ms == 0)))
                            state <= IDLE;
                        else
                            state <= DATA;
                            
                REPEAT: if(rise_flag  == 1)
                            state <= IDLE;
                        else
                            state <= REPEAT;
                            
                default:    state <= IDLE;
 
 
            endcase

//计时器 
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 0)
        cnt <= 19'b0;
    else    if((state == IDLE) || (rise_flag == 1) || (fall_flag == 1))
        cnt <= 19'b0;
    else    
        cnt <= cnt + 19'b1;

assign  flag_0_56ms = ((cnt > (TIME_0_56ms - ERROR_RANGE)) &&
                       (cnt < (TIME_0_56ms + ERROR_RANGE)));

assign  flag_1_69ms = ((cnt > (TIME_1_69ms - ERROR_RANGE)) &&
                       (cnt < (TIME_1_69ms + ERROR_RANGE)));
                       
assign  flag_2_25ms = ((cnt > (TIME_2_25ms - ERROR_RANGE)) &&
                       (cnt < (TIME_2_25ms + ERROR_RANGE)));

assign  flag_4_5ms  = ((cnt > (TIME_4_5ms - ERROR_RANGE)) &&
                       (cnt < (TIME_4_5ms + ERROR_RANGE)));

assign  flag_9ms    = ((cnt > (TIME_9ms - ERROR_RANGE)) &&
                       (cnt < (TIME_9ms + ERROR_RANGE)));                       

//数据接收

assign  finish_flag = ((rise_flag == 1) && (data_state == 6'd32));

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 0)
        data_state <= 6'd0;
    else    if((finish_flag == 1) || (state != DATA))
        data_state <= 6'd0;
    else    if(fall_flag == 1)
        data_state <= data_state + 6'd1;
    else
        data_state <= data_state;
        
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 0)
        data <= 32'd0;
    else    if(state == DATA)
        if((fall_flag == 1) && (flag_1_69ms == 1))
            data[data_state] <= 1'b1;
        else    if((fall_flag == 1) && (flag_0_56ms == 1))
            data[data_state] <= 1'b0;
        else
            data[data_state] <= data[data_state];
    else
        data <= data;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 0)
        data_inf <= 8'd0;
    else    if((data[7:0] == ~data[15:8]) &&
               (data[23:16] == ~data[31:24]) &&
               (finish_flag == 1))
        data_inf <= data[23:16];      
    else
        data_inf <= data_inf;

//重复信号
assign  repeat_en = (state == REPEAT);

always@(posedge sys_clk)begin
    press_flag_reg <= finish_flag;
    press_flag <= press_flag_reg;
end
    
    
//边沿检测
edge_gen    edge_gen_inst1
(
    .sys_clk  (sys_clk),
    .sys_rst_n(sys_rst_n),
    .inf_in   (inf_in),

    .rise_flag(rise_flag),
    .fall_flag(fall_flag)
);

endmodule
