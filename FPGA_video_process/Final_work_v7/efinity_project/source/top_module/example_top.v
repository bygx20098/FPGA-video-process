`include "ddr3_controller.vh"

//`define Efinity_Debug
//`define AXI_FULL_DEPLEX
module example_top
(

// riscv jtag debugger
input   jtag_inst1_SEL     ,
input   jtag_inst1_TDI     ,
input   jtag_inst1_CAPTURE ,
input   jtag_inst1_SHIFT   ,
output   jtag_inst1_TDO    ,
input   jtag_inst1_TCK     ,


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


//flash spi
output		system_spi_0_io_sclk_write,
output		system_spi_0_io_data_0_writeEnable,
input		system_spi_0_io_data_0_read,
output		system_spi_0_io_data_0_write,
output		system_spi_0_io_data_1_writeEnable,
input		system_spi_0_io_data_1_read,
output		system_spi_0_io_data_1_write,
output		system_spi_0_io_ss,

//riscv uart
output		system_uart_0_io_txd,
input		system_uart_0_io_rxd,

//riscv gpio
input [3:0] system_gpio_0_io_read,
output [3:0] system_gpio_0_io_write,
output [3:0] system_gpio_0_io_writeEnable,

output      memoryCheckerPass,
output      systemClk_rstn

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
 assign memoryCheckerPass=1'b0;
assign systemClk_rstn 	= 1'b1;

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

reg             per_ddr3_vs;
reg             per_ddr3_hs;
reg             per_ddr3_de;
reg     [7:0]   per_ddr3_r ;
reg     [7:0]   per_ddr3_g ;
reg     [7:0]   per_ddr3_b ;

wire            nearest_interpolated_vs   ;
wire            nearest_interpolated_de   ;
wire    [7:0]   nearest_interpolated_red  ;
wire    [7:0]   nearest_interpolated_green;
wire    [7:0]   nearest_interpolated_blue ;
wire            bilinear_interpolated_vs   ;
wire            bilinear_interpolated_de   ;
wire    [7:0]   bilinear_interpolated_red  ;
wire    [7:0]   bilinear_interpolated_green;
wire    [7:0]   bilinear_interpolated_blue ;
wire            bicubic_interpolated_vs   ;
wire            bicubic_interpolated_de   ;
wire    [7:0]   bicubic_interpolated_red  ; 
wire    [7:0]   bicubic_interpolated_green;
wire    [7:0]   bicubic_interpolated_blue ;



reg     [26:0]   c_src_img_width  = 27'd640;
reg     [26:0]   c_src_img_height = 27'd480;
reg     [2:0]    state_reg;
wire    [10:0]   c_dst_img_width;
wire    [10:0]   c_dst_img_height;
wire    [26:0]   c_x_radio;
wire    [26:0]   c_y_radio;
wire    [2:0]    state;
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

wire    [7:0]           bram_a_wdata_r;
wire    [7:0]           bram_a_wdata_g;
wire    [7:0]           bram_a_wdata_b;
wire    [11:0]          bram_a_waddr  ;
wire                    bram1_a_wenb  ;
wire                    bram2_a_wenb  ;

wire           [11:0]          even_bram1_raddr  ;
wire           [11:0]          odd_bram1_raddr   ;
wire           [11:0]          even_bram2_raddr  ;
wire           [11:0]          odd_bram2_raddr   ;
wire           [ 7:0]          even_bram1_r_rdata;
wire           [ 7:0]          odd_bram1_r_rdata ;
wire           [ 7:0]          even_bram2_r_rdata;
wire           [ 7:0]          odd_bram2_r_rdata ;
wire           [ 7:0]          even_bram1_g_rdata;
wire           [ 7:0]          odd_bram1_g_rdata ;
wire           [ 7:0]          even_bram2_g_rdata;
wire           [ 7:0]          odd_bram2_g_rdata ;
wire           [ 7:0]          even_bram1_b_rdata;
wire           [ 7:0]          odd_bram1_b_rdata ;
wire           [ 7:0]          even_bram2_b_rdata;
wire           [ 7:0]          odd_bram2_b_rdata ;



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

inf_control
#(
    .C_DST_IMG_WIDTH_STEP (11'd40  ),
    .C_DST_IMG_HEIGHT_STEP(11'd15  ),
    .C_DST_IMG_WIDTH_MAX  (11'd1600),
    .C_DST_IMG_HEIGHT_MAX (11'd900 ),
    .C_DST_IMG_WIDTH_MIN  (11'd800 ),
    .C_DST_IMG_HEIGHT_MIN (11'd600 )
)inf_control_inst
(
/*i*/.clk             (clk_25m         ),
/*i*/.rst_n           (rst_n           ),
/*i*/.inf_in          (inf_in          ),

/*o*/.c_dst_img_width (c_dst_img_width ),
/*o*/.c_dst_img_height(c_dst_img_height),
/*o*/.repeat_led      (/*b_led[1] */       ),
/*o*/.state           (state           ),
/*o*/.beep            (beep            )
);

always@(posedge hdmi_tx_slow_clk) state_reg <= state;//变换时钟域

//缩放算法的多路选择器
always@(posedge hdmi_tx_slow_clk or negedge rst_n)begin
    if(~rst_n)begin
        per_ddr3_vs <= ~nearest_interpolated_vs  ;
        per_ddr3_hs <= ~nearest_interpolated_de  ;
        per_ddr3_de <= nearest_interpolated_de   ;
        per_ddr3_r  <= nearest_interpolated_red  ;
        per_ddr3_g  <= nearest_interpolated_green;
        per_ddr3_b  <= nearest_interpolated_blue ;
    end
    else begin
        case(state_reg)
            NEAREST  : 
            begin
                per_ddr3_vs <= ~nearest_interpolated_vs  ;
                per_ddr3_hs <= ~nearest_interpolated_de  ;
                per_ddr3_de <= nearest_interpolated_de   ;
                per_ddr3_r  <= nearest_interpolated_red  ;
                per_ddr3_g  <= nearest_interpolated_green;
                per_ddr3_b  <= nearest_interpolated_blue ;
            end
            BILINEAR :
            begin
                per_ddr3_vs <= ~bilinear_interpolated_vs  ;
                per_ddr3_hs <= ~bilinear_interpolated_de  ;
                per_ddr3_de <= bilinear_interpolated_de   ;
                per_ddr3_r  <= bilinear_interpolated_red  ;
                per_ddr3_g  <= bilinear_interpolated_green;
                per_ddr3_b  <= bilinear_interpolated_blue ;               
            end
            BICUBIC  :
            begin
                per_ddr3_vs <= ~bicubic_interpolated_vs   ;
                per_ddr3_hs <= ~bicubic_interpolated_de   ;
                per_ddr3_de <= bicubic_interpolated_de    ;
                per_ddr3_r  <= bicubic_interpolated_red   ;
                per_ddr3_g  <= bicubic_interpolated_green ;
                per_ddr3_b  <= bicubic_interpolated_blue  ;
            end
            default  :
            begin
                per_ddr3_vs <= ~nearest_interpolated_vs  ;
                per_ddr3_hs <= ~nearest_interpolated_de  ;
                per_ddr3_de <= nearest_interpolated_de   ;
                per_ddr3_r  <= nearest_interpolated_red  ;
                per_ddr3_g  <= nearest_interpolated_green;
                per_ddr3_b  <= nearest_interpolated_blue ;
            end
        endcase
    end
end





radio_calculator x_radio_calculator(
    .numer   (c_src_img_width<<16),
    .denom   (c_dst_img_width),
    .clken   (1'b1),
    .clk     (hdmi_tx_slow_clk),
    .reset   (~rst_n),
    .quotient(c_x_radio),
    .remain  ()
);

radio_calculator y_radio_calculator(
    .numer   (c_src_img_height<<16),
    .denom   (c_dst_img_height),
    .clken   (1'b1),
    .clk     (hdmi_tx_slow_clk),
    .reset   (~rst_n),
    .quotient(c_y_radio),
    .remain  ()
);

rgb_bram_top rgb_bram_top_inst
(
    .clk_in1           (hdmi_rx_slow_clk),
    .clk_in2           (hdmi_tx_slow_clk),

    .bram_a_wdata_r    (bram_a_wdata_r),
    .bram_a_wdata_g    (bram_a_wdata_g),
    .bram_a_wdata_b    (bram_a_wdata_b),
    .bram_a_waddr      (bram_a_waddr),
    .bram1_a_wenb      (bram1_a_wenb),
    .bram2_a_wenb      (bram2_a_wenb),

    .even_bram1_raddr  (even_bram1_raddr  ),
    .odd_bram1_raddr   (odd_bram1_raddr   ),
    .even_bram2_raddr  (even_bram2_raddr  ),
    .odd_bram2_raddr   (odd_bram2_raddr   ),
    .even_bram1_r_rdata(even_bram1_r_rdata),
    .odd_bram1_r_rdata (odd_bram1_r_rdata ),
    .even_bram2_r_rdata(even_bram2_r_rdata),
    .odd_bram2_r_rdata (odd_bram2_r_rdata ),
    .even_bram1_g_rdata(even_bram1_g_rdata),
    .odd_bram1_g_rdata (odd_bram1_g_rdata ),
    .even_bram2_g_rdata(even_bram2_g_rdata),
    .odd_bram2_g_rdata (odd_bram2_g_rdata ),
    .even_bram1_b_rdata(even_bram1_b_rdata),
    .odd_bram1_b_rdata (odd_bram1_b_rdata ),
    .even_bram2_b_rdata(even_bram2_b_rdata),
    .odd_bram2_b_rdata (odd_bram2_b_rdata )

);

nearest_interpolation_rgb_v4 nearest_inst           
(                                                
    .src_img_width   (c_src_img_width [10:0]),   
    .src_img_height  (c_src_img_height[10:0]),   	
    .dst_img_width   (c_dst_img_width       ),   	
    .dst_img_height  (c_dst_img_height      ),   	
    .x_radio         (c_x_radio       [15:0]),
    .y_radio         (c_y_radio       [15:0]),

    .clk_in1         (hdmi_rx_slow_clk      ),
    .clk_in2         (hdmi_tx_slow_clk      ),
    .rst_n           (rst_n                 ),

    .per_img_vsync   (~rx_vsync),                       //  Prepared Image data vsync valid signal
    .per_img_de      (rx_de    ),                       //  Prepared Image data de vaild  signal
    .per_img_r       (rdata_in ),
    .per_img_g       (gdata_in ),
    .per_img_b       (bdata_in ),

    .post_img_vsync  (nearest_interpolated_vs   ),                       //  processed Image data vsync valid signal
    .post_img_de     (nearest_interpolated_de   ),                       //  processed Image data de vaild  signal
    .post_img_r      (nearest_interpolated_red  ), 
    .post_img_g      (nearest_interpolated_green),
    .post_img_b      (nearest_interpolated_blue ),
    
    .bram_a_wdata_r    (bram_a_wdata_r),
    .bram_a_wdata_g    (bram_a_wdata_g),
    .bram_a_wdata_b    (bram_a_wdata_b),
    .bram_a_waddr      (bram_a_waddr  ),
    .bram1_a_wenb      (bram1_a_wenb  ),
    .bram2_a_wenb      (bram2_a_wenb  ),

    .even_bram1_raddr  (even_bram1_raddr  ),
    .odd_bram1_raddr   (odd_bram1_raddr   ),
    .even_bram2_raddr  (even_bram2_raddr  ),
    .odd_bram2_raddr   (odd_bram2_raddr   ),
    .even_bram1_r_rdata(even_bram1_r_rdata),
    .odd_bram1_r_rdata (odd_bram1_r_rdata ),
    .even_bram2_r_rdata(even_bram2_r_rdata),
    .odd_bram2_r_rdata (odd_bram2_r_rdata ),
    .even_bram1_g_rdata(even_bram1_g_rdata),
    .odd_bram1_g_rdata (odd_bram1_g_rdata ),
    .even_bram2_g_rdata(even_bram2_g_rdata),
    .odd_bram2_g_rdata (odd_bram2_g_rdata ),
    .even_bram1_b_rdata(even_bram1_b_rdata),
    .odd_bram1_b_rdata (odd_bram1_b_rdata ),
    .even_bram2_b_rdata(even_bram2_b_rdata),
    .odd_bram2_b_rdata (odd_bram2_b_rdata )  
);


bilinear_interpolation_rgb_v3 bilinear_inst
(
    .src_img_width   (c_src_img_width [10:0]),
    .src_img_height  (c_src_img_height[10:0]),
    .dst_img_width   (c_dst_img_width       ),
    .dst_img_height  (c_dst_img_height      ),
    .x_radio         (c_x_radio       [15:0]),
    .y_radio         (c_y_radio       [15:0]),   

    .clk_in1         (hdmi_rx_slow_clk),
    .clk_in2         (hdmi_tx_slow_clk),
    .rst_n           (rst_n           ),

    .per_img_vsync   (~rx_vsync),       //  Prepared Image data vsync valid signal
    .per_img_de      (rx_de    ),       //  Prepared Image data de vaild  signal
    .per_img_r       (rdata_in ),       //  Prepared Image brightness input
    .per_img_g       (gdata_in ),
    .per_img_b       (bdata_in ),

    .post_img_vsync  (bilinear_interpolated_vs   ),       //  processed Image data vsync valid signal
    .post_img_de     (bilinear_interpolated_de   ),       //  processed Image data href vaild  signal
    .post_img_r      (bilinear_interpolated_red  ),       //  processed Image brightness output
    .post_img_g      (bilinear_interpolated_green),
    .post_img_b      (bilinear_interpolated_blue ),
    
/*     .bram_a_wdata_r    (),
    .bram_a_wdata_g    (),
    .bram_a_wdata_b    (),
    .bram_a_waddr      (),
    .bram1_a_wenb      (),
    .bram2_a_wenb      (),

    .even_bram1_raddr  (),
    .odd_bram1_raddr   (),
    .even_bram2_raddr  (),
    .odd_bram2_raddr   (), */
    .even_bram1_r_rdata(even_bram1_r_rdata),
    .odd_bram1_r_rdata (odd_bram1_r_rdata ),
    .even_bram2_r_rdata(even_bram2_r_rdata),
    .odd_bram2_r_rdata (odd_bram2_r_rdata ),
    .even_bram1_g_rdata(even_bram1_g_rdata),
    .odd_bram1_g_rdata (odd_bram1_g_rdata ),
    .even_bram2_g_rdata(even_bram2_g_rdata),
    .odd_bram2_g_rdata (odd_bram2_g_rdata ),
    .even_bram1_b_rdata(even_bram1_b_rdata),
    .odd_bram1_b_rdata (odd_bram1_b_rdata ),
    .even_bram2_b_rdata(even_bram2_b_rdata),
    .odd_bram2_b_rdata (odd_bram2_b_rdata )  
);



nine_point_interpolation_v3
(
    .src_img_width   (c_src_img_width [10:0]),
    .src_img_height  (c_src_img_height[10:0]),
    .dst_img_width   (c_dst_img_width       ),
    .dst_img_height  (c_dst_img_height      ),
    .x_radio         (c_x_radio       [15:0]),
    .y_radio         (c_y_radio       [15:0]),   
    
    .clk_in1         (hdmi_rx_slow_clk),
    .clk_in2         (hdmi_tx_slow_clk),
    .rst_n           (rst_n           ),
    
    //  Image data prepared to be processed
    .per_img_vsync   (~rx_vsync),       //  Prepared Image data vsync valid signal
    .per_img_de      (rx_de    ),       //  Prepared Image data href vaild  signal
    .per_img_r       (rdata_in ),       //  Prepared Image brightness input
    .per_img_g       (gdata_in ),
    .per_img_b       (bdata_in ),
    
    //  Image data has been processed
    .post_img_vsync  (bicubic_interpolated_vs   ),       //  processed Image data vsync valid signal
    .post_img_de     (bicubic_interpolated_de   ),       //  processed Image data href vaild  signal
    .post_img_r      (bicubic_interpolated_red  ),       //  processed Image brightness output
    .post_img_g      (bicubic_interpolated_green),
    .post_img_b      (bicubic_interpolated_blue ),
    
/*     output  reg             [7:0]           bram_a_wdata_r    ,
    output  reg             [7:0]           bram_a_wdata_g    ,
    output  reg             [7:0]           bram_a_wdata_b    ,
    output  reg             [11:0]          bram_a_waddr      ,
    output  reg                             bram1_a_wenb      ,
    output  reg                             bram2_a_wenb      ,
    
    output  reg             [11:0]          even_bram1_raddr  ,
    output  reg             [11:0]          odd_bram1_raddr   ,
    output  reg             [11:0]          even_bram2_raddr  ,
    output  reg             [11:0]          odd_bram2_raddr   , */
    
    .even_bram1_r_rdata(even_bram1_r_rdata),
    .odd_bram1_r_rdata (odd_bram1_r_rdata ),
    .even_bram2_r_rdata(even_bram2_r_rdata),
    .odd_bram2_r_rdata (odd_bram2_r_rdata ),
    .even_bram1_g_rdata(even_bram1_g_rdata),
    .odd_bram1_g_rdata (odd_bram1_g_rdata ),
    .even_bram2_g_rdata(even_bram2_g_rdata),
    .odd_bram2_g_rdata (odd_bram2_g_rdata ),
    .even_bram1_b_rdata(even_bram1_b_rdata),
    .odd_bram1_b_rdata (odd_bram1_b_rdata ),
    .even_bram2_b_rdata(even_bram2_b_rdata),
    .odd_bram2_b_rdata (odd_bram2_b_rdata )
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
      wire [7:0]  m_cpu_aid_0;
	  wire [31:0] m_cpu_aaddr_0;
	  wire [7:0]  m_cpu_alen_0;
	  wire [2:0]  m_cpu_asize_0;
	  wire [1:0]  m_cpu_aburst_0;
	  wire [1:0]  m_cpu_alock_0;
	  wire		  m_cpu_avalid_0;
	  wire		  m_cpu_aready_0;	  
	  wire		  m_cpu_atype_0;
	  wire [7:0]  m_cpu_wid_0;
	  wire [127:0]m_cpu_wdata_0;
	  wire [15:0] m_cpu_wstrb_0;
	  wire		  m_cpu_wlast_0;
	  wire		  m_cpu_wvalid_0;
	  wire		  m_cpu_wready_0;
	  wire [3:0]  m_cpu_rid_0;
	  wire [127:0]m_cpu_rdata_0;
	  wire		  m_cpu_rlast_0;
	  wire		  m_cpu_rvalid_0;
	  wire		  m_cpu_rready_0;
	  wire [1:0]  m_cpu_rresp_0;
	  wire [7:0]  m_cpu_bid_0;
	  wire		  m_cpu_bvalid_0;
	  wire		  m_cpu_bready_0;
      wire          m_cpu_awready_0;
      wire          m_cpu_arready_0;
      wire          m_cpu_awvalid_0;
      wire          m_cpu_arvalid_0;    
assign m_cpu_aready_0=(m_cpu_atype_0 & m_cpu_awready_0) | (!m_cpu_atype_0 & m_cpu_arready_0);
assign m_cpu_awvalid_0=m_cpu_avalid_0 & m_cpu_atype_0;
assign m_cpu_arvalid_0=m_cpu_avalid_0 & ~m_cpu_atype_0;

   
      wire [7:0]  s_ddr_aid_0;
	  wire [31:0] s_ddr_aaddr_0;
	  wire [7:0]  s_ddr_alen_0;
	  wire [2:0]  s_ddr_asize_0;
	  wire [1:0]  s_ddr_aburst_0;
	  wire [1:0]  s_ddr_alock_0;
	  wire		  s_ddr_avalid_0;
	  wire		  s_ddr_aready_0;
	  wire		  s_ddr_atype_0;
	  wire [7:0]  s_ddr_wid_0;
	  wire [127:0]s_ddr_wdata_0;
	  wire [15:0] s_ddr_wstrb_0;
	  wire		  s_ddr_wlast_0;
	  wire		  s_ddr_wvalid_0;
	  wire		  s_ddr_wready_0;
	  wire [3:0]  s_ddr_rid_0;
	  wire [127:0]s_ddr_rdata_0;
	  wire		  s_ddr_rlast_0;
	  wire		  s_ddr_rvalid_0;
	  wire		  s_ddr_rready_0;
	  wire [1:0]  s_ddr_rresp_0;
	  wire [7:0]  s_ddr_bid_0;
	  wire		  s_ddr_bvalid_0;
	  wire		  s_ddr_bready_0;
      
wire   [0:0]   s_fullduplex_axi_awvalid;    
wire   [31:0]  s_fullduplex_axi_awaddr ;
wire   [1:0]   s_fullduplex_axi_awlock ;
wire    [0:0]  s_fullduplex_axi_awready;
wire   [7:0]   s_fullduplex_axi_awid   ;
wire   [1:0]   s_fullduplex_axi_awburst;
wire   [7:0]   s_fullduplex_axi_awlen  ;
wire   [2:0]   s_fullduplex_axi_awsize ;

wire   [0:0]   s_fullduplex_axi_arvalid;
wire   [31:0]  s_fullduplex_axi_araddr ;
wire   [1:0]   s_fullduplex_axi_arlock ;
wire    [0:0]  s_fullduplex_axi_arready;
wire   [7:0]   s_fullduplex_axi_arid   ;
wire   [2:0]   s_fullduplex_axi_arsize ;
wire   [7:0]   s_fullduplex_axi_arlen  ;
wire   [1:0]   s_fullduplex_axi_arburst;

wire   [0:0]   s_fullduplex_axi_wvalid ;
wire   [0:0]   s_fullduplex_axi_wlast  ;
wire   [7:0]   s_fullduplex_axi_wid    ;
wire   [127:0] s_fullduplex_axi_wdata  ;
wire   [15:0]  s_fullduplex_axi_wstrb  ;
wire    [0:0]  s_fullduplex_axi_wready ;

wire   [0:0]   s_fullduplex_axi_bready ;
wire    [1:0]  s_fullduplex_axi_bresp  ;
wire    [7:0]  s_fullduplex_axi_bid    ;
wire    [0:0]  s_fullduplex_axi_bvalid ;

wire   [0:0]   s_fullduplex_axi_rready ;
wire    [7:0]  s_fullduplex_axi_rid    ;
wire    [127:0]s_fullduplex_axi_rdata  ;
wire    [1:0]  s_fullduplex_axi_rresp  ;
wire    [0:0]  s_fullduplex_axi_rvalid ;
wire    [0:0]  s_fullduplex_axi_rlast  ;         
      
      
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

wire        io_ddrMasters_0_reset;

frame_buffer #(
	.I_VID_WIDTH 	(16),                      			
	.O_VID_WIDTH 	(16),                    
	.AXI_ID_WIDTH	( AXI_ID_WIDTH 	),       
	.AXI_WR_ID		(	AXI0_WR_ID	),       
	.AXI_RD_ID		( AXI0_RD_ID    ),       
	.AXI_ADDR_WIDTH (AXI_ADDR_WIDTH ),       
	.AXI_DATA_WIDTH (AXI_DATA_WIDTH	),       
	.START_ADDR		(32'h20000),              
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
/*i*/.H_VALID 	 	(c_dst_img_width	),//( 13'd146 		),//(H_VALID 	 	  ),//
/*i*/.H_BACK_PORCH	(13'd1696-c_dst_img_width),//( 13'd10 			),//(H_BACK_PORCH ),//
/*i*/.V_PRE_PORCH 	(V_PRE_PORCH  		),//( 13'd5 			),//(V_PRE_PORCH  ),//
/*i*/.V_SYNC 	 	(V_SYNC 	 		),//( 13'd5 			),//(V_SYNC 	 		),//
/*i*/.V_VALID 	 	(c_dst_img_height 	),//( 13'd119 		),//(V_VALID 	 	  ),//
/*i*/.V_BACK_PORCH	(13'd996-c_dst_img_height),//( 13'd5 			),//(V_BACK_PORCH ),//
/*i*/.MAX_VID_WIDTH	(c_dst_img_width ),    // output img width
/*i*/.MAX_VID_HIGHT	(c_dst_img_height),    // output img hight

/*i*/.axi_clk		(sys_clk 		    ), 
/*i*/.rst_n			(Sys_Rst_N          ),

/*o*/.axi_awid		(axi_m_awid			),//      
/*o*/.axi_awaddr	(axi_m_awaddr		),//    
/*o*/.axi_awlen		(axi_m_awlen		),//     
/*o*/.axi_awsize	(axi_m_awsize		), //   
/*o*/.axi_awburst	(axi_m_awburst		), //  
/*o*/.axi_awlock	(axi_m_awlock		), //   
/*o*/.axi_awvalid	(axi_m_awvalid		), //  
/*i*/.axi_awready	(axi_m_awready		),  //
                                         
/*O*/.axi_wid		(axi_m_wid			),
/*o*/.axi_wdata		(axi_m_wdata		),     
/*o*/.axi_wstrb		(axi_m_wstrb		),     
/*o*/.axi_wlast		(axi_m_wlast		), //    
/*o*/.axi_wvalid	(axi_m_wvalid		), //   
/*i*/.axi_wready	(axi_m_wready		),//
                                    				              	
/*i*/.axi_bid		(axi_m_bid			),//   
/*o*/.axi_bresp		(axi_m_bresp		),// 
/*i*/.axi_bvalid	(axi_m_bvalid		),//
/*o*/.axi_bready	(axi_m_bready		),//
                                                    
/*o*/.axi_arid		(axi_m_arid			), //     
/*o*/.axi_araddr	(axi_m_araddr		),//    
/*o*/.axi_arlen		(axi_m_arlen	    ), //    
/*o*/.axi_arsize	(axi_m_arsize		),//    
/*o*/.axi_arburst	(axi_m_arburst	 	), //  
/*o*/.axi_arlock	(axi_m_arlock	 	), //   
/*o*/.axi_arvalid	(axi_m_arvalid		), //  
/*i*/.axi_arready	(axi_m_arready		),//
                                        
/*i*/.axi_rid  		(axi_m_rid			), //      
/*i*/.axi_rdata		(axi_m_rdata		),//
/*i*/.axi_rresp		(axi_m_rresp	 	), //    
/*i*/.axi_rlast		(axi_m_rlast	 	),//   
/*i*/.axi_rvalid	(axi_m_rvalid	 	), //   
/*o*/.axi_rready	(axi_m_rready		)  //   
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
		.nrst		(Sys_Rst_N      ),
	  
	  	
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
	  	.i_avalid(s_ddr_avalid_0),     
	  	.o_aready(s_ddr_aready_0),                
	  	.i_aaddr (s_ddr_aaddr_0 ),      
	  	.i_aid   (s_ddr_aid_0   ),        
	  	.i_alen  (s_ddr_alen_0  ),       
	  	.i_asize (s_ddr_asize_0 ),      
	  	.i_aburst(s_ddr_aburst_0),     
	  	.i_alock (s_ddr_alock_0 ),      
	  	.i_atype (s_ddr_atype_0 ),      

	  	.i_wid   (s_ddr_wid_0   ),        
	  	.i_wvalid(s_ddr_wvalid_0),     
	  	.o_wready(s_ddr_wready_0),     
	  	.i_wdata (s_ddr_wdata_0 ),      
	  	.i_strb  (s_ddr_wstrb_0 ),      
	  	.i_wlast (s_ddr_wlast_0 ),               

	  	.o_bvalid(s_ddr_bvalid_0), 
	  	.i_bready(s_ddr_bready_0), 
	  	.o_bid   (s_ddr_bid_0   ),    

	  	.o_rvalid(s_ddr_rvalid_0), 
	  	.i_rready(s_ddr_rready_0), 
	  	.o_rdata (s_ddr_rdata_0 ),  
	  	.o_rid   (s_ddr_rid_0   ),    
	  	.o_rresp (s_ddr_rresp_0 ),
	  	.o_rlast (s_ddr_rlast_0 ),
	  
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
    .SysClk   ( sys_clk    ), //System Clock
    .Reset_N  ( rst_n      ), //System Reset
    //Axi Slave Interfac Signal
    .AWID     (s_fullduplex_axi_awid   ),     //(I)[WrAddr]Write address ID.             
    .AWADDR   (s_fullduplex_axi_awaddr   ),   //(I)[WrAddr]Write address.                 
    .AWLEN    (s_fullduplex_axi_awlen   ),    //(I)[WrAddr]Burst length.                  
    .AWSIZE   (s_fullduplex_axi_awsize   ),   //(I)[WrAddr]Burst size.                   
    .AWBURST  (s_fullduplex_axi_awburst   ),  //(I)[WrAddr]Burst type.                      
    .AWLOCK   (s_fullduplex_axi_awlock   ),   //(I)[WrAddr]Lock type.                    
    .AWVALID  (s_fullduplex_axi_awvalid   ),  //(I)[WrAddr]Write address valid.            
    .AWREADY  (s_fullduplex_axi_awready   ),  //(O)[WrAddr]Write address ready.           
    ///////////                                               
    .WID      (s_fullduplex_axi_wid    ),     //(I)[WrData]Write ID tag.                
    .WDATA    (s_fullduplex_axi_wdata    ),   //(I)[WrData]Write data.                   
    .WSTRB    (s_fullduplex_axi_wstrb    ),   //(I)[WrData]Write strobes.                
    .WLAST    (s_fullduplex_axi_wlast    ),   //(I)[WrData]Write last.                  
    .WVALID   (s_fullduplex_axi_wvalid    ),  //(I)[WrData]Write valid.                    
    .WREADY   (s_fullduplex_axi_wready    ),  //(O)[WrData]Write ready.                  
    ///////////                                                 
    .BID      (s_fullduplex_axi_bid    ),     //(O)[WrResp]Response ID tag.             
    .BVALID   (s_fullduplex_axi_bvalid    ),  //(O)[WrResp]Write response valid.        
    .BREADY   (s_fullduplex_axi_bready    ),  //(I)[WrResp]Response ready.              
    ///////////                                                 
    .ARID     (s_fullduplex_axi_arid   ),     //(I)[RdAddr]Read address ID.                  
    .ARADDR   (s_fullduplex_axi_araddr   ),   //(I)[RdAddr]Read address.                   
    .ARLEN    (s_fullduplex_axi_arlen   ),    //(I)[RdAddr]Burst length.                   
    .ARSIZE   (s_fullduplex_axi_arsize   ),   //(I)[RdAddr]Burst size.                    
    .ARBURST  (s_fullduplex_axi_arburst   ),  //(I)[RdAddr]Burst type.                   
    .ARLOCK   (s_fullduplex_axi_arlock   ),   //(I)[RdAddr]Lock type.                     
    .ARVALID  (s_fullduplex_axi_arvalid   ),  //(I)[RdAddr]Read address valid.    
    .ARREADY  (s_fullduplex_axi_arready   ),  //(O)[RdAddr]Read address ready.               
    ///////////                                                
    .RID      (s_fullduplex_axi_rid    ),     //(O)[RdData]Read ID tag.                 
    .RDATA    (s_fullduplex_axi_rdata     ),  //(O)[RdData]Read data.                    
    .RRESP    (s_fullduplex_axi_rresp      ), //(O)[RdData]Read response.                   
    .RLAST    (s_fullduplex_axi_rlast      ), //(O)[RdData]Read last.                    
    .RVALID   (s_fullduplex_axi_rvalid     ), //(O)[RdData]Read valid.                  
    .RREADY   (s_fullduplex_axi_rready    ),  //(I)[RdData]Read ready.                  
    /////////////                                                
    //DDR Controner AXI4 Signal
    .aid      (s_ddr_aid_0   ),  //(O)[Addres] Address ID                             
    .aaddr    (s_ddr_aaddr_0   ),  //(O)[Addres] Address                                
    .alen     (s_ddr_alen_0     ),  //(O)[Addres] Address Brust Length                    
    .asize    (s_ddr_asize_0    ),  //(O)[Addres] Address Burst size                       
    .aburst   (s_ddr_aburst_0   ),  //(O)[Addres] Address Burst type                     
    .alock    (s_ddr_alock_0    ),  //(O)[Addres] Address Lock type                      
    .avalid   (s_ddr_avalid_0   ),  //(O)[Addres] Address Valid                          
    .aready   (s_ddr_aready_0   ),  //(I)[Addres] Address Ready                          
    .atype    (s_ddr_atype_0   ),  //(O)[Addres] Operate Type 0=Read, 1=Write           
    /////////// /////////                                                  
    .wid      (s_ddr_wid_0     ),  //(O)[Write]  ID                                      
    .wdata    (s_ddr_wdata_0   ),  //(O)[Write]  Data                                   
    .wstrb    (s_ddr_wstrb_0   ),  //(O)[Write]  Data Strobes(Byte valid)               
    .wlast    (s_ddr_wlast_0   ),  //(O)[Write]  Data Last                               
    .wvalid   (s_ddr_wvalid_0   ),  //(O)[Write]  Data Valid                              
    .wready   (s_ddr_wready_0   ),  //(I)[Write]  Data Ready                              
    /////////// /////////                                                  
    .rid      (s_ddr_rid_0    ),  //(I)[Read]   ID                                     
    .rdata    (s_ddr_rdata_0    ),  //(I)[Read]   Data                                   
    .rlast    (s_ddr_rlast_0    ),  //(I)[Read]   Data Last                                 
    .rvalid   (s_ddr_rvalid_0   ),  //(I)[Read]   Data Valid                             
    .rready   (s_ddr_rready_0   ),  //(O)[Read]   Data Ready                             
    .rresp    (s_ddr_rresp_0    ),  //(I)[Read]   Response                               
    /////////// /////////                                                  
    .bid      (s_ddr_bid_0  ),  //(I)[Answer] Response Write ID                         
    .bvalid   (s_ddr_bvalid_0  ),  //(I)[Answer] Response valid                          
    .bready   (s_ddr_bready_0  )   //(O)[Answer] Response Ready                          
  ); 


//=================================================================================
//
//=================================================================================
wire  [15:0] io_apbSlave_0_PADDR ;
wire  io_apbSlave_0_PENABLE      ;
wire [31:0] io_apbSlave_0_PRDATA ;
wire io_apbSlave_0_PREADY        ;
wire  io_apbSlave_0_PSEL         ;
wire io_apbSlave_0_PSLVERROR     ;
wire  [31:0] io_apbSlave_0_PWDATA;
wire  io_apbSlave_0_PWRITE       ;

soc_riscv socInst(
/*----------JTAG DEBUG-------------------------------------------------------*/

/*i*/.jtagCtrl_enable     (jtag_inst1_SEL    ),
/*i*/.jtagCtrl_tdi        (jtag_inst1_TDI    ),
/*i*/.jtagCtrl_capture    (jtag_inst1_CAPTURE),
/*i*/.jtagCtrl_shift      (jtag_inst1_SHIFT  ),
/*i*/.jtagCtrl_update     (),//$
/*i*/.jtagCtrl_reset      (),//$
/*o*/.jtagCtrl_tdo        (jtag_inst1_TDO    ),
/*i*/.jtagCtrl_tck        (jtag_inst1_TCK    ),
     
/*----------AXI Slave Read Data Channel---------------------------------------*/
     
/*i*/.io_ddrA_r_payload_last (m_cpu_rlast_0 ),//*    //*:直连，$:空置，#：注释，数字：填入常量
/*i*/.io_ddrA_r_payload_resp (m_cpu_rresp_0 ),//*
/*i*/.io_ddrA_r_payload_id   (m_cpu_rid_0   ),//*
/*i*/.io_ddrA_r_payload_data (m_cpu_rdata_0 ),//*
/*o*/.io_ddrA_r_ready        (m_cpu_rready_0),//*
/*i*/.io_ddrA_r_valid        (m_cpu_rvalid_0),//*
     
/*----------AXI Slave Write Respond Channel-----------------------------------*/  

/*i*/.io_ddrA_b_payload_resp (2'b00),//2'b00                                            
/*i*/.io_ddrA_b_payload_id   (m_cpu_bid_0   ),//*                                             
/*o*/.io_ddrA_b_ready        (m_cpu_bready_0),//*                                          
/*i*/.io_ddrA_b_valid        (m_cpu_bvalid_0),//*                                        

/*----------AXI Slave Write Data Channel--------------------------------------*/          

/*o*/.io_ddrA_w_payload_id   (m_cpu_wid_0   ),//*                                              
/*o*/.io_ddrA_w_payload_last (m_cpu_wlast_0 ),//*                                           
/*i*/.io_ddrA_w_ready        (m_cpu_wready_0),//*                                    
/*o*/.io_ddrA_w_valid        (m_cpu_wvalid_0),//*                                    
/*o*/.io_ddrA_w_payload_strb (m_cpu_wstrb_0 ),//*                                      
/*o*/.io_ddrA_w_payload_data (m_cpu_wdata_0 ),//*                                      

/*----------AXI Slave Half-Duplex Address Channel for Read and Write----------*/  

/*o*/.io_ddrA_arw_payload_write (m_cpu_atype_0),//*#0=r 1=w                       
/*o*/.io_ddrA_arw_payload_prot  (),//$                                            
/*o*/.io_ddrA_arw_payload_qos   (),//$                                            
/*o*/.io_ddrA_arw_payload_cache (),//$                                            
/*o*/.io_ddrA_arw_payload_lock  (m_cpu_alock_0 ),//*                              
/*o*/.io_ddrA_arw_payload_burst (m_cpu_aburst_0),//*                              
/*o*/.io_ddrA_arw_payload_size  (m_cpu_asize_0 ),//*                              
/*o*/.io_ddrA_arw_payload_len   (m_cpu_alen_0  ),//*                                
/*o*/.io_ddrA_arw_payload_region(),//$                                            
/*o*/.io_ddrA_arw_payload_id    (m_cpu_aid_0   ),//*
/*o*/.io_ddrA_arw_payload_addr  (m_cpu_aaddr_0 ),//*
/*i*/.io_ddrA_arw_ready         (m_cpu_aready_0),//*
/*o*/.io_ddrA_arw_valid         (m_cpu_avalid_0),//*
     
/*----------EXTERNAL MEMORY Clock Ports---------------------------------------*/
     
/*i*/.io_memoryClk              (sys_clk), 
/*o*/.io_memoryReset            (), 
     
/*----------------------------------------------------------------------------*/
     
/*i*/.system_spi_0_io_data_0_read       (system_spi_0_io_data_0_read       ),           
/*o*/.system_spi_0_io_data_0_write      (system_spi_0_io_data_0_write      ),
/*o*/.system_spi_0_io_data_0_writeEnable(system_spi_0_io_data_0_writeEnable),
/*i*/.system_spi_0_io_data_1_read       (system_spi_0_io_data_1_read       ),
/*o*/.system_spi_0_io_data_1_write      (system_spi_0_io_data_1_write      ),
/*o*/.system_spi_0_io_data_1_writeEnable(system_spi_0_io_data_1_writeEnable),
/*o*/.system_spi_0_io_sclk_write        (system_spi_0_io_sclk_write        ),
/*o*/.system_spi_0_io_ss                (system_spi_0_io_ss                ),
/*i*/.system_spi_0_io_data_2_read       (),                                  
/*o*/.system_spi_0_io_data_2_write      (),                                  
/*o*/.system_spi_0_io_data_2_writeEnable(),                                  
/*i*/.system_spi_0_io_data_3_read       (),                                  
/*o*/.system_spi_0_io_data_3_write      (),                                  
/*o*/.system_spi_0_io_data_3_writeEnable(),                                  
     
/*o*/.system_uart_0_io_txd              (system_uart_0_io_txd        ), 
/*i*/.system_uart_0_io_rxd              (system_uart_0_io_rxd        ), 
                                        
/*o*/.system_gpio_0_io_writeEnable      (system_gpio_0_io_writeEnable), 
/*o*/.system_gpio_0_io_write            (system_gpio_0_io_write      ), 
/*i*/.system_gpio_0_io_read             (system_gpio_0_io_read       ), 
                                        
/*i*/.io_asyncReset                     (~rst_n                      ),
/*o*/.io_systemReset                    (),                            
/*i*/.io_systemClk                      (sys_clk                     ),   

/*----------------APB3 SLAVE INTERFACE--------------------------------------------------------*/
/*o*/.io_apbSlave_0_PADDR               (io_apbSlave_0_PADDR    ),
/*o*/.io_apbSlave_0_PENABLE             (io_apbSlave_0_PENABLE  ),
/*i*/.io_apbSlave_0_PRDATA              (io_apbSlave_0_PRDATA   ),
/*i*/.io_apbSlave_0_PREADY              (io_apbSlave_0_PREADY   ),
/*o*/.io_apbSlave_0_PSEL                (io_apbSlave_0_PSEL     ),
/*i*/.io_apbSlave_0_PSLVERROR           (io_apbSlave_0_PSLVERROR),
/*o*/.io_apbSlave_0_PWDATA              (io_apbSlave_0_PWDATA   ),
/*o*/.io_apbSlave_0_PWRITE              (io_apbSlave_0_PWRITE   )     
                                                                         
);                                                                        
                                                                            
                                                                         
                                                                          
//=============================================================  			
//                                                               		
//=============================================================  		
wire [1:0] blank;                                                		
interconnect interconnectInst(                                                   		  
      .rst_n(rst_n),                                                     		
      .clk  (sys_clk),                                                       		
                                                                 		
/*i*/.s_axi_awvalid({m_cpu_awvalid_0,axi_m_awvalid}),                                               
/*i*/.s_axi_awaddr ({m_cpu_aaddr_0,axi_m_awaddr}),                          			  
/*i*/.s_axi_awlock ({m_cpu_alock_0,axi_m_awlock}),                           		  
/*o*/.s_axi_awready({m_cpu_awready_0,axi_m_awready}),                         		   
/*i*/.s_axi_awprot ({4'b0,4'b0}),//                                  		
/*i*/.s_axi_awcache({4'b0,4'b0}),//                                  		
/*i*/.s_axi_awqos  ({4'b0,4'b0}),//                                  		
/*i*/.s_axi_awuser ({3'b0,3'b0}),//                                                 	
/*i*/.s_axi_awid   ({m_cpu_aid_0,axi_m_awid}),                             			
/*i*/.s_axi_awburst({m_cpu_aburst_0,axi_m_awburst}),                          		  
/*i*/.s_axi_awlen  ({m_cpu_alen_0,axi_m_awlen}),                            		 
/*i*/.s_axi_awsize ({m_cpu_asize_0,axi_m_awsize}),                           		  
                                                                                    
/*i*/.s_axi_arvalid({m_cpu_arvalid_0,axi_m_arvalid}),                         			      
/*i*/.s_axi_araddr ({m_cpu_aaddr_0,axi_m_araddr}),                           		  
/*i*/.s_axi_arlock ({m_cpu_alock_0,axi_m_arlock}),                           	       
/*o*/.s_axi_arready({m_cpu_arready_0,axi_m_arready}),                         		   
/*i*/.s_axi_arqos  ({4'b0,4'b0}),//                                  	 	
/*i*/.s_axi_arcache({4'b0,4'b0}),//                                  	 	
/*i*/.s_axi_arid   ({m_cpu_aid_0,axi_m_arid}),                             		 
/*i*/.s_axi_arsize ({m_cpu_asize_0,axi_m_arsize}),                           		     
/*i*/.s_axi_arlen  ({m_cpu_alen_0,axi_m_arlen}),                                                 
/*i*/.s_axi_arburst({m_cpu_aburst_0,axi_m_arburst}),                          			    
/*i*/.s_axi_arprot ({4'b0,4'b0}),//                                  		
/*i*/.s_axi_aruser ({3'b0,3'b0}),//                                  	 	
                                                                 	 	
/*i*/.s_axi_wvalid ({m_cpu_wvalid_0,axi_m_wvalid}),                          	 	        
/*i*/.s_axi_wlast  ({m_cpu_wlast_0,axi_m_wlast}),                           		      
/*i*/.s_axi_wid    ({m_cpu_wid_0, axi_m_wid}),                             
/*i*/.s_axi_wdata  ({m_cpu_wdata_0,axi_m_wdata}),                             
/*i*/.s_axi_wstrb  ({m_cpu_wstrb_0,axi_m_wstrb}),                              
/*o*/.s_axi_wready ({m_cpu_wready_0,axi_m_wready}),                                 
/*i*/.s_axi_wuser  ({3'b0,3'b0}),//                            
   
/*i*/.s_axi_bready ({m_cpu_bready_0,axi_m_bready}),                                
/*o*/.s_axi_bresp  ({blank,axi_m_bresp}),                              
/*o*/.s_axi_bid    ({m_cpu_bid_0,axi_m_bid}),       
/*o*/.s_axi_bvalid ({m_cpu_bvalid_0,axi_m_bvalid}),
/*o*/.s_axi_buser  (),//

/*i*/.s_axi_rready ({m_cpu_rready_0,axi_m_rready}),
/*o*/.s_axi_rid    ({m_cpu_rid_0,axi_m_rid}),                         
/*o*/.s_axi_rdata  ({m_cpu_rdata_0,axi_m_rdata}),
/*o*/.s_axi_rresp  ({m_cpu_rresp_0,axi_m_rresp}),
/*o*/.s_axi_rvalid ({m_cpu_rvalid_0,axi_m_rvalid}),
/*o*/.s_axi_rlast  ({m_cpu_rlast_0,axi_m_rlast}),
/*o*/.s_axi_ruser  (), //

//-------------------------------------------------------------- 
                                                                 
/*o*/.m_axi_awvalid (s_fullduplex_axi_awvalid), 
/*o*/.m_axi_awaddr  (s_fullduplex_axi_awaddr),  
/*o*/.m_axi_awlock  (s_fullduplex_axi_awlock ),             
/*i*/.m_axi_awready (s_fullduplex_axi_awready),             
/*o*/.m_axi_awprot  (),                         
/*o*/.m_axi_awid    (s_fullduplex_axi_awid   ),             
/*o*/.m_axi_awburst (s_fullduplex_axi_awburst), 
/*o*/.m_axi_awlen   (s_fullduplex_axi_awlen  ), 
/*o*/.m_axi_awsize  (s_fullduplex_axi_awsize ), 
/*o*/.m_axi_awcache (),                         
/*o*/.m_axi_awqos   (),                         
/*o*/.m_axi_awuser  (),                         
/*o*/.m_axi_awregion(),                         
                                                
/*o*/.m_axi_arvalid (s_fullduplex_axi_arvalid), 
/*o*/.m_axi_araddr  (s_fullduplex_axi_araddr ),             
/*o*/.m_axi_arlock  (s_fullduplex_axi_arlock ),             
/*i*/.m_axi_arready (s_fullduplex_axi_arready), 
/*o*/.m_axi_arprot  (),                         
/*o*/.m_axi_arburst (s_fullduplex_axi_arburst), 
/*o*/.m_axi_arlen   (s_fullduplex_axi_arlen),   
/*o*/.m_axi_arsize  (s_fullduplex_axi_arsize),             
/*o*/.m_axi_arcache (),                         
/*o*/.m_axi_arqos   (),                         
/*o*/.m_axi_aruser  (),                         
/*o*/.m_axi_arregion(),                         
/*o*/.m_axi_arid    (s_fullduplex_axi_arid),    
                                                
/*o*/.m_axi_wvalid  (s_fullduplex_axi_wvalid ), 
/*o*/.m_axi_wlast   (s_fullduplex_axi_wlast  ), 
/*o*/.m_axi_wdata   (s_fullduplex_axi_wdata  ),             
/*o*/.m_axi_wstrb   (s_fullduplex_axi_wstrb  ),             
/*i*/.m_axi_wready  (s_fullduplex_axi_wready ), 
/*o*/.m_axi_wuser   (),                         
                                                
/*o*/.m_axi_bready  (s_fullduplex_axi_bready),  
/*i*/.m_axi_bresp   (s_fullduplex_axi_bresp ),             
/*i*/.m_axi_bid     (s_fullduplex_axi_bid   ),  
/*i*/.m_axi_bvalid  (s_fullduplex_axi_bvalid),  
/*i*/.m_axi_buser   (3'b0),                         
                                                
/*o*/.m_axi_rready  (s_fullduplex_axi_rready ), 
/*i*/.m_axi_rid     (s_fullduplex_axi_rid    ), 
/*i*/.m_axi_rdata   (s_fullduplex_axi_rdata  ), 
/*i*/.m_axi_rresp   (s_fullduplex_axi_rresp  ),             
/*i*/.m_axi_rvalid  (s_fullduplex_axi_rvalid ),
/*i*/.m_axi_rlast   (s_fullduplex_axi_rlast  ),
/*i*/.m_axi_ruser   (3'b0)



);
//=============================================================
//
//=============================================================

apb3_slave #(
    // user parameter starts here
    //
    .NUM_REG(3)
)apb3_slave_inst1
(
    // user logic starts here
/*i*/.clk       (sys_clk),
/*i*/.resetn    (rst_n  ),

/*o*/.start     (),//from cpu
/*o*/.iaddr     (),//from cpu
/*o*/.ilen      (),//from cpu
/*o*/.idata     (),//from cpu
/*i*/.src_width (c_src_img_width [10:0]),//from logic
/*i*/.src_height(c_src_img_height[10:0]),//from logic
/*i*/.dst_width (c_dst_img_width       ),//from logic
/*i*/.dst_height(c_dst_img_height      ),//from logic
/*i*/.algo_state(state                 ),//from logic
    
/*i*/.PADDR     (io_apbSlave_0_PADDR),
/*i*/.PSEL      (io_apbSlave_0_PSEL),
/*i*/.PENABLE   (io_apbSlave_0_PENABLE),
/*o*/.PREADY    (io_apbSlave_0_PREADY),
/*i*/.PWRITE    (io_apbSlave_0_PWRITE),
/*i*/.PWDATA    (io_apbSlave_0_PWDATA),
/*o*/.PRDATA    (io_apbSlave_0_PRDATA),
/*o*/.PSLVERROR (io_apbSlave_0_PSLVERROR)

);



endmodule


   
   