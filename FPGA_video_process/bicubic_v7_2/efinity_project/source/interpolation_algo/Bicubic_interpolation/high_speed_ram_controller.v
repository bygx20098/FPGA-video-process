module high_speed_ram_controller
#(
    parameter C_ADDR_WIDTH  = 8,
    parameter C_DATA_WIDTH  = 8
)
(
    input  wire                     wclk    ,
    input  wire                     wen     ,
    input  wire [C_ADDR_WIDTH-1:0]  waddr   ,
    input  wire [C_DATA_WIDTH-1:0]  wdata   ,
    
    input  wire                     vs      ,
    input  wire                     rclk    ,
    input  wire                     rclk_4x ,
    input  wire [C_ADDR_WIDTH-1:0]  raddr0  ,
    output reg  [C_DATA_WIDTH-1:0]  rdata0  ,
    input  wire [C_ADDR_WIDTH-1:0]  raddr1  ,
    output reg  [C_DATA_WIDTH-1:0]  rdata1  ,
    input  wire [C_ADDR_WIDTH-1:0]  raddr2  ,
    output reg  [C_DATA_WIDTH-1:0]  rdata2  ,
    input  wire [C_ADDR_WIDTH-1:0]  raddr3  ,
    output reg  [C_DATA_WIDTH-1:0]  rdata3  ,
    input  wire [C_ADDR_WIDTH-1:0]  raddr4  ,
    output reg  [C_DATA_WIDTH-1:0]  rdata4  ,
    input  wire [C_ADDR_WIDTH-1:0]  raddr5  ,
    output reg  [C_DATA_WIDTH-1:0]  rdata5  ,
    input  wire [C_ADDR_WIDTH-1:0]  raddr6  ,
    output reg  [C_DATA_WIDTH-1:0]  rdata6  ,
    input  wire [C_ADDR_WIDTH-1:0]  raddr7  ,
    output reg  [C_DATA_WIDTH-1:0]  rdata7  
);

reg                      vs_reg;
reg  [C_ADDR_WIDTH-1:0]  raddr0_reg  [3:0];
reg  [C_ADDR_WIDTH-1:0]  raddr_sel_0 ;
wire [C_DATA_WIDTH-1:0]  rdata_sel_0 ;
reg  [C_DATA_WIDTH-1:0]  rdata0_reg  [3:0];

reg  [C_ADDR_WIDTH-1:0]  raddr1_reg  [3:0];
reg  [C_ADDR_WIDTH-1:0]  raddr_sel_1 ;
wire [C_DATA_WIDTH-1:0]  rdata_sel_1 ;
reg  [C_DATA_WIDTH-1:0]  rdata1_reg  [3:0];


always@(posedge rclk_4x)begin
    raddr0_reg[0]  <= raddr0;
    raddr0_reg[1]  <= raddr1;
    raddr0_reg[2]  <= raddr2;
    raddr0_reg[3]  <= raddr3;
    raddr1_reg[0]  <= raddr4;
    raddr1_reg[1]  <= raddr5;
    raddr1_reg[2]  <= raddr6;
    raddr1_reg[3]  <= raddr7;
    vs_reg         <= vs;
end

reg     [1:0]   cnt;

always@(posedge rclk_4x)begin
    if(~vs_reg)
        cnt <= 2'd0;
    else if(cnt == 2'd3)
        cnt <= 2'd0;
    else
        cnt <= cnt + 1'b1;
end

always@(posedge rclk_4x) raddr_sel_0 <= raddr0_reg[cnt];
always@(posedge rclk_4x) raddr_sel_1 <= raddr1_reg[cnt];

always@(posedge rclk_4x)begin
    case(cnt)
        2'd2: 
        begin
            rdata0_reg[0] <= rdata_sel_0  ;
            rdata0_reg[1] <= rdata0_reg[1];
            rdata0_reg[2] <= rdata0_reg[2];
            rdata0_reg[3] <= rdata0_reg[3];
            rdata1_reg[0] <= rdata_sel_1  ;
            rdata1_reg[1] <= rdata1_reg[1];
            rdata1_reg[2] <= rdata1_reg[2];
            rdata1_reg[3] <= rdata1_reg[3];
        end
        2'd3:
        begin
            rdata0_reg[0] <= rdata0_reg[0];
            rdata0_reg[1] <= rdata_sel_0  ;
            rdata0_reg[2] <= rdata0_reg[2];
            rdata0_reg[3] <= rdata0_reg[3];
            rdata1_reg[0] <= rdata1_reg[0];
            rdata1_reg[1] <= rdata_sel_1  ;
            rdata1_reg[2] <= rdata1_reg[2];
            rdata1_reg[3] <= rdata1_reg[3];
        end
        2'd0:
        begin
            rdata0_reg[0] <= rdata0_reg[0];
            rdata0_reg[1] <= rdata0_reg[1];
            rdata0_reg[2] <= rdata_sel_0  ;
            rdata0_reg[3] <= rdata0_reg[3];
            rdata1_reg[0] <= rdata1_reg[0];
            rdata1_reg[1] <= rdata1_reg[1];
            rdata1_reg[2] <= rdata_sel_1  ;
            rdata1_reg[3] <= rdata1_reg[3];
        end
        2'd1:  
        begin
            rdata0_reg[0] <= rdata0_reg[0];
            rdata0_reg[1] <= rdata0_reg[1];
            rdata0_reg[2] <= rdata0_reg[2];
            rdata0_reg[3] <= rdata_sel_0  ;
            rdata1_reg[0] <= rdata1_reg[0];
            rdata1_reg[1] <= rdata1_reg[1];
            rdata1_reg[2] <= rdata1_reg[2];
            rdata1_reg[3] <= rdata_sel_1  ;
        end
        default:
        begin
            rdata0_reg[0] <= rdata0_reg[0];
            rdata0_reg[1] <= rdata0_reg[1];
            rdata0_reg[2] <= rdata0_reg[2];
            rdata0_reg[3] <= rdata0_reg[3];
            rdata1_reg[0] <= rdata1_reg[0];
            rdata1_reg[1] <= rdata1_reg[1];
            rdata1_reg[2] <= rdata1_reg[2];
            rdata1_reg[3] <= rdata1_reg[3];
        end
    endcase
end

always@(posedge rclk)begin
    rdata0 <= rdata0_reg[0];
    rdata1 <= rdata0_reg[1];
    rdata2 <= rdata0_reg[2];
    rdata3 <= rdata0_reg[3];
    rdata4 <= rdata1_reg[0];
    rdata5 <= rdata1_reg[1];
    rdata6 <= rdata1_reg[2];
    rdata7 <= rdata1_reg[3];
end



bram_asymmetric_r2_w1_port
#(
    .C_ADDR_WIDTH(C_ADDR_WIDTH),
    .C_DATA_WIDTH(C_DATA_WIDTH)
)bram_inst1
(
    .wclk    (wclk),
    .wen     (wen),
    .waddr   (waddr),
    .wdata   (wdata),

    .rclk    (rclk_4x),
    .raddr1  (raddr_sel_0),
    .rdata1  (rdata_sel_0),
    .raddr2  (raddr_sel_1),
    .rdata2  (rdata_sel_1)
);


endmodule