module	my_rgb_to_yuv422(
	input	wire				clk      ,
	input	wire    [7:0]		i_r_8b   ,
	input	wire    [7:0]		i_g_8b   ,
	input	wire    [7:0]		i_b_8b   ,  	
	input   wire				i_h_sync ,
	input	wire				i_v_sync ,
	input	wire				i_data_en,
    
    output  wire                o_hs     ,
	output  wire                o_vs     ,
	output  wire                o_de     ,
	output  wire    [7:0]       o_y      ,
	output  wire    [7:0]       o_c
);

wire    [7 : 0]		o_y_8b   ;
wire    [7 : 0]		o_cb_8b  ;
wire    [7 : 0]		o_cr_8b  ;

wire				o_h_sync ;
wire				o_v_sync ; 
wire				o_data_en;



rgb_to_ycbcr inst1(
    .clk       (clk),
    .i_r_8b    (i_r_8b),
    .i_g_8b    (i_g_8b),
    .i_b_8b    (i_b_8b),
    .i_h_sync  (i_h_sync),
    .i_v_sync  (i_v_sync),
    .i_data_en (i_data_en),
    
    .o_y_8b    (o_y_8b),
    .o_cb_8b   (o_cb_8b),
    .o_cr_8b   (o_cr_8b),
    .o_h_sync  (o_h_sync),
    .o_v_sync  (o_v_sync),                                                                                                  
    .o_data_en (o_data_en)                                                                                                
);

yuv444_yuv422 inst2(
	.sys_clk (clk),
	.i_hs    (o_h_sync),
	.line_end(1'b0),
	.i_vs    (o_v_sync),
	.i_de    (o_data_en),
	.i_y     (o_y_8b),
	.i_cb    (o_cb_8b),
	.i_cr    (o_cr_8b),
    
	.o_hs    (o_hs),
	.o_vs    (o_vs),
	.o_de    (o_de),
	.o_y     (o_y),
	.o_c     (o_c)
);




















endmodule