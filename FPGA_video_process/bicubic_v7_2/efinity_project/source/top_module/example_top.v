`include "ddr3_controller.vh"

//`define Efinity_Debug
//`define AXI_FULL_DEPLEX
module example_top
(

input jtag_inst1_CAPTURE,
input jtag_inst1_DRCK,
input jtag_inst1_RESET,
input jtag_inst1_RUNTEST,
input jtag_inst1_SEL,
input jtag_inst1_SHIFT,
input jtag_inst1_TCK,
input jtag_inst1_TDI,
input jtag_inst1_TMS,
input jtag_inst1_UPDATE,
output jtag_inst1_TDO,
// clk interface
input sys_clk,
input osc_clk,
output osc_en,

// inf&beep interface
input clk_25m,
input inf_in,
output beep ,
// hdmi interface
	
  output [9:0] tmds_tx_clk_TX_DATA,
  output [9:0] tmds_tx_data0_TX_DATA,
  output [9:0] tmds_tx_data1_TX_DATA,
  output [9:0] tmds_tx_data2_TX_DATA,
  output tmds_tx_clk_TX_OE,
  output tmds_tx_clk_TX_RST,
  output tmds_tx_data0_TX_OE,
  output tmds_tx_data1_TX_OE,
  output tmds_tx_data2_TX_OE,
  output tmds_tx_data0_TX_RST,
  output tmds_tx_data1_TX_RST,
  output tmds_tx_data2_TX_RST,
  
  input 			hdmi_rx_fast_clk,
  input 			hdmi_rx_slow_clk,
  input             hdmi_tx_fast_clk,
  input 			hdmi_tx_slow_clk,  
  input             hdmi_tx_4x_clk,
  
  input 			hdmi_rx_clk_RX_DATA,
  input [9:0] hdmi_rx_d0_RX_DATA,
  input [9:0] hdmi_rx_d1_RX_DATA,
  input [9:0] hdmi_rx_d2_RX_DATA,
  output 			hdmi_rx_clk_RX_ENA,
  output 			hdmi_rx_d0_RX_RST,
  output 			hdmi_rx_d0_RX_ENA,
  output 			hdmi_rx_d1_RX_RST,
  output 			hdmi_rx_d1_RX_ENA,
  output 			hdmi_rx_d2_RX_RST,
  output 			hdmi_rx_d2_RX_ENA,   
  input hdmi_rx_pll_LOCKED ,
  input hdmi_tx_pll_LOCKED ,
  output hdmi_rx_pll_RSTN,
  output hdmi_tx_pll_RSTN,
  output 	HPD_N,
  input 	HDMI_5V_N,
  input 	FPGA_HDMI_SCL_IN,
  input 	FPGA_HDMI_SDA_IN,
  output 	FPGA_HDMI_SCL_OUT,
  output 	FPGA_HDMI_SCL_OE,
  output 	FPGA_HDMI_SDA_OUT,
  output 	FPGA_HDMI_SDA_OE,

//ddr3
 output DDR3_PLL_RSTN,
  output SYS_PLL_RSTN,
  input DDR3_PLL_LOCK,
  input SYS_PLL_LOCK,

input core_clk,
input twd_clk,
input tdqss_clk,
input tac_clk,


output reset,
output cs,
output ras,
output cas,
output we,
output cke,
output [15:0]addr,
output [2:0]ba,
output odt,
output [`DRAM_GROUP-1'b1:0] o_dm_hi,
output [`DRAM_GROUP-1'b1:0] o_dm_lo,

input [`DRAM_GROUP-1'b1:0]i_dqs_hi,
input [`DRAM_GROUP-1'b1:0]i_dqs_lo,

input [`DRAM_GROUP-1'b1:0]i_dqs_n_hi,
input [`DRAM_GROUP-1'b1:0]i_dqs_n_lo,


output [`DRAM_GROUP-1'b1:0]o_dqs_hi,
output [`DRAM_GROUP-1'b1:0]o_dqs_lo,

output [`DRAM_GROUP-1'b1:0]o_dqs_n_hi,
output [`DRAM_GROUP-1'b1:0]o_dqs_n_lo,


output [`DRAM_GROUP-1'b1:0]o_dqs_oe,
output [`DRAM_GROUP-1'b1:0]o_dqs_n_oe,

input [`DRAM_WIDTH-1'b1:0] i_dq_hi,
input [`DRAM_WIDTH-1'b1:0] i_dq_lo,

output [`DRAM_WIDTH-1'b1:0] o_dq_hi,
output [`DRAM_WIDTH-1'b1:0] o_dq_lo,

output [`DRAM_WIDTH-1'b1:0] o_dq_oe,

output [2:0]			shift,
output [4:0]			shift_sel,
output 					shift_ena,

// led 
	input nrst,
	input clk_10m,
	output [1:0] b_led,
	input uart_rx,
  	output uart_tx


);
//=====================================================================
////Define  Parameter
//=====================================================================

  /////////////   
  	parameter   AXI_DATA_WIDTH    = 128               ; //AXI Data Width(Bit)
  
  	parameter   DDR_WRITE_FIRST   = 1'h1              ; //1:Write First ; 0: Read First   
  	parameter   AXI_ID_WIDTH    =   8         ;
   //Define  Parameter
  /////////////////////////////////////////////////////////                                
	
	localparam   AXI0_WR_ID        = 8'haa           ; //AXI Write ID
	localparam   AXI0_RD_ID        = 8'h55           ; //AXI Read ID	
		  	
	localparam   AXI_ADDR_WIDTH 	= 32;//Address Width      
	localparam   S_COUNT 					= 1;                          
	localparam   M_COUNT 					= 1;                          
	localparam   AXI_SW 					= AXI_DATA_WIDTH/8;//Write Strobes Width     
	
  /////////////                 
//=========================================================================
//signal define
//=========================================================================
  /////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////
  reg           Ddr_Ready       = 1'h0  ;
  /////////////////////////////////////////////////////////
wire 					cal_done;
wire 					cal_pass;

wire    [S_COUNT*AXI_ID_WIDTH-1:0]  	axi_m_awid;        //
wire    [S_COUNT*AXI_ADDR_WIDTH-1:0]	axi_m_awaddr;
wire    [S_COUNT*8-1:0]         		axi_m_awlen;
wire    [S_COUNT*3-1:0]         		axi_m_awsize;
wire    [S_COUNT*2-1:0]         		axi_m_awburst;
wire    [S_COUNT-1:0]           		axi_m_awlock;
wire    [S_COUNT*4-1:0]         		axi_m_awcache;
wire    [S_COUNT*3-1:0]         		axi_m_awprot;
wire    [S_COUNT-1:0]           		axi_m_awvalid;
wire    [S_COUNT-1:0]           		axi_m_awready;
wire	[S_COUNT*AXI_ID_WIDTH-1:0]		axi_m_wid;
wire    [S_COUNT*AXI_DATA_WIDTH-1:0]	axi_m_wdata;
wire    [S_COUNT*AXI_SW-1:0]    		axi_m_wstrb;
wire    [S_COUNT-1:0]           		axi_m_wlast;
wire    [S_COUNT-1:0]           		axi_m_wvalid;
wire    [S_COUNT-1:0]           		axi_m_wready;
wire    [S_COUNT*AXI_ID_WIDTH-1:0]  	axi_m_bid;
wire    [S_COUNT*2-1:0]         		axi_m_bresp;
wire    [S_COUNT-1:0]           		axi_m_bvalid;
wire    [S_COUNT-1:0]           		axi_m_bready;
wire    [S_COUNT*AXI_ID_WIDTH-1:0]  	axi_m_arid;
wire    [S_COUNT*AXI_ADDR_WIDTH-1:0]	axi_m_araddr;
wire    [S_COUNT*8-1:0]         		axi_m_arlen;
wire    [S_COUNT*3-1:0]         		axi_m_arsize;
wire    [S_COUNT*2-1:0]         		axi_m_arburst;
wire    [S_COUNT-1:0]           		axi_m_arlock;
wire    [S_COUNT-1:0]           		axi_m_arvalid;
wire    [S_COUNT-1:0]           		axi_m_arready;
wire    [S_COUNT*AXI_ID_WIDTH-1:0]  	axi_m_rid;
wire    [S_COUNT*AXI_DATA_WIDTH-1:0]	axi_m_rdata;
wire    [S_COUNT*2-1:0]         		axi_m_rresp;
wire    [S_COUNT-1:0]           		axi_m_rlast;
wire    [S_COUNT-1:0]           		axi_m_rvalid;
wire    [S_COUNT-1:0]          			axi_m_rready;// 

//==============================================================================
//reset porcess module
//==============================================================================
 assign DDR3_PLL_RSTN = nrst;
 assign SYS_PLL_RSTN = nrst;

 reg   [3:0]   Reset_Cnt     = 4'h0  ;
 wire          DdrResetCtrl  ;
 wire		   Sys_Rst_N	;
 wire  		   w_rst_n;
assign w_rst_n = DDR3_PLL_LOCK & SYS_PLL_LOCK ;

  rst_n_piple # (
    .DLY(3)
  )
  rst_n_piple_inst (
    .clk(sys_clk ),
    .rst_n_i(w_rst_n ),
    .rst_n_o(Sys_Rst_N)
  );

  wire    rst_n = Sys_Rst_N;


  assign osc_en = 1'b1;
	reg [25:0] cnt = 'd0;
  always @( posedge sys_clk )
  begin
		cnt <= cnt + 1'b1;
		
  end
  assign b_led[0] = 1'b0;
//=====================================================================================
//hdmi demo
//=====================================================================================
wire                            video_hs;
wire                            video_vs;
wire                            video_de;
wire[7:0]                       video_r;
wire[7:0]                       video_g;
wire[7:0]                       video_b;


wire 			                      rx_hsync;	
wire 			                      rx_vsync;	
wire 			                      rx_de	 ;  
wire [7:0]                      rdata_in;	
wire [7:0]                      gdata_in;	
wire [7:0]                      bdata_in;

	  wire 			ch0_hs_o	;		
	  wire 			ch0_vs_o	;		 
	  wire 			ch0_de_o	;		
	  wire [7:0] 	ch0_rdata	;
	  wire [7:0] 	ch0_gdata	;
	  wire [7:0] 	ch0_bdata	;
	  wire [7:0] 	ch0_zero	;

	  wire [7:0] 	ch0_y;
	  wire [7:0]    ch0_c;
	  wire ch0_vs;
	  wire ch0_hs;
	  wire ch0_de;
	  wire [7:0] y_444		;
	wire [7:0] cb_444		;
	wire [7:0] cr_444		;
	wire 		 h_sync_444	;
	wire 		 v_sync_444	;
	wire 		 de_444		;



	wire 		 h_sync_422	;
	wire 		 v_sync_422	;
	wire 		 de_422		;

	wire 	ch0_v_sync_444;
	wire 	ch0_h_sync_444;
	wire 		ch0_de_444	;	
	wire [7:0]	ch0_y_444	;	
	wire [7:0]	ch0_cb_444	;	
	wire  [7:0]	ch0_cr_444	;	

assign hdmi_rx_clk_RX_ENA = 1'b1;

assign hdmi_rx_d0_RX_ENA = 1'b1; 
assign hdmi_rx_d1_RX_ENA = 1'b1;  
assign hdmi_rx_d2_RX_ENA = 1'b1; 
 

assign hdmi_rx_d0_RX_RST = 1'b0; 
assign hdmi_rx_d1_RX_RST = 1'b0;
assign hdmi_rx_d2_RX_RST = 1'b0;  



//================================================
//  HDMI输入模块开始
//================================================
reg [22:0] wait_cnt;
wire hdmi_rx_rst_n ;
wire hdmi_tx_rst_n ;
//hdmi_rx_pll_LOCKED
always @( posedge osc_clk )
begin
		if( ~HPD_N )
				if( wait_cnt[22])
						wait_cnt <= wait_cnt;
				else
						wait_cnt <= wait_cnt + 1'b1;
		else
				wait_cnt <= 0;
end 

  assign  hdmi_rx_pll_RSTN   = wait_cnt[22];
  assign  hdmi_tx_pll_RSTN   = hdmi_rx_pll_RSTN;
  rst_n_piple # (
    .DLY(3)
  )
  rst_n_hdmi_rx_slow_clk (
    .clk(hdmi_rx_slow_clk ),
    .rst_n_i( hdmi_rx_pll_LOCKED),
    .rst_n_o(hdmi_rx_rst_n)
  );
  
  rst_n_piple # (
    .DLY(3)
  )
  rst_n_hdmi_tx_slow_clk (
    .clk(hdmi_tx_slow_clk ),
    .rst_n_i( hdmi_tx_pll_LOCKED),
    .rst_n_o(hdmi_tx_rst_n)
  );

	hdmi_rx u_hdmi_rx(
 /*i*/.cfg_clk(osc_clk),
 /*i*/.rst_n  (rst_n),
 /*i*/.hdmi_rx_5v_n(HDMI_5V_N),
 /*o*/.hdmi_rx_hpd_n(HPD_N),
 	/*i*/.scl_i		(FPGA_HDMI_SCL_IN), 
	/*o*/.scl_o		(FPGA_HDMI_SCL_OUT), 
	/*o*/.scl_oe	(FPGA_HDMI_SCL_OE),    
	/*i*/.sda_i		(FPGA_HDMI_SDA_IN), 
	/*o*/.sda_o		(FPGA_HDMI_SDA_OUT), 
	/*o*/.sda_oe	(FPGA_HDMI_SDA_OE) 
);    
dvi_decoder u_dvi_decoder(                                                        

/*i*/.pclk          (hdmi_rx_slow_clk),         // double rate pixel clock                
/*i*/.bdata        	(~hdmi_rx_d0_RX_DATA),       // Blue data in                           
/*i*/.gdata       	(~hdmi_rx_d1_RX_DATA),       // Green data in                          
/*i*/.rdata         (~hdmi_rx_d2_RX_DATA),       // Red data in                            
/*i*/.rst_n         (hdmi_rx_rst_n      ),      // external reset input, e.g. reset button
/*o*/.reset         (					),        // rx reset                               
/*o*/.hsync         (rx_hsync	),                // hsync data                             
/*o*/.vsync         (rx_vsync	),                // vsync data                             
/*o*/.de            (rx_de		),                // data enable                            
/*o*/.red           (rdata_in	),                // pixel data out                         
/*o*/.green         (gdata_in	),                // pixel data out                         
/*o*/.blue          (bdata_in	)                 // pixel data out                         
                                                                                
   );    // pixel data out   
          
//==================================================================
//  HDMI输入模块结束
//==================================================================


wire [9:0] tmds_data0;
wire [9:0] tmds_data1;
wire [9:0] tmds_data2;
wire [9:0] tmds_clk ;

//==================================================================
//图像处理模块开始
//==================================================================

localparam NEAREST      = 3'b100  ;
localparam BILINEAR     = 3'b010  ;
localparam BICUBIC      = 3'b001  ;

wire            per_ddr3_vs = ~bicubic_interpolated_vs   ;
wire            per_ddr3_hs = ~bicubic_interpolated_de   ;
wire            per_ddr3_de = bicubic_interpolated_de    ;
wire    [7:0]   per_ddr3_r  = bicubic_interpolated_red   ;
wire    [7:0]   per_ddr3_g  = bicubic_interpolated_green ;
wire    [7:0]   per_ddr3_b  = bicubic_interpolated_blue  ;

wire            bicubic_interpolated_vs    ;
wire            bicubic_interpolated_de    ;
wire    [7:0]   bicubic_interpolated_red   ;
wire    [7:0]   bicubic_interpolated_green ;
wire    [7:0]   bicubic_interpolated_blue  ;

//ddr3输入
wire             i_vs_422;
wire             i_de_422;
wire    [7:0]    i_y_422 ;
wire    [7:0]    i_c_422 ;
//ddr3输出
wire             o_hs_422;
wire             o_vs_422;
wire             o_de_422;
wire    [7:0]    o_y_422 ;
wire    [7:0]    o_c_422 ;


my_rgb_to_yuv422(
	.clk      (hdmi_tx_slow_clk),
	.i_r_8b   (per_ddr3_r ),
	.i_g_8b   (per_ddr3_g ),
	.i_b_8b   (per_ddr3_b ),  	
	.i_h_sync (per_ddr3_hs),
	.i_v_sync (per_ddr3_vs),
	.i_data_en(per_ddr3_de),

    .o_hs     (),
	.o_vs     (i_vs_422   ),
	.o_de     (i_de_422   ),
	.o_y      (i_y_422    ),
	.o_c      (i_c_422    )
);

my_yuv422_to_rgb(
    .rst_n    (rst_n),   
    .clk      (hdmi_tx_slow_clk),
    .i_v_sync (o_vs_422),
    .i_h_sync (o_hs_422),
    .i_de     (o_de_422),
    .c_in     (o_c_422 ),
    .y_in     (o_y_422 ),

    .o_r_8b   (tx_r ),
	.o_g_8b   (tx_g ),
	.o_b_8b   (tx_b ),	
	.o_h_sync (tx_hs),
	.o_v_sync (tx_vs),                                                                                                    
	.o_de     (tx_de)                                                                                              
);



bicubic_interpolation bicubic_inst

(
/*i*/.C_SRC_IMG_WIDTH   (11'd640),
/*i*/.C_SRC_IMG_HEIGHT  (11'd480),
/*i*/.C_DST_IMG_WIDTH   (11'd1600),
/*i*/.C_DST_IMG_HEIGHT  (11'd900),
/*i*/.C_X_RATIO         (16'd26214),
/*i*/.C_Y_RATIO         (16'd34952),

/*i*/.clk_in1           (hdmi_rx_slow_clk),
/*i*/.clk_in2           (hdmi_tx_slow_clk),
/*i*/.clk_in2_4x        (hdmi_tx_4x_clk  ),
/*i*/.rst_n             (rst_n           ),

/*i*/.per_img_vsync     (~rx_vsync),       //  Prepared Image data vsync valid signal   
/*i*/.per_img_href      (rx_de    ),       //  Prepared Image data href vaild  signal   
/*i*/.per_img_red       (rdata_in ),       //  Prepared Image brightness input             
/*i*/.per_img_green     (gdata_in ),                                                    
/*i*/.per_img_blue      (bdata_in ),                                                      

/*o*/.post_img_vsync    (bicubic_interpolated_vs   ),       //  processed Image data vsync valid signal   
/*o*/.post_img_href     (bicubic_interpolated_de   ),       //  processed Image data href vaild  signal 
/*o*/.post_img_red      (bicubic_interpolated_red  ),       //  processed Image brightness output      
/*o*/.post_img_green    (bicubic_interpolated_green),                                                
/*o*/.post_img_blue     (bicubic_interpolated_blue )                                                  
);                                                                                                   
//==================================================================
//图像处理模块结束
//==================================================================


//    ___  ___  ___  ___  ___.---------------.
//  .'\__\'\__\'\__\'\__\'\__,`   .  ____ ___ \
//  |\/ __\/ __\/ __\/ __\/ _:\   |`.  \  \___ \
//   \\'\__\'\__\'\__\'\__\'\_`.__|""`. \  \___ \
//    \\/ __\/ __\/ __\/ __\/ __:                \
//     \\'\__\'\__\'\__\ \__\'\_;-----------------`
//      \\/   \/   \/   \/   \/ :                 |
//       \|______________________;________________|


//==================================================================
//HDMI输出模块开始
//==================================================================
wire    [7:0]   tx_r;
wire    [7:0]   tx_g;
wire    [7:0]   tx_b;
wire            tx_vs;
wire            tx_hs;
wire            tx_de;


//RGB信号输出
dvi_encoder dvi_encoder_m0
(
	.pixelclk      (hdmi_tx_slow_clk   ),// system clock
	.pixelclk5x    (hdmi_tx_fast_clk   ),// system clock x5
	.rstin         (~hdmi_tx_rst_n     ),// reset
	.blue_din      (tx_b  ), //(bdata_in	),   ////   (video_b            ),//
	.green_din     (tx_g  ), //(gdata_in	),   ////(video_g            ),//   
	.red_din       (tx_r  ), //(rdata_in	),   ////(video_r            ),//   
	.hsync         (tx_hs ),         //(rx_hsync	),   ////(video_hs           ),//   
	.vsync         (tx_vs ),         //(rx_vsync	),   //// (video_vs           ),//  
	.de            (tx_de ),         //(rx_de		),   //  // (video_de           ),//

	.tmds_data0    (tmds_data0),
    .tmds_data1    (tmds_data1),
    .tmds_data2    (tmds_data2),
    .tmds_clk      (tmds_clk  )
);

//==================================================================
//HDMI输出模块结束
//==================================================================

assign tmds_tx_data0_TX_OE = 1'b1;
assign tmds_tx_data1_TX_OE = 1'b1;
assign tmds_tx_data2_TX_OE = 1'b1;
assign tmds_tx_clk_TX_OE   = 1'b1;

assign tmds_tx_data0_TX_RST = 1'b0;
assign tmds_tx_data1_TX_RST = 1'b0;
assign tmds_tx_data2_TX_RST = 1'b0;
assign tmds_tx_clk_TX_RST   = 1'b0;
assign tmds_tx_clk_TX_DATA   = ~tmds_clk;
assign tmds_tx_data0_TX_DATA = ~tmds_data0;
assign tmds_tx_data1_TX_DATA = ~tmds_data1;
assign tmds_tx_data2_TX_DATA = ~tmds_data2;
//=======================================================================
//DDR3 soft Controller
//=======================================================================
parameter START_ADDR = 32'h000000;
parameter END_ADDR = 32'h1ffffff;
 wire [7:0] m_aid_0;
	  wire [31:0] m_aaddr_0;
	  wire [7:0]  m_alen_0;
	  wire [2:0]  m_asize_0;
	  wire [1:0]  m_aburst_0;
	  wire [1:0]  m_alock_0;
	  wire		m_avalid_0;
	  wire		m_aready_0;
	  
	  wire		m_atype_0;
	  wire [7:0]  m_wid_0;
	  wire [127:0] m_wdata_0;
	  wire [15:0]	m_wstrb_0;
	  wire		m_wlast_0;
	  wire		m_wvalid_0;
	  wire		m_wready_0;
	  wire [3:0] m_rid_0;
	  wire [127:0] m_rdata_0;
	  wire		m_rlast_0;
	  wire		m_rvalid_0;
	  wire		m_rready_0;
	  wire [1:0] m_rresp_0;
	  wire [7:0] m_bid_0;
	  wire [1:0] m_bresp_0;
	  wire		m_bvalid_0;
	  wire		m_bready_0;
//===============================================
//  frame buffer vga_timing_generater parameter
//===============================================
localparam       H_PRE_PORCH  = 13'd24;  //13'd14;  //13'd110 	;//24	;    //88;
localparam       H_SYNC 	  = 13'd80;  //13'd56;  //13'd40 	;//136  ;    //44;
localparam       V_PRE_PORCH  = 13'd1;   //13'd1;   //13'd5 	;//	3     ;      //4;
localparam       V_SYNC 	  = 13'd3;   //13'd3;   //13'd5 	;//6      ;      //5;
//==============================================
//  frame buffer
//==============================================
frame_buffer #(
	.I_VID_WIDTH 	(16),                      			
	.O_VID_WIDTH 	(16),                    
	.AXI_ID_WIDTH	( AXI_ID_WIDTH 	),       
	.AXI_WR_ID		(	AXI0_WR_ID	),       
	.AXI_RD_ID		( AXI0_RD_ID    ),       
	.AXI_ADDR_WIDTH (AXI_ADDR_WIDTH ),       
	.AXI_DATA_WIDTH (AXI_DATA_WIDTH	),       
	.START_ADDR		(0	 ),              
	.BURST_LEN 		(8'd128),           
	.FB_NUM			(3)                    
)u_frame_buffer_ch0(                       
/*i*/.i_clk			(hdmi_tx_slow_clk   ),// (CLK_148P5M),//	(VI_CLK3_PLL		),    //(CLK_148P5M   ),//    
///*i*/.i_hs		(),//(rx_hsync 			),// (sync_hs3  ),//(e3_h							),  //(sw0_hs 			),//
/*i*/.i_vs			(i_vs_422), //video_scale_data_vs  //(rx_vsync 			),// (sync_vs2  ),//(e3_v							),  //(sw0_vs 			),//
/*i*/.i_de			(i_de_422), //video_scale_data_de  //(rx_de 				),// (sync_de2  ),//(e3_de						),    //(sw0_de 			),//
/*i*/.vin 			({i_y_422,i_c_422}),//video_scale_data_out //({rdata_in,gdata_in,bdata_in}			),// (sync_vout2),//({e3_yout,e3_cout}),   //(sw0_vout			),//
                  
/*i*/.o_clk			(hdmi_tx_slow_clk	),//(clk_o),//
/*i*/.o_hs    		(o_hs_422),//(ch0_hs_o			), //active high
/*i*/.o_vs    		(o_vs_422),//(ch0_vs_o			), //active high
/*i*/.o_de    		(o_de_422),//(ch0_de_o			), //active high
/*i*/.vout    		({o_y_422,o_c_422}),//({ch0_rdata,ch0_gdata,ch0_bdata}			),


/*i*/.H_PRE_PORCH 	(H_PRE_PORCH  		),//( 13'd10 			),//(H_PRE_PORCH  ),//
/*i*/.H_SYNC 	 	(H_SYNC 	 		),//( 13'd10 			),//(H_SYNC 	 		),//
/*i*/.H_VALID 	 	(13'd1600	        ),//( 13'd146 		),//(H_VALID 	 	  ),//
/*i*/.H_BACK_PORCH	(13'd96             ),//( 13'd10 			),//(H_BACK_PORCH ),//
/*i*/.V_PRE_PORCH 	(V_PRE_PORCH  		),//( 13'd5 			),//(V_PRE_PORCH  ),//
/*i*/.V_SYNC 	 	(V_SYNC 	 		),//( 13'd5 			),//(V_SYNC 	 		),//
/*i*/.V_VALID 	 	(13'd900 	        ),//( 13'd119 		),//(V_VALID 	 	  ),//
/*i*/.V_BACK_PORCH	(13'd96             ),//( 13'd5 			),//(V_BACK_PORCH ),//
/*i*/.MAX_VID_WIDTH	(11'd1600           ),    // output img width
/*i*/.MAX_VID_HIGHT	(11'd900            ),    // output img hight

/*i*/.axi_clk		(sys_clk 		), 
/*i*/.rst_n			(Sys_Rst_N		),

/*o*/.axi_awid		(axi_m_awid			),      
/*o*/.axi_awaddr	(axi_m_awaddr		),    
/*o*/.axi_awlen		(axi_m_awlen		),     
/*o*/.axi_awsize	(axi_m_awsize		),    
/*o*/.axi_awburst	(axi_m_awburst		),   
/*o*/.axi_awlock	(axi_m_awlock		),    
/*o*/.axi_awvalid	(axi_m_awvalid		),   
/*i*/.axi_awready	(axi_m_awready		),  
                                         
/*O*/.axi_wid		(axi_m_wid			),
/*o*/.axi_wdata		(axi_m_wdata		),     
/*o*/.axi_wstrb		(axi_m_wstrb		),     
/*o*/.axi_wlast		(axi_m_wlast		),     
/*o*/.axi_wvalid	(axi_m_wvalid		),    
/*i*/.axi_wready	(axi_m_wready		),
                                    				              	
/*i*/.axi_bid		(axi_m_bid			),       
/*o*/.axi_bresp		(axi_m_bresp		),     
/*i*/.axi_bvalid	(axi_m_bvalid		),    
/*o*/.axi_bready	(axi_m_bready		),
                                                    
/*o*/.axi_arid		(axi_m_arid			),      
/*o*/.axi_araddr	(axi_m_araddr		),    
/*o*/.axi_arlen		(axi_m_arlen	    ),     
/*o*/.axi_arsize	(axi_m_arsize		),    
/*o*/.axi_arburst	(axi_m_arburst	 	),   
/*o*/.axi_arlock	(axi_m_arlock	 	),    
/*o*/.axi_arvalid	(axi_m_arvalid		),   
/*i*/.axi_arready	(axi_m_arready		),
                                        
/*i*/.axi_rid  		(axi_m_rid			),       
/*i*/.axi_rdata		(axi_m_rdata		),
/*i*/.axi_rresp		(axi_m_rresp	 	),     
/*i*/.axi_rlast		(axi_m_rlast	 	),     
/*i*/.axi_rvalid	(axi_m_rvalid	 	),    
/*o*/.axi_rready	(axi_m_rready		)     
);

  always @( posedge sys_clk or negedge Sys_Rst_N)
  begin
		if( !Sys_Rst_N )
			Ddr_Ready <= 1'b0;
		else if( cal_done & cal_pass )	
			Ddr_Ready <= 1'b1;
  end
  

efx_ddr3_axi inst_ddr3_axi
	  (	
	  	.core_clk		(core_clk),
		.tac_clk		(tac_clk),
		.twd_clk		(twd_clk),	
		.tdqss_clk	(tdqss_clk),
			
		.axi_clk	(sys_clk 		),
		.nrst		(Sys_Rst_N		),
	  
	  	
	  	.reset		( reset           ) ,           
		.cs			( cs              ) ,              
		.ras		( ras             ) ,              
		.cas		( cas             ) ,              
		.we			( we              ) ,              
		.cke		( cke             ) ,              
		.addr		( addr            ) ,              
		.ba			( ba              ) ,              
		.odt		( odt             ) ,              
		.o_dm_hi	( o_dm_hi         ) ,                 
		.o_dm_lo	( o_dm_lo         ) ,                 
		.i_dq_hi	( i_dq_hi         ) ,                    
		.i_dq_lo	( i_dq_lo         ) ,                    							
		.o_dq_hi	(o_dq_hi),                  
		.o_dq_lo	(o_dq_lo),                  
		.o_dq_oe	(o_dq_oe),                  
		.i_dqs_hi	( i_dqs_hi        ) ,          
		.i_dqs_lo	( i_dqs_lo        ) ,          
		.i_dqs_n_hi	(i_dqs_n_hi			),            
		.i_dqs_n_lo	(i_dqs_n_lo		),            
		.o_dqs_hi	(o_dqs_hi		),
		.o_dqs_lo	(o_dqs_lo		),
		.o_dqs_n_hi	(o_dqs_n_hi		),
		.o_dqs_n_lo	(o_dqs_n_lo		),
		.o_dqs_oe	(o_dqs_oe		),
		.o_dqs_n_oe	(o_dqs_n_oe		),
	  	
	  	//TO Tester
	  	.i_avalid(m_avalid_0),
	  	.o_aready(m_aready_0),
	  	.i_aaddr(m_aaddr_0),
	  	.i_aid(m_aid_0),
	  	.i_alen(m_alen_0),
	  	.i_asize(m_asize_0),
	  	.i_aburst(m_aburst_0),
	  	.i_alock(m_alock_0),
	  	.i_atype(m_atype_0),
	  	
	  	.i_wid(m_wid_0),
	  	.i_wvalid(m_wvalid_0),
	  	.o_wready(m_wready_0),
	  	.i_wdata(m_wdata_0),
	  	.i_strb(m_wstrb_0),
	  	.i_wlast(m_wlast_0),
	  	
	  	.o_bvalid(m_bvalid_0),
	  	.i_bready(m_bready_0),
	  	.o_bid(m_bid_0),
	  	
	  	.o_rvalid(m_rvalid_0),
	  	.i_rready(m_rready_0),
	  	.o_rdata(m_rdata_0),
	  	.o_rid(m_rid_0),
	  	.o_rresp(m_rresp_0),
	  	.o_rlast(m_rlast_0),
	  
	  	.shift(shift),
	  	.shift_sel(shift_sel),
	  	.shift_ena(shift_ena),
	  	.cal_ena(1'b1),
	  	.cal_done(cal_done),
	  	.cal_pass(cal_pass)
	  ); 




Axi4FullDeplex
  # (
      .DDR_WRITE_FIRST  ( DDR_WRITE_FIRST ),
      .AXI_DATA_WIDTH   ( AXI_DATA_WIDTH  )
    )
  U2_Axi4FullDeplex_0
  (
    //System Signal
    .SysClk   ( Axi0Clk    ), //System Clock
    .Reset_N  ( axi0_rst_n   ), //System Reset
    //Axi Slave Interfac Signal
    .AWID     ( axi_m_awid      ),  //(O)[WrAddr]Write address ID.
    .AWADDR   ( axi_m_awaddr    ),  //(O)[WrAddr]Write address.
    .AWLEN    ( axi_m_awlen     ),  //(O)[WrAddr]Burst length.
    .AWSIZE   ( axi_m_awsize    ),  //(O)[WrAddr]Burst size.
    .AWBURST  ( axi_m_awburst   ),  //(O)[WrAddr]Burst type.
    .AWLOCK   ( axi_m_awlock    ),  //(O)[WrAddr]Lock type.
    .AWVALID  ( axi_m_awvalid   ),  //(O)[WrAddr]Write address valid.
    .AWREADY  ( axi_m_awready   ),  //(I)[WrAddr]Write address ready.
    ///////////                
    .WID      ( axi_m_wid       ),  //(O)[WrData]Write ID tag.
    .WDATA    ( axi_m_wdata     ),  //(O)[WrData]Write data.
    .WSTRB    ( axi_m_wstrb     ),  //(O)[WrData]Write strobes.
    .WLAST    ( axi_m_wlast     ),  //(O)[WrData]Write last.
    .WVALID   ( axi_m_wvalid    ),  //(O)[WrData]Write valid.
    .WREADY   ( axi_m_wready    ),  //(I)[WrData]Write ready.
    ///////////                
    .BID      ( axi_m_bid       ),  //(I)[WrResp]Response ID tag.
    .BVALID   ( axi_m_bvalid    ),  //(I)[WrResp]Write response valid.
    .BREADY   ( axi_m_bready    ),   //(O)[WrResp]Response ready.
    ///////////                 
    .ARID     ( axi_m_arid      ),  //(O)[RdAddr]Read address ID.
    .ARADDR   ( axi_m_araddr    ),  //(O)[RdAddr]Read address.
    .ARLEN    ( axi_m_arlen     ),  //(O)[RdAddr]Burst length.
    .ARSIZE   ( axi_m_arsize    ),  //(O)[RdAddr]Burst size.
    .ARBURST  ( axi_m_arburst   ),  //(O)[RdAddr]Burst type.
    .ARLOCK   ( axi_m_arlock    ),  //(O)[RdAddr]Lock type.
    .ARVALID  ( axi_m_arvalid   ),  //(O)[RdAddr]Read address valid.
    .ARREADY  ( axi_m_arready   ),  //(I)[RdAddr]Read address ready.
    ///////////                
    .RID      ( axi_m_rid       ),  //(I)[RdData]Read ID tag.
    .RDATA    ( axi_m_rdata     ),  //(I)[RdData]Read data.
    .RRESP    ( axi_m_rresp     ),  //(I)[RdData]Read response.
    .RLAST    ( axi_m_rlast     ),  //(I)[RdData]Read last.
    .RVALID   ( axi_m_rvalid    ),  //(I)[RdData]Read valid.
    .RREADY   ( axi_m_rready    ),  //(O)[RdData]Read ready.
    /////////////
    //DDR Controner AXI4 Signal
    .aid      ( m_aid_0       ),  //(O)[Addres] Address ID
    .aaddr    ( m_aaddr_0     ),  //(O)[Addres] Address
    .alen     ( m_alen_0      ),  //(O)[Addres] Address Brust Length
    .asize    ( m_asize_0     ),  //(O)[Addres] Address Burst size
    .aburst   ( m_aburst_0    ),  //(O)[Addres] Address Burst type
    .alock    ( m_alock_0     ),  //(O)[Addres] Address Lock type
    .avalid   ( m_avalid_0    ),  //(O)[Addres] Address Valid
    .aready   ( m_aready_0    ),  //(I)[Addres] Address Ready
    .atype    ( m_atype_0     ),  //(O)[Addres] Operate Type 0=Read, 1=Write
    /////////// /////////     
    .wid      ( m_wid_0       ),  //(O)[Write]  ID
    .wdata    ( m_wdata_0     ),  //(O)[Write]  Data
    .wstrb    ( m_wstrb_0     ),  //(O)[Write]  Data Strobes(Byte valid)
    .wlast    ( m_wlast_0     ),  //(O)[Write]  Data Last
    .wvalid   ( m_wvalid_0    ),  //(O)[Write]  Data Valid
    .wready   ( m_wready_0    ),  //(I)[Write]  Data Ready
    /////////// /////////     
    .rid      ( m_rid_0       ),  //(I)[Read]   ID
    .rdata    ( m_rdata_0     ),  //(I)[Read]   Data
    .rlast    ( m_rlast_0     ),  //(I)[Read]   Data Last
    .rvalid   ( m_rvalid_0    ),  //(I)[Read]   Data Valid
    .rready   ( m_rready_0    ),  //(O)[Read]   Data Ready
    .rresp    ( m_rresp_0     ),  //(I)[Read]   Response
    /////////// /////////     
    .bid      ( m_bid_0       ),  //(I)[Answer] Response Write ID
    .bvalid   ( m_bvalid_0    ),  //(I)[Answer] Response valid
    .bready   ( m_bready_0    )   //(O)[Answer] Response Ready
  );



//=================================================================================
//
//=================================================================================
//=============================================================
//
//=============================================================
//=============================================================
//
//=============================================================





endmodule



