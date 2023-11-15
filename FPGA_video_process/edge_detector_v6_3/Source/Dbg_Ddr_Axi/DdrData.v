
`timescale 100ps/10ps
// `define   D_Sim_Debug 

///////////////////////////////////////////////////////////
/**********************************************************
  功能描述：
  
  重要输入信号要求：
  详细设计方案文件编号：
  仿真文件名：
  
  编制：朱仁昌
  创建日期： 2019-11-21
  版本：V1、0
  修改记录：
**********************************************************/

module DdrWrDataGen   
(   
  SysClk    , //System Clock
  WrAddrIn  , //(I)[DdrWrDataGen]Write Address Input 
  WrStartEn , //(I)[DdrWrDataGen]Write Start Enable
  WriteEn   , //(I)[DdrWrDataGen]Write Enable
  WrMaskEn  , //(I)[DdrWrDataGen]Write Mask Enable
  DdrWrMask , //(I)[DdrWrDataGen]DDR Write Mask
  DdrWrData   //(O)[DdrWrDataGen]DDR Write Data
);

  //Define  Parameter
  /////////////////////////////////////////////////////////    
  parameter   AXI_DATA_WIDTH = 256 ;

  localparam  [15:0]  AXI_BYTE_NUM  =   AXI_DATA_WIDTH/8  ;
  localparam          AXI_BYTE_CNT_WIDTH  = $clog2(AXI_BYTE_NUM) ;


  localparam    ADW   = AXI_DATA_WIDTH      ;
  localparam    ABN   = AXI_BYTE_NUM        ;
  localparam    ABW   = AXI_BYTE_CNT_WIDTH  ;

  localparam    TCo_C  = 1;    
  /////////////////////////////////////////////////////////   
  input                 SysClk      ; //System Clock
  input   [31:0]        WrAddrIn    ; //(I)[DdrWrDataGen]Write Address Input 
  input                 WrStartEn   ; //(I)[DdrWrDataGen]Write Start Enale
  input                 WriteEn     ; //(I)[DdrWrDataGen]Write Enable
  input                 WrMaskEn    ; //(I)[DdrWrDataGen]Write Mask Enable
  output  [ABN-1:0]     DdrWrMask   ; //(I)[DdrWrDataGen]DDR Write Mask
  output  [ADW-1:0]     DdrWrData   ; //(O)[DdrWrDataGen]DDR Write Data          
    
//1111111111111111111111111111111111111111111111111111111
//  
//  Input：
//  output：
//***************************************************/ 
  /////////////////////////////////////////////////////////
  reg   [    7:0]   First_D_Gen   [ABN-1:0]   ;
  reg   [    7:0]   Wr_Data_Gen   [ABN-1:0]   ;
  reg   [ABN-1:0]   Wr_Mask_Gen = {ABN{1'h1}} ;

  wire  [15:0]   Write_Addr  = {WrAddrIn[15:ABW],{ABW{1'h0}}} ;

  genvar   i ;
  generate
    for ( i=0;i<ABN;i=i+1 )
    begin
      always @ (posedge SysClk)
      begin
        // Wr_Mask_Gen[i]        <=  (Write_Addr[ABW*2-1:ABW]!=i ) ;
        // Wr_Data_Gen[i][7:0]   <=  (Write_Addr[7:0]    +   i   ) ; 
        // if (WriteEn)  Wr_Mask_Gen[i]        <=  (Write_Addr[ABW*2-1:ABW]!=i ) ;
        // if (WriteEn)  Wr_Data_Gen[i][7:0]   <=  (Write_Addr[7:0]    +   i   ) ; 
        if (WrStartEn)      Wr_Mask_Gen[i]        <=  (Write_Addr[ABW*2-1:ABW]!=i)    ;
        else if (WriteEn)   Wr_Mask_Gen[i]        <=  (i==0) ? Wr_Mask_Gen[ABN-1] : Wr_Mask_Gen[i-1]  ;
        if (WrStartEn)      Wr_Data_Gen[i][7:0]   <=  ( Write_Addr[7:0]      +   i  ) ; 
        else if (WriteEn)   Wr_Data_Gen[i][7:0]   <=  Wr_Data_Gen[i][7:0] + AXI_BYTE_NUM  ;  
      end
    end
  endgenerate

  /////////////////////////////////////////////////////////    
  wire  [ADW-1:0]   Wr_Data ; //MIPI Tx Data
  wire  [ABN-1:0]   Wr_Mask ;

  genvar j;
  generate
    for ( j=0;j<ABN;j=j+1 )
    begin
      assign  Wr_Data[j*8+:8]  = (WrMaskEn &  (~Wr_Mask_Gen[j]))  ? (~Wr_Data_Gen[j][7:0])  : Wr_Data_Gen[j][7:0]  ;
      assign  Wr_Mask[j]       =  WrMaskEn ?  Wr_Mask_Gen[j]      : {ABN{1'h1}};
    end
  endgenerate
   
  /////////////////////////////////////////////////////////   
  reg  [ADW-1:0]  Data_Cnt ;

  always  @(posedge SysClk)
  begin
    if (WrStartEn)
    begin
      Data_Cnt[    31 : 0 ]   <=  WrAddrIn ;
      Data_Cnt[ADW-1  : 32]   <=  0 ;
    end
    else   if (WriteEn)   Data_Cnt <= Data_Cnt + AXI_BYTE_NUM;
  end       

  /////////////////////////////////////////////////////////   

`ifdef  D_Sim_Debug

  wire  [ABN-1:0]     DdrWrMask   = {ABN{1'h1}} ; //(I)[DdrWrDataGen]DDR Write Mask
  wire  [ADW-1:0]     DdrWrData   = Data_Cnt    ; //(O)[DdrWrDataGen]DDR Write Data   

`else 

  wire  [ABN-1:0]     DdrWrMask   = Wr_Mask     ; //(I)[DdrWrDataGen]DDR Write Mask
  wire  [ADW-1:0]     DdrWrData   = Wr_Data     ; //(O)[DdrWrDataGen]DDR Write Data  
  
`endif 

  /////////////////////////////////////////////////////////   

//111111111111111111111111111111111111111111111111111111111

  
  
endmodule 
  
  
  
  
  
  

///////////////////////////////////////////////////////////
/**********************************************************
  功能描述：
  
  重要输入信号要求：
  详细设计方案文件编号：
  仿真文件名：
  
  编制：朱仁昌
  创建日期： 2019-11-21
  版本：V1、0
  修改记录：
**********************************************************/

module DdrRdDataChk 
(   
  SysClk      , //(I)System Clock
  RdAddrIn    , //(I)[DdrRdDataChk]Read Address Input  
  RdDataEn    , //(I)[DdrRdDataChk]DDR Read Data Valid         
  DdrRdData   , //(I)[DdrRdDataChk]DDR Read DataOut      
  DdrRdError  , //(O)[DdrRdDataChk]DDR Prbs Error         
  DdrRdRight    //(O)[DdrRdDataChk]DDR Read Right           
);

  //Define  Parameter
  /////////////////////////////////////////////////////////
  parameter RIGHT_CNT_WIDTH = 12  ;
  parameter AXI_DATA_WIDTH  = 256 ;
    
  localparam  [15:0]  AXI_BYTE_NUM  =   AXI_DATA_WIDTH/8  ;
  localparam          AXI_BYTE_CNT_WIDTH  = $clog2(AXI_BYTE_NUM) ;


  localparam    ADW   = AXI_DATA_WIDTH      ;
  localparam    ABN   = AXI_BYTE_NUM        ;
  localparam    ABW   = AXI_BYTE_CNT_WIDTH  ;

  localparam    AXI_LONGWORD_NUM    = AXI_DATA_WIDTH/32;
  
  // localparam  [15:0]  AXI_BYTE_NUM  =   AXI_DATA_WIDTH/8  ;
  // localparam    AXI_BYTE_CNT_WIDTH  = $clog2(AXI_BYTE_NUM) ;


  // localparam    ADW   = AXI_DATA_WIDTH    ;
  // localparam    ABN   = AXI_BYTE_NUM      ;
  localparam    LWN_C = AXI_LONGWORD_NUM  ;
  
  localparam   TCo_C     = 1;    
  /////////////////////////////////////////////////////////
  input               SysClk      ; //(I)System Clock
  input   [   31:0]   RdAddrIn    ; //(I)[DdrRdDataChk]Read Address Input  
  input               RdDataEn    ; //(I)[DdrRdDataChk]DDR Read Data Valid         
  input   [ADW-1:0]   DdrRdData   ; //(I)[DdrRdDataChk]DDR Read DataOut      
  output              DdrRdError  ; //(O)[DdrRdDataChk]DDR Prbs Error         
  output              DdrRdRight  ; //(O)[DdrRdDataChk]DDR Read Right  
  
//1111111111111111111111111111111111111111111111111111111
//  
//  Input：
//  output：
//***************************************************/ 
  
  /////////////////////////////////////////////////////////
  wire [15:0] CalcAddrValue    = RdAddrIn[31:16] + RdAddrIn[15:0];  
  
  reg [LWN_C-1:0]  ChkValue  = {LWN_C{1'h0}};
  reg [LWN_C-1:0]  ChkFlag   = {LWN_C{1'h0}};
    
  always @( posedge SysClk)  
  begin
    ChkValue[0]   <= # TCo_C DdrRdData[15: 0] ==  CalcAddrValue    ;
    ChkFlag [0]   <= # TCo_C DdrRdData[31:16] == (CalcAddrValue[2] ? 16'haaaa : 16'h5555);
  end
  
  /////////////////////////////////////////////////////////
  reg [15:0]  AddrValueReg = 16'h0;
  
  always @( posedge SysClk)  AddrValueReg <= # TCo_C CalcAddrValue;
  
  /////////////////////////////////////////////////////////
  genvar  j;
  generate  
    for (j=1;j<LWN_C;j=j+1)
    begin : DdrRdDataChk_Check
      always @( posedge SysClk)  
      begin
        ChkValue[j]   <= # TCo_C DdrRdData[j*32+15 : j*32   ] ==  ( DdrRdData[(j-1)*32+15 : (j-1)*32   ]  + 16'h4)  ;
        ChkFlag [j]   <= # TCo_C DdrRdData[j*32+31 : j*32+16] ==  (~DdrRdData[(j-1)*32+31 : (j-1)*32+16]  )         ;
      end
    end
  endgenerate

  /////////////////////////////////////////////////////////
  reg  [2:0]  RdDataEnReg = 3'h0;
  
  always @( posedge SysClk)  RdDataEnReg <= # TCo_C {RdDataEnReg[1:0],RdDataEn};
  
  /////////////////////////////////////////////////////////
  reg  CheckDataErr = 1'h0;
  
  always @( posedge SysClk)  if (RdDataEnReg[0])  CheckDataErr <= # TCo_C ~((&ChkValue) & (&ChkFlag));
  
  /////////////////////////////////////////////////////////
  reg   RdDataErr = 1'h0;
  reg   [ABN-1:0] Data_Err  = {ABN{1'h0}}  ;
  
`ifdef  D_Sim_Debug

  always @( posedge SysClk)  if (RdDataEn)  RdDataErr <= # TCo_C RdAddrIn[31:0] != DdrRdData[31:0] ;

`else 

  wire    [7:0]  Read_Addr = {RdAddrIn[7:ABW],{ABW{1'h0}}}  ;
  genvar   i ;
  generate
    for ( i=0;i<ABN;i=i+1 )
    begin
      always @ (posedge SysClk) if (RdDataEn)
      begin
        if (i==0)   Data_Err[0]   <=  (Read_Addr[7:0]     !=  DdrRdData[7:0]     )  ;
        else        Data_Err[i]   <=  (DdrRdData[i*8+:8]  != (Read_Addr[7:0] + i))  ;
      end
    end
  endgenerate

  always @( posedge SysClk)  if (RdDataEn)  RdDataErr <= # TCo_C |Data_Err  ; 
  
`endif 

  /////////////////////////////////////////////////////////
  reg [RIGHT_CNT_WIDTH-1:0] TimeOutCnt = {RIGHT_CNT_WIDTH{1'h0}};
  
  always @( posedge SysClk)  
  begin
    if (RdDataEnReg[0])   TimeOutCnt <= # TCo_C {RIGHT_CNT_WIDTH{1'h0}};
    else                  TimeOutCnt <= # TCo_C TimeOutCnt + {{(RIGHT_CNT_WIDTH-1){1'h0}},(~&TimeOutCnt)};
  end
  
  wire  RightClr = TimeOutCnt[RIGHT_CNT_WIDTH-1];
  
  /////////////////////////////////////////////////////////
  reg [RIGHT_CNT_WIDTH-1:0] AddrRightCnt = {RIGHT_CNT_WIDTH{1'h0}};
  
  always @( posedge SysClk)  if (RdDataEnReg[1])
  begin
    if (RdDataErr)      AddrRightCnt <= # TCo_C {RIGHT_CNT_WIDTH{1'h0}};
    else if (RightClr)  AddrRightCnt <= # TCo_C {RIGHT_CNT_WIDTH{1'h0}};
    else                AddrRightCnt <= # TCo_C AddrRightCnt + {{(RIGHT_CNT_WIDTH-1){1'h0}},(~&AddrRightCnt)};
  end
  
  wire  AddrRight = &AddrRightCnt ;
  
/////////////////////////////////////////////////////////
  assign  DdrRdError  =   RdDataErr ; //(O)[DdrRdDataChk]DDR Prbs Error        
  assign  DdrRdRight  =   AddrRight ; //(O)[DdrRdDataChk]DDR Read Right  
  
/////////////////////////////////////////////////////////
//1111111111111111111111111111111111111111111111111111111

endmodule 
  
    
    
    