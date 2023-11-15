module  led_ctrl
(
    input   wire    sys_clk  ,
    input   wire    sys_rst_n,
    input   wire    repeat_en,
    
    output  wire    led
);

parameter   CNT_MAX = 22'd137_5000;

wire    rise_flag;
reg     [21:0]  cnt;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 0)
        cnt <= CNT_MAX;
    else    if(rise_flag == 1)
        cnt <= 22'd0;
    else    if(cnt < CNT_MAX)
        cnt <= cnt + 22'd1;
    else
        cnt <= cnt;

assign  led = ((cnt >= 22'd0) && (cnt < CNT_MAX));

edge_gen    edge_gen_inst1
(
    .sys_clk  (sys_clk),
    .sys_rst_n(sys_rst_n),
    .inf_in   (repeat_en),

    .rise_flag(rise_flag)
);

endmodule