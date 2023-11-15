module my_yuv422_to_rgb(
    input   wire             rst_n    ,   
    input   wire             clk      ,
    input   wire             i_v_sync ,
    input   wire             i_h_sync ,
    input   wire             i_de     ,
    input   wire     [7:0]   c_in     ,
    input   wire     [7:0]   y_in     ,
    
    output	wire     [7:0]   o_r_8b   ,
	output	wire     [7:0]	 o_g_8b   ,
	output	wire     [7:0]	 o_b_8b   ,	
	output	wire			 o_h_sync ,
	output	wire			 o_v_sync ,                                                                                                    
	output	wire			 o_de                                                                                                   
);

wire    [7 : 0]		mid_y_8b;
wire    [7 : 0]		mid_cb_8b;
wire    [7 : 0]		mid_cr_8b;      				
wire                mid_h_sync;
wire                mid_v_sync;
wire                mid_data_en;

yuv422_2_ycbcr444 inst1(
    .rst_n    (rst_n),   
    .clk      (clk),
    .i_v_sync (i_v_sync),
    .i_h_sync (i_h_sync),
    .i_de     (i_de),
    .c_in     (c_in), 
    .y_in     (y_in),

    .o_v_sync (mid_v_sync),
    .o_h_sync (mid_h_sync),
    .o_de     (mid_data_en),
    .y_out    (mid_y_8b),
    .cb_out   (mid_cb_8b),
    .cr_out   (mid_cr_8b)

);

ycbcr_to_rgb inst2(
	.clk      (clk),
	.i_y_8b   (mid_y_8b),
	.i_cb_8b  (mid_cb_8b),
	.i_cr_8b  (mid_cr_8b),
	.i_h_sync (mid_h_sync),
	.i_v_sync (mid_v_sync),
	.i_data_en(mid_data_en),

	.o_r_8b   (o_r_8b),
	.o_g_8b   (o_g_8b),
	.o_b_8b   (o_b_8b),
	.o_h_sync (o_h_sync),
	.o_v_sync (o_v_sync),                                                                                                    
	.o_data_en(o_de)                                                                                                   
);



endmodule