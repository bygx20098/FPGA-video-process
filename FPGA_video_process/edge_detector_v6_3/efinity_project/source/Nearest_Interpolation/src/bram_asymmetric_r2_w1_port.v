module bram_asymmetric_r2_w1_port
#(
    parameter C_ADDR_WIDTH  = 8,
    parameter C_DATA_WIDTH  = 8
)
(
    input  wire                     wclk    ,
    input  wire                     wen     ,
    input  wire [C_ADDR_WIDTH-1:0]  waddr   ,
    input  wire [C_DATA_WIDTH-1:0]  wdata   ,
    
    input  wire                     rclk    ,
    input  wire [C_ADDR_WIDTH-1:0]  raddr1  ,
    output reg  [C_DATA_WIDTH-1:0]  rdata1  ,
    input  wire [C_ADDR_WIDTH-1:0]  raddr2  ,
    output reg  [C_DATA_WIDTH-1:0]  rdata2  
);

localparam C_MEM_DEPTH = {C_ADDR_WIDTH{1'b1}};

reg     [C_DATA_WIDTH-1:0]      mem [C_MEM_DEPTH:0]; //声明存储器的寄存器
integer                         i;

initial
begin
        for(i = 0;i <= C_MEM_DEPTH;i = i+1) //存储器赋初值
            mem[i] = 0;
end

always @(posedge wclk)
begin
        if(wen == 1'b1)
            mem[waddr] <= wdata; 
        else
            mem[waddr] <= mem[waddr];
end

always @(posedge rclk)
begin
        rdata1 <= mem[raddr1];
        rdata2 <= mem[raddr2];
end


endmodule