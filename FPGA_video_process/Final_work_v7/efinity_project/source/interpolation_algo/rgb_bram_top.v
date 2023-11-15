module  rgb_bram_top
(
    input    wire                            clk_in1           ,
    input    wire                            clk_in2           ,

    input    wire            [7:0]           bram_a_wdata_r    ,
    input    wire            [7:0]           bram_a_wdata_g    ,
    input    wire            [7:0]           bram_a_wdata_b    ,
    input    wire            [11:0]          bram_a_waddr      ,
    input    wire                            bram1_a_wenb      ,
    input    wire                            bram2_a_wenb      ,
  
    input    wire            [11:0]          even_bram1_raddr  ,
    input    wire            [11:0]          odd_bram1_raddr   ,
    input    wire            [11:0]          even_bram2_raddr  ,
    input    wire            [11:0]          odd_bram2_raddr   ,
    
    output   wire            [ 7:0]          even_bram1_r_rdata,
    output   wire            [ 7:0]          odd_bram1_r_rdata ,
    output   wire            [ 7:0]          even_bram2_r_rdata,
    output   wire            [ 7:0]          odd_bram2_r_rdata ,
    output   wire            [ 7:0]          even_bram1_g_rdata,
    output   wire            [ 7:0]          odd_bram1_g_rdata ,
    output   wire            [ 7:0]          even_bram2_g_rdata,
    output   wire            [ 7:0]          odd_bram2_g_rdata ,
    output   wire            [ 7:0]          even_bram1_b_rdata,
    output   wire            [ 7:0]          odd_bram1_b_rdata ,
    output   wire            [ 7:0]          even_bram2_b_rdata,
    output   wire            [ 7:0]          odd_bram2_b_rdata 

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








endmodule