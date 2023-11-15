
`timescale 100ps/10ps

////////////////// DdrWrCtrl /////////////////////////////
/**********************************************************
  Function Description:

  Establishment : Richard Zhu
  Create date   : 2020-01-09
  Versions      : V0.1
  Revision of records:
  Ver0.1

**********************************************************/

module  DdrWrCtrl
(
  //System Signal
  SysClk      , //System Clock
  Reset_N     , //System Reset
  //config AXI&DDR Operate Parameter
  CfgWrAddr   , //(I)Config Write Start Address
  CfgWrBLen   , //(I)Config Write Burst Length
  CfgWrSize   , //(I)Config Write Size
  //Operate Control & State
  RamWrStart  , //(I)Ram Operate Start
  RamWrEnd    , //(O)Ram Operate End
  RamWrAddr   , //(O)Ram Write Address
  RamWrNext   , //(O)Ram Write Next
  RamWrMask   , //(I)Ram Write Mask
  RamWrData   , //(I)Ram Write Data
  RamWrBusy   , //(O)Ram Write Busy
  RamWrALoad  , //(O)Ram Write Address Load
  //Axi Slave Interfac Signal
  AWID        , //(O)[WrAddr]Write address ID.
  AWADDR      , //(O)[WrAddr]Write address.
  AWLEN       , //(O)[WrAddr]Burst length.
  AWSIZE      , //(O)[WrAddr]Burst size.
  AWBURST     , //(O)[WrAddr]Burst type.
  AWLOCK      , //(O)[WrAddr]Lock type.
  AWVALID     , //(O)[WrAddr]Write address valid.
  AWREADY     , //(I)[WrAddr]Write address ready.
  /////////////
  WID         , //(O)[WrData]Write ID tag.
  WDATA       , //(O)[WrData]Write data.
  WSTRB       , //(O)[WrData]Write strobes.
  WLAST       , //(O)[WrData]Write last.
  WVALID      , //(O)[WrData]Write valid.
  WREADY      , //(I)[WrData]Write ready.
  /////////////
  BID         , //(I)[WrResp]Response ID tag.
  BVALID      , //(I)[WrResp]Write response valid.
  BREADY        //(O)[WrResp]Response ready.
);

  //Define  Parameter
  /////////////////////////////////////////////////////////
  parameter   TCo_C           = 1                 ;
                                                  
  parameter   AXI_ID_WIDTH    =   8               ;
  parameter   AXI_WR_ID       = 8'ha5             ;
  parameter   AXI_DATA_WIDTH  = 256               ;
                                                  
  localparam  AXI_BYTE_NUMBER = AXI_DATA_WIDTH/8  ;
  localparam  AXI_DATA_SIZE   = $clog2(AXI_BYTE_NUMBER) ;  
                                                  
  localparam  AIW             = AXI_ID_WIDTH      ;
  localparam  ADW_C           = AXI_DATA_WIDTH    ;
  localparam  ABN_C           = AXI_BYTE_NUMBER   ;

  /////////////////////////////////////////////////////////

  //Define Port
  /////////////////////////////////////////////////////////
  //System Signal
  input         SysClk    ;     //System Clock
  input         Reset_N   ;     //System Reset

  /////////////////////////////////////////////////////////
  //Operate Control & State
  input             RamWrStart  ; //(I)[DdrWrCtrl]Ram Operate Start
  output            RamWrEnd    ; //(O)[DdrWrCtrl]Ram Operate End
  output  [31:0]    RamWrAddr   ; //(O)[DdrWrCtrl]Ram Write Address
  output            RamWrNext   ; //(O)[DdrWrCtrl]Ram Write Next
  output            RamWrBusy   ; //(O)[DdrWrCtrl]Ram Write Busy
  input [ABN_C-1:0] RamWrMask   ; //(I)[DdrWrCtrl]Ram Write Mask
  input [ADW_C-1:0] RamWrData   ; //(I)[DdrWrCtrl]Ram Write Data
  output            RamWrALoad  ; //(O)Ram Write Address Load

  /////////////////////////////////////////////////////////
  //Config DDR Operate Parameter
  input   [31:0]    CfgWrAddr   ; //(I)[DdrWrCtrl]Config Write Start Address
  input   [ 7:0]    CfgWrBLen   ; //(I)[DdrWrCtrl]Config Write Burst Length
  input   [ 2:0]    CfgWrSize   ; //(I)[DdrWrCtrl]Config Write Size

  /////////////////////////////////////////////////////////
  output  [AIW-1:0]     AWID        ; //(O)[WrAddr]Write address ID. This signal is the identification tag for the write address group of signals.
  output  [   31:0]     AWADDR      ; //(O)[WrAddr]Write address. The write address gives the address of the first transfer in a write burst transaction.
  output  [    7:0]     AWLEN       ; //(O)[WrAddr]Burst length. The burst length gives the exact number of transfers in a burst. This information determines the number of data transfers associated with the address.
  output  [    2:0]     AWSIZE      ; //(O)[WrAddr]Burst size. This signal indicates the size of each transfer in the burst.
  output  [    1:0]     AWBURST     ; //(O)[WrAddr]Burst type. The burst type and the size information, determine how the address for each transfer within the burst is calculated.
  output  [    1:0]     AWLOCK      ; //(O)[WrAddr]Lock type. Provides additional information about the atomic characteristics of the transfer.
  output                AWVALID     ; //(O)[WrAddr]Write address valid. This signal indicates that the channel is signaling valid write address and control information.
  input                 AWREADY     ; //(I)[WrAddr]Write address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
  /////////////                 
  output  [AIW-1:0]     WID         ; //(O)[WrData]Write ID tag. This signal is the ID tag of the write data transfer.
  output  [ABN_C-1:0]   WSTRB       ; //(O)[WrData]Write strobes. This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight bits of the write data bus.
  output                WLAST       ; //(O)[WrData]Write last. This signal indicates the last transfer in a write burst.
  output                WVALID      ; //(O)[WrData]Write valid. This signal indicates that valid write data and strobes are available.
  input                 WREADY      ; //(O)[WrData]Write ready. This signal indicates that the slave can accept the write data.
  output  [ADW_C-1:0]   WDATA       ; //(I)[WrData]Write data.
  /////////////                 
  input   [AIW-1:0]     BID         ; //(I)[WrResp]Response ID tag. This signal is the ID tag of the write response.
  input                 BVALID      ; //(I)[WrResp]Write response valid. This signal indicates that the channel is signaling a valid write response.
  output                BREADY      ; //(O)[WrResp]Response ready. This signal indicates that the master can accept a write response.

//1111111111111111111111111111111111111111111111111111111
//  Process Address Channel
//  Input：
//  output：
//***************************************************/
  /////////////////////////////////////////////////////////
  reg     Sync_Clr  = 1'h0  ;

  always @( posedge SysClk or negedge Reset_N)
  begin
    if (~Reset_N)   Sync_Clr <= # TCo_C 1'h1 ;
    else            Sync_Clr <= # TCo_C 1'h0 ;
  end

  /////////////////////////////////////////////////////////
  wire  AddrReady = AWREADY;

  wire  [AIW-1:0]   Calc_Wr_Id  = ( CfgWrAddr >> AXI_DATA_SIZE ) ;

  /////////////////////////////////////////////////////////
  reg   [    7:0]   WrBurstLen  =  8'h0;
  reg   [AIW-1:0]   Axi_Wr_ID   =  8'h0;
  reg   [   31:0]   WrStartAddr = 32'h0;

  always @( posedge SysClk)   if(RamWrStart)  WrBurstLen  <= # TCo_C  CfgWrBLen;
  always @( posedge SysClk)   if(RamWrStart)  WrStartAddr <= # TCo_C  CfgWrAddr;

  always @( posedge SysClk)   if(RamWrStart)  Axi_Wr_ID   <= # TCo_C  Calc_Wr_Id ;

  /////////////////////////////////////////////////////////
  reg     AddrValid = 1'h0;
  wire    Addr_Req  ;

  wire AddrWrEn = (AddrValid & AddrReady);

  always @( posedge SysClk or negedge Reset_N)
  begin
    if (!Reset_N)         AddrValid <= # TCo_C 1'h0;
    else if (RamWrStart)  AddrValid <= # TCo_C 1'h1;
    else if (AddrWrEn)    AddrValid <= # TCo_C 1'h0;
  end

  /////////////////////////////////////////////////////////
  wire  [AIW-1:0]  AWID    = Axi_Wr_ID     ; //(O)[WrAddr]Write address ID. This signal is the identification tag for the write address group of signals.
  wire  [   31:0]  AWADDR  = WrStartAddr   ; //(O)[WrAddr]Write address. The write address gives the address of the first transfer in a write burst transaction.
  wire  [    7:0]  AWLEN   = WrBurstLen    ; //(O)[WrAddr]Burst length. The burst length gives the exact number of transfers in a burst. This information determines the number of data transfers associated with the address.

  wire  [    2:0]  AWSIZE  = CfgWrSize     ; //(O)[WrAddr]Burst size. This signal indicates the size of each transfer in the burst.
  wire  [    1:0]  AWBURST = 2'b01         ; //(O)[WrAddr]Burst type. The burst type and the size information, determine how the address for each transfer within the burst is calculated.
  wire  [    1:0]  AWLOCK  = 2'b00         ; //(O)[WrAddr]Lock type. Provides additional information about the atomic characteristics of the transfer.
  wire             AWVALID = AddrValid     ; //(O)[WrAddr]Write address valid. This signal indicates that the channel is signaling valid write address and control information.

  /////////////////////////////////////////////////////////

//1111111111111111111111111111111111111111111111111111111



//22222222222222222222222222222222222222222222222222222
//  Process DDR Operate
//  Input：
//  output：
//***************************************************/

  /////////////////////////////////////////////////////////
  wire  DataWrReady     = WREADY  ;

  /////////////////////////////////////////////////////////
  reg   DataWrValid     = 1'h0    ;
  reg   DataWrLast      = 1'h0    ;
                        
  wire  DataWrEn        = DataWrValid & DataWrReady              ;
  wire  DataWrEnd       = DataWrValid & DataWrReady & DataWrLast ;

  assign  Addr_Req      = DataWrEnd   ;

  /////////////////////////////////////////////////////////
  reg   DataWrAddrAva   = 1'h0 ;
  reg   DataWrStart     = 1'h0 ;

  always @( posedge SysClk or negedge Reset_N)
  begin
    if (~Reset_N)       DataWrAddrAva <= # TCo_C 1'h0;
    else if (DataWrEnd) DataWrAddrAva <= # TCo_C 1'h0;
    else if (AddrWrEn)  DataWrAddrAva <= # TCo_C DataWrValid;
  end
    
  wire	DataWrNextBrst  = (AddrWrEn | DataWrAddrAva ) & DataWrEnd;
  
  always @( posedge SysClk)  DataWrStart    <= # TCo_C (AddrWrEn & (~DataWrValid)) | DataWrNextBrst;
  
  /////////////////////////////////////////////////////////
  always @( posedge SysClk or negedge Reset_N)
  begin
    if (!Reset_N)           DataWrValid  <= # TCo_C 1'h0;
    else if (DataWrStart)   DataWrValid  <= # TCo_C 1'h1;
    else if (DataWrEnd)     DataWrValid  <= # TCo_C 1'h0;
  end

  /////////////////////////////////////////////////////////
  reg   [7:0]   WrBurstCnt = 8'h0;

  always @( posedge SysClk or negedge Reset_N)
  begin
    if (!Reset_N)           WrBurstCnt  <= # TCo_C 8'h0;
    else if (DataWrStart)   WrBurstCnt  <= # TCo_C WrBurstLen;
    else if (DataWrEn)      WrBurstCnt  <= # TCo_C WrBurstCnt - {7'h0,(|WrBurstCnt)};
  end

  always @( posedge SysClk)
  begin
    if (DataWrStart)      DataWrLast <= # TCo_C  (~|WrBurstLen);
    else if (DataWrEn)    DataWrLast <= # TCo_C  (WrBurstCnt == 8'h1);
    else if (DataWrEnd)   DataWrLast <= # TCo_C  1'h0;
  end

  /////////////////////////////////////////////////////////
  wire  [AIW  -1:0]   WID     = Axi_Wr_ID     ; //(O)[WrData]Write ID tag. This signal is the ID tag of the write data transfer.
  wire  [ABN_C-1:0]   WSTRB   = RamWrMask     ; //(O)[WrData]Write strobes. This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight bits of the write data bus.
  wire                WVALID  = DataWrValid   ; //(O)[WrData]Write valid. This signal indicates that valid write data and strobes are available.
  wire                WLAST   = DataWrLast    ; //(O)[WrData]Write last. This signal indicates the last transfer in a write burst.
  wire  [ADW_C-1:0]   WDATA   = RamWrData     ; //(I)[WrData]Write data.

  /////////////////////////////////////////////////////////
  wire  RamWrALoad  = DataWrStart; //(O)Ram Write Address Load

//22222222222222222222222222222222222222222222222222222


//3333333333333333333333333333333333333333333333333333333
//  Write Address
//  Input：
//  output：
//***************************************************/

  /////////////////////////////////////////////////////////
  reg   [ 7:0]  WrByteNum   =  8'h0 ;
  reg   [31:0]  WrAddrCnt   = 32'h0 ;  //(O)Ram Write Address
  // reg   [ 7:0]  WrAddrStep  =  8'h0 ;

  genvar i ;
  generate 
    for (i=0;i<8;i=i+1)
    begin
      always @  (posedge SysClk) if (DataWrNextBrst | (~DataWrValid)) 
      begin
        if (i==CfgWrSize)   WrByteNum[i]  <= 1'h1 ;
        else                WrByteNum[i]  <= 1'h0 ;
      end
    end
  endgenerate

  always @( posedge SysClk)
  begin
    if (~DataWrValid)         WrAddrCnt <= # TCo_C WrStartAddr;
    else if (DataWrNextBrst)  WrAddrCnt <= # TCo_C WrStartAddr;
    else if (DataWrEn)        WrAddrCnt <= # TCo_C WrAddrCnt  + {24'h0,WrByteNum};
  end

  /////////////////////////////////////////////////////////
  reg   RamWrBusy = 1'h0; //(O)[DdrWrCtrl]Ram Write Busy

  always @( posedge SysClk or negedge Reset_N)
  begin
    if (~Reset_N)             RamWrBusy <= # TCo_C 1'h0 ;
    else if (DataWrStart)     RamWrBusy <= # TCo_C 1'h1 ;
    else if (DataWrEnd )      RamWrBusy <= # TCo_C 1'h0 ;
  end

  /////////////////////////////////////////////////////////
  reg   RamWrEnd    = 1'h0  ;   //(O)[DdrWrCtrl]Ram Operate End
 
  always @( posedge SysClk)   RamWrEnd  <= # TCo_C DataWrEnd  ;   
  
  /////////////////////////////////////////////////////////
  reg           DataGroupEn     = 1'h0 ;
  
  always @( * )    DataGroupEn = (WrAddrCnt[AXI_DATA_SIZE-1:0] 
                              + WrByteNum[AXI_DATA_SIZE-1:0]) 
                              == (AXI_BYTE_NUMBER[AXI_DATA_SIZE-1:0]);

  /////////////////////////////////////////////////////////  
  wire          RamWrNext = DataWrEn & DataGroupEn  ; //(O)[DdrWrCtrl]Ram Write Next
  wire  [31:0]  RamWrAddr = WrAddrCnt ; //(O)[DdrWrCtrl]Ram Write Address
  
  /////////////////////////////////////////////////////////
//333333333333333333333333333333333333333333333333333333333

//444444444444444444444444444444444444444444444444444444444
//  检查返回ID
//********************************************************/
  /////////////////////////////////////////////////////////
  reg     BackReady = 1'h0  ; //(O)[WrResp]Response ready. 
  wire    BackValid = BVALID;

  wire    BackRespond = BackReady & BackValid;

  /////////////////////////////////////////////////////////

  wire              InfoFifo_Wr_En     =  RamWrStart  ; //(I) Write Enable
  wire              InfoFifo_Rd_En     =  BackRespond ; //(I) Read Enable
  wire  [AIW-1:0]   InfoFifo_Wr_Data   =  Calc_Wr_Id  ; //(I) Write Data 
  wire  [AIW-1:0]   InfoFifo_Rd_Data   ; //(O) Read Data
  wire  [    3:0]   InfoFifo_Data_Num  ; //(O) Ram Data Number
  wire              InfoFifo_Fifo_Err  ; //(O) Fifo Error

  
  defparam  U5_Info_Fifo.OUT_REG       = "No"; //"Yes" Output Register Eanble ; "No"  Output Register Disble
  // defparam  U5_Info_Fifo.USE_BRAM      = "No"; //"Yee" Use BRAM ; "No" Use LEs
  defparam  U5_Info_Fifo.DATA_WIDTH    = AIW ; //Data Width
  defparam  U5_Info_Fifo.DATA_DEPTH    = 8   ; //Address Width 

  Axi_Test_Info_Fifo   U5_Info_Fifo
  (
    .Sys_Clk    ( SysClk            ) , //System Clock
    .Sync_Clr   ( Sync_Clr          ) , //Sync Reset
    .I_Wr_En    ( InfoFifo_Wr_En    ) , //Write Enable
    .I_Wr_Data  ( InfoFifo_Wr_Data  ) , //Write Data 
    .I_Rd_En    ( InfoFifo_Rd_En    ) , //Read Enable
    .O_Rd_Data  ( InfoFifo_Rd_Data  ) , //Read Data
    .O_Data_Num ( InfoFifo_Data_Num ) , //Ram Data Number
    .O_Fifo_Err ( InfoFifo_Fifo_Err )   //Fifo Error
  );

  /////////////////////////////////////////////////////////
  always @(posedge SysClk)    BackReady <= |InfoFifo_Data_Num ;//& (~BackRespond)  ;

  /////////////////////////////////////////////////////////
  reg     Back_ID_Right   = 1'h0 ;
  
  always @(posedge SysClk)  if (BackRespond)  Back_ID_Right <=  ( InfoFifo_Rd_Data  ==  BID ) ;

  /////////////////////////////////////////////////////////
  wire    BREADY = BackReady; //(O)[WrResp]Response ready. This signal indicates that the master can accept a write response.

  /////////////////////////////////////////////////////////

//444444444444444444444444444444444444444444444444444444444

endmodule

/////////////////// DdrWrCtrl ///////////////////////////////////








/////////////////// DdrRdCtrl ///////////////////////////////////
/**********************************************************
  Function Description:

  Establishment : Richard Zhu
  Create date   : 2020-01-09
  Versions      : V0.1
  Revision of records:
  Ver0.1

**********************************************************/
module  DdrRdCtrl
(
  //System Signal
  SysClk      , //System Clock
  Reset_N     , //System Reset
  //Operate Control & State
  RamRdStart  , //(I)Ram Read Start
  // RamRdSize   , //(I)Ram Read Size
  RamRdEnd    , //(O)Ram Read End
  RamRdAddr   , //(O)Ram Read Addrdss
  RamRdData   , //(O)Ram Read Data
  RamRdDAva   , //(O)Ram Read Available
  RamRdBusy   , //(O)Ram Read Busy
  RamRdALoad  , //(O)Ram Read Address Load
  //Config DDR & AXI Operate Parameter
  CfgRdSize   , //(I)Config Read Size
  CfgRdBurst  , //(I)Config Read Burst Type
  CfgRdLock   , //(I)Config Read Lock Flag
  CfgRdAddr   , //(I)Config Read Start Address
  CfgRdBLen   , //(I)[DdrOpCtrl]Config Read Burst Length
  //Axi4 Read Address & Data Bus
  ARID        , //(O)[RdAddr]Read address ID.
  ARADDR      , //(O)[RdAddr]Read address.
  ARLEN       , //(O)[RdAddr]Burst length.
  ARSIZE      , //(O)[RdAddr]Burst size.
  ARBURST     , //(O)[RdAddr]Burst type.
  ARLOCK      , //(O)[RdAddr]Lock type.
  ARVALID     , //(O)[RdAddr]Read address valid.
  ARREADY     , //(I)[RdAddr]Read address ready.
  /////////////
  RID         , //(I)[RdData]Read ID tag.
  RDATA       , //(I)[RdData]Read data.
  RRESP       , //(I)[RdData]Read response.
  RLAST       , //(I)[RdData]Read last.
  RVALID      , //(I)[RdData]Read valid.
  RREADY        //(O)[RdData]Read ready.
);

  //Define  Parameter
  /////////////////////////////////////////////////////////
  parameter   TCo_C           = 1;

  parameter   AXI_ID_WIDTH    =   8               ;
  parameter   AXI_RD_ID       = 8'ha5             ;
  parameter   AXI_DATA_WIDTH  = 256               ;

  localparam  AXI_BYTE_NUMBER = AXI_DATA_WIDTH/8  ;
  localparam  AXI_DATA_SIZE   = $clog2(AXI_BYTE_NUMBER) ;  
  
  localparam  AIW             = AXI_ID_WIDTH      ;
  localparam  ADW_C           = AXI_DATA_WIDTH    ;
  localparam  ABN_C           = AXI_BYTE_NUMBER   ;

  /////////////////////////////////////////////////////////

  //Define Port
  /////////////////////////////////////////////////////////
  //System Signal
  input         SysClk    ;     //System Clock
  input         Reset_N   ;     //System Reset

  /////////////////////////////////////////////////////////
  //Operate Control & State
  input               RamRdStart  ; //(I)[DdrRdCtrl]Ram Read Start
  // input   [      2:0] RamRdSize   ; //(I)Ram Read Size
  output              RamRdEnd    ; //(O)[DdrRdCtrl]Ram Read End
  output  [     31:0] RamRdAddr   ; //(O)[DdrRdCtrl]Ram Read Addrdss
  output              RamRdDAva   ; //(O)[DdrRdCtrl]Ram Read Available
  output              RamRdBusy   ; //(O)Ram Read Busy
  output              RamRdALoad  ; //(O)Ram Read Address Load
  output  [ADW_C-1:0] RamRdData   ; //(O)[DdrRdCtrl]Ram Read Data

  /////////////////////////////////////////////////////////
  //Config DDR & AXI Operate Parameter
  input   [      2:0] CfgRdSize   ; //(I)Config Read Size
  input   [      1:0] CfgRdBurst  ; //(I)Config Read Burst Type
  input   [      1:0] CfgRdLock   ; //(I)Config Read Lock Flag
  input   [     31:0] CfgRdAddr   ; //(I)[DdrRdCtrl]Config Read Start Address
  input   [      7:0] CfgRdBLen   ; //(I)[DdrRdCtrl]Config Read Burst Length

  /////////////////////////////////////////////////////////
  //Axi4 Read Address & Data Bus
  output  [AIW-1:0]   ARID        ; //(O)[RdAddr]Read address ID. This signal is the identification tag for the read address group of signals.
  output  [   31:0]   ARADDR      ; //(O)[RdAddr]Read address. The read address gives the address of the first transfer in a read burst transaction.
  output  [    7:0]   ARLEN       ; //(O)[RdAddr]Burst length. This signal indicates the exact number of transfers in a burst.
  output  [    2:0]   ARSIZE      ; //(O)[RdAddr]Burst size. This signal indicates the size of each transfer in the burst.
  output  [    1:0]   ARBURST     ; //(O)[RdAddr]Burst type. The burst type and the size information determine how the address for each transfer within the burst is calculated.
  output  [    1:0]   ARLOCK      ; //(O)[RdAddr]Lock type. This signal provides additional information about the atomic characteristics of the transfer.
  output              ARVALID     ; //(O)[RdAddr]Read address valid. This signal indicates that the channel is signaling valid read address and control information.
  input               ARREADY     ; //(I)[RdAddr]Read address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
  /////////////              
  input   [AIW-1:0]   RID         ; //(I)[RdData]Read ID tag. This signal is the identification tag for the read data group of signals generated by the slave.
  input   [    1:0]   RRESP       ; //(I)[RdData]Read response. This signal indicates the status of the read transfer.
  input               RLAST       ; //(I)[RdData]Read last. This signal indicates the last transfer in a read burst.
  input               RVALID      ; //(I)[RdData]Read valid. This signal indicates that the channel is signaling the required read data.
  output              RREADY      ; //(O)[RdData]Read ready. This signal indicates that the master can accept the read data and response information.
  input   [ADW_C-1:0] RDATA       ; //(I)[RdData]Read data.


  /////////////////////////////////////////////////////////

//111111111111111111111111111111111111111111111111111111111
//  Process AXI Operate Parameter
//  Input：
//  output：
//********************************************************/
  /////////////////////////////////////////////////////////
  reg     Sync_Clr  = 1'h0  ;

  always @( posedge SysClk or negedge Reset_N)
  begin
    if (~Reset_N)   Sync_Clr <= # TCo_C 1'h1 ;
    else            Sync_Clr <= # TCo_C 1'h0 ;
  end

  /////////////////////////////////////////////////////////
  wire  AddrReady = ARREADY;

  wire  [ 7:0]  Calc_Rd_Id  =  ( CfgRdAddr >> AXI_DATA_SIZE ) ;

  /////////////////////////////////////////////////////////
  reg   [    2:0]  RdDataSize  =  1'h0 ;
  reg   [    1:0]  RdBurstType =  1'h0 ;
  reg   [    1:0]  RdLockFlag  =  1'h0 ;
  reg   [    7:0]  RdBurstLen  =  8'h0 ;
  reg   [AIW-1:0]  Axi_Rd_ID   =  8'h0 ;
  reg   [   31:0]  RdStartAddr = 32'h0 ;

  always @( posedge SysClk)   if(RamRdStart)  RdDataSize    <= # TCo_C  CfgRdSize   ;
  always @( posedge SysClk)   if(RamRdStart)  RdBurstType   <= # TCo_C  CfgRdBurst  ;
  always @( posedge SysClk)   if(RamRdStart)  RdLockFlag    <= # TCo_C  CfgRdLock   ;
  always @( posedge SysClk)   if(RamRdStart)  RdBurstLen    <= # TCo_C  CfgRdBLen   ;
  always @( posedge SysClk)   if(RamRdStart)  Axi_Rd_ID     <= # TCo_C  Calc_Rd_Id  ;
  always @( posedge SysClk)   if(RamRdStart)  RdStartAddr   <= # TCo_C  CfgRdAddr   ;

  /////////////////////////////////////////////////////////
  reg     RdAddr_Pause    = 1'h0  ;
  reg     RdAddr_ReStart  = 1'h0  ;
  reg     AddrValid       = 1'h0  ; //(I)[RdAddr]Read address valid. This signal indicates that the channel is signaling valid read address and control information.

  wire AddrRdEn   = (AddrValid & AddrReady);

  always @( posedge SysClk or negedge Reset_N)
  begin
    if (!Reset_N)             AddrValid <= # TCo_C 1'h0 ;
    else if (RamRdStart)      AddrValid <= # TCo_C 1'h1 ;
    else if (AddrRdEn)        AddrValid <= # TCo_C 1'h0 ;
  end

  /////////////////////////////////////////////////////////
  wire             ARVALID = AddrValid     ; //(I)[RdAddr]Read address valid. This signal indicates that the channel is signaling valid read address and control information.
  wire  [    2:0]  ARSIZE  = RdDataSize    ; //(I)[RdAddr]Burst size. This signal indicates the size of each transfer in the burst.
  wire  [    1:0]  ARBURST = RdBurstType   ; //(I)[RdAddr]Burst type. The burst type and the size information determine how the address for each transfer within the burst is calculated.
  wire  [    1:0]  ARLOCK  = RdLockFlag    ; //(I)[RdAddr]Lock type. This signal provides additional information about the atomic characteristics of the transfer.
  wire  [    7:0]  ARLEN   = RdBurstLen    ; //(I)[RdAddr]Burst length. This signal indicates the exact number of transfers in a burst.
  wire  [AIW-1:0]  ARID    = Axi_Rd_ID     ; //(I)[RdAddr]Read address ID. This signal is the identification tag for the read address group of signals.
  wire  [   31:0]  ARADDR  = RdStartAddr   ; //(I)[RdAddr]Read address. The read address gives the address of the first transfer in a read burst transaction.

  /////////////////////////////////////////////////////////
//111111111111111111111111111111111111111111111111111111111

//222222222222222222222222222222222222222222222222222222222
//  Process DDR Operate
//********************************************************/
  /////////////////////////////////////////////////////////
  wire  [AIW  -1:0]   DataRdId    = RID     ; //(O)[RdData]Read ID tag. This signal is the identification tag for the read data group of signals generated by the slave.
  wire  [      1:0]   DataRdResp  = RRESP   ; //(O)[RdData]Read response. This signal indicates the status of the read transfer.
  wire                DataRdLast  = RLAST   ; //(O)[RdData]Read last. This signal indicates the last transfer in a read burst.
  wire                DataRdValid = RVALID  ; //(O)[RdData]Read valid. This signal indicates that the channel is signaling the required read data.
  wire  [ADW_C-1:0]   DataRdData  = RDATA   ; //(O)[RdData]Read data.

  /////////////////////////////////////////////////////////
  reg   DataRdReady = 1'h0;

  wire  DataRdEn    = DataRdReady & DataRdValid;
  wire  DataRdEnd   = DataRdReady & DataRdValid & DataRdLast;

  /////////////////////////////////////////////////////////
  reg   DataRdAddrAva     = 1'h0;
  reg   DataRdNextBrst    = 1'h0;
  reg   DataRdStart       = 1'h0;

  always @( posedge SysClk or negedge Reset_N)
  begin
    if (~Reset_N)       DataRdAddrAva <= # TCo_C 1'h0;
    else if (AddrRdEn)  DataRdAddrAva <= # TCo_C DataRdReady;
    else if (DataRdEnd) DataRdAddrAva <= # TCo_C 1'h0;
  end

  always @( * )  DataRdNextBrst <= # TCo_C (AddrRdEn | DataRdAddrAva ) & DataRdEnd;
  // always @( posedge SysClk)  DataRdStart    <= # TCo_C (AddrRdEn ) | DataRdNextBrst;
  // always @( posedge SysClk)  DataRdStart    <= # TCo_C (AddrRdEn & (~DataRdReady)) | DataRdNextBrst;

  /////////////////////////////////////////////////////////
  reg  RamRdALoad  = 1'h0 ;

  always @( posedge SysClk)   RamRdALoad  <=  AddrRdEn  ;

  // wire  RamRdALoad =  DataRdStart; //(O)Ram Read Address Load;

//222222222222222222222222222222222222222222222222222222222

//333333333333333333333333333333333333333333333333333333333
//
//********************************************************/

  ////////////////////////////////////////////////////////
  wire  [AIW+46:0]  InfoFifo_Wr_Data  = { Calc_Rd_Id  ,
                                          CfgRdSize   ,
                                          CfgRdBurst  ,
                                          CfgRdLock   ,
                                          CfgRdBLen   ,
                                          CfgRdAddr   } ; //(I) Write Data 

  wire              InfoFifo_Wr_En     =  RamRdStart      ; //(I) Write Enable
  wire              InfoFifo_Rd_En     ;//=  DataRdEnd       ; //(I) Read Enable
  wire  [AIW+46:0]  InfoFifo_Rd_Data   ; //(O) Read Data
  wire  [    3 :0]  InfoFifo_Data_Num  ; //(O) Ram Data Number
  wire              InfoFifo_Wr_Full   ; //(O) FIFO Write Full
  wire              InfoFifo_Rd_Empty  ; //(O) FIFO Write Empty
  wire              InfoFifo_Fifo_Err  ; //(O) Fifo Error

  
  defparam  U3_Info_Fifo.OUT_REG       = "No"   ; //"Yes" Output Register Eanble ; "No"  Output Register Disble
  // defparam  U3_Info_Fifo.USE_BRAM      = "No"   ; //"Yee" Use BRAM ; "No" Use LEs
  defparam  U3_Info_Fifo.DATA_WIDTH    = AIW+47 ; //Data Width
  defparam  U3_Info_Fifo.DATA_DEPTH    = 8      ; //Address Width 

  Axi_Test_Info_Fifo   U3_Info_Fifo
  (
    .Sys_Clk    ( SysClk            ) , //System Clock
    .Sync_Clr   ( Sync_Clr          ) , //Sync Reset
    .I_Wr_En    ( InfoFifo_Wr_En    ) , //Write Enable
    .I_Wr_Data  ( InfoFifo_Wr_Data  ) , //Write Data 
    .I_Rd_En    ( InfoFifo_Rd_En    ) , //Read Enable
    .O_Rd_Data  ( InfoFifo_Rd_Data  ) , //Read Data
    .O_Data_Num ( InfoFifo_Data_Num ) , //Ram Data Number
    .O_Wr_Full  ( InfoFifo_Wr_Full  ) , //(O) FIFO Write Full
    .O_Rd_Empty ( InfoFifo_Rd_Empty ) , //(O) FIFO Write Empty
    .O_Fifo_Err ( InfoFifo_Fifo_Err )   //Fifo Error
  );

  wire  [AIW-1:0]   Info_Axi_Rd_ID   = InfoFifo_Rd_Data[AIW+46:47]  ;
  wire  [    2:0]   Info_RdDataSize  = InfoFifo_Rd_Data[    46:44]  ;
  wire  [    1:0]   Info_RdBurstType = InfoFifo_Rd_Data[    43:42]  ;
  wire  [    1:0]   Info_RdLockFlag  = InfoFifo_Rd_Data[    41:40]  ;
  wire  [    7:0]   Info_RdBurstLen  = InfoFifo_Rd_Data[    39:32]  ;
  wire  [   31:0]   Info_RdStartAddr = InfoFifo_Rd_Data[    31: 0]  ;  

  assign InfoFifo_Rd_En = DataRdEnd ;//| (~InfoFifo_Rd_Empty & InfoFifo_Wr_En) ;

  always @( posedge SysClk)  DataRdStart    <= # TCo_C InfoFifo_Rd_Empty ? RamRdStart : DataRdEnd ;
  // always @( posedge SysClk)  DataRdStart    <= # TCo_C (AddrRdEn & (~DataRdReady)) 
  //                                                     |(InfoFifo_Rd_Empty & RamRdStart);
  /////////////////////////////////////////////////////////

  always @( posedge SysClk)   RdAddr_Pause    <=  ( &InfoFifo_Data_Num[2:1])  ;
  always @( posedge SysClk)   RdAddr_ReStart  <=  (~&InfoFifo_Data_Num[2:1])  & RdAddr_Pause ;

  /////////////////////////////////////////////////////////
//333333333333333333333333333333333333333333333333333333333

//444444444444444444444444444444444444444444444444444444444
//
//********************************************************/
  /////////////////////////////////////////////////////////
  reg [7:0] DataRdTimeOut   = 8'hff ;
  reg       DataRdReadyClr  = 1'h0  ;

  always @( posedge SysClk)
  begin
    if (~DataRdReady)       DataRdTimeOut <= # TCo_C 8'hff;
    else if (DataRdValid)   DataRdTimeOut <= # TCo_C 8'hff;
    else                    DataRdTimeOut <= # TCo_C DataRdTimeOut - {7'h0, (|DataRdTimeOut)};
  end

  always @( posedge SysClk)  DataRdReadyClr <= # TCo_C (DataRdTimeOut == 5'h1);

  /////////////////////////////////////////////////////////
  reg [7:0] RdBurstCnt      = 8'h0;
  reg       DataRdLastFlag  = 1'h0;

  always @( posedge SysClk or negedge Reset_N)
  begin
    if (! Reset_N)            RdBurstCnt <= # TCo_C 8'h0;
    else if ( InfoFifo_Rd_En & (|InfoFifo_Data_Num) )  
    begin
      RdBurstCnt <= # TCo_C Info_RdBurstLen ;
    end
    else if ( InfoFifo_Wr_En &  (~|InfoFifo_Data_Num) )
    begin
      RdBurstCnt <= # TCo_C CfgRdBLen ;
    end
    else if (DataRdEn) RdBurstCnt <= # TCo_C RdBurstCnt      - {7'h0,(|RdBurstCnt)}  ;
  end

  // always @( posedge SysClk or negedge Reset_N)
  // begin
  //   if (! Reset_N)          RdBurstCnt <= # TCo_C 8'h0;
  //   else if (DataRdStart)   RdBurstCnt <= # TCo_C Info_RdBurstLen ;
  //   else if (DataRdEn)      RdBurstCnt <= # TCo_C RdBurstCnt      - {7'h0,(|RdBurstCnt)}  ;
  // end

  always @( posedge SysClk)
  begin
    if (! Reset_N)                DataRdLastFlag  <= # TCo_C 1'h0       ;
    else if (DataRdLastFlag)      
    begin
      if (|Info_RdBurstLen)       DataRdLastFlag  <= # TCo_C ~DataRdEn  ;
    end
    else if (|InfoFifo_Data_Num)  
    begin
      if (InfoFifo_Rd_En)         DataRdLastFlag  <= # TCo_C ( Info_RdBurstLen == 0 ) ;
    end
    else if (InfoFifo_Wr_En)      DataRdLastFlag  <= # TCo_C ( CfgRdBLen == 0 ) ;
    else if (DataRdEn)            DataRdLastFlag <= # TCo_C ( RdBurstCnt       == 8'h1  ) ;
  end
  // always @( posedge SysClk)
  // begin
  //   if (DataRdStart)    DataRdLastFlag <= # TCo_C ( Info_RdBurstLen  == 8'h0  ) ;
  //   // else if (DataRdEn)  DataRdLastFlag <= # TCo_C ( InfoFifo_Data_Num  == 8'h1  ) ;
  //   else if (DataRdEn)  DataRdLastFlag <= # TCo_C ( RdBurstCnt       == 8'h1  ) ;
  //   else if (DataRdEnd) DataRdLastFlag <= # TCo_C ( RdBurstCnt       == 8'h0  ) ;
  // end

  wire  DataRdEndFlag = DataRdLastFlag & DataRdEn ;

  /////////////////////////////////////////////////////////
  reg   DataRdEndReg;
  
  always @( posedge SysClk)  DataRdEndReg <= # TCo_C DataRdEnd;  
  
  /////////////////////////////////////////////////////////
  always @( posedge SysClk or negedge Reset_N)
  begin
    if (!Reset_N)             DataRdReady  <= # TCo_C 1'h0  ;
    else if (DataRdReadyClr)  DataRdReady  <= # TCo_C 1'h0  ;
    else if (DataRdEndReg)    DataRdReady  <= # TCo_C 1'h0  ;
    else if (DataRdEnd  )     DataRdReady  <= # TCo_C 1'h0  ;
    else if (DataRdEndFlag)   DataRdReady  <= # TCo_C 1'h0  ;
    else                      DataRdReady  <= # TCo_C (|InfoFifo_Data_Num) ;
  end

  /////////////////////////////////////////////////////////
  wire  RREADY  = DataRdReady ; //(I)[RdData]Read ready. This signal indicates that the master can accept the read data and response information.

  /////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////

//444444444444444444444444444444444444444444444444444444444

//555555555555555555555555555555555555555555555555555555555
//
//********************************************************/
  /////////////////////////////////////////////////////////
  // wire [7:0]   RdByteNum =  (8'h1 <<  Info_RdDataSize) ;
  reg   [ 7:0]  RdByteNum =  8'h1 ;
  reg   [31:0]  RdAddrCnt = 32'h0 ; //(O)[DdrRdCtrl]Ram Read Addrdss

  genvar i ;
  generate 
    for (i=0;i<8;i=i+1)
    begin
      always @  (posedge SysClk) if (DataRdStart) 
      begin
        if (i==Info_RdDataSize)   RdByteNum[i]  <= 1'h1 ;
        else                      RdByteNum[i]  <= 1'h0 ;
      end
    end
  endgenerate

  always @( posedge SysClk)
  begin
    if (DataRdStart)    RdAddrCnt <= # TCo_C Info_RdStartAddr ;
    else  if (DataRdEn) RdAddrCnt <= # TCo_C RdAddrCnt        + {24'h0,RdByteNum} ;
  end

  /////////////////////////////////////////////////////////
  reg   RamRdBusy   = 1'h0; //(O)Ram Read Busy

  always @( posedge SysClk)   RamRdBusy <= DataRdReady | DataRdAddrAva;

  /////////////////////////////////////////////////////////
  reg   DataRdBusy = 1'h0;

  always @( posedge SysClk)
  begin
    if (DataRdEnd)      DataRdBusy <= # TCo_C 1'h0;
    else if (DataRdEn)  DataRdBusy <= # TCo_C 1'h1;
  end

  /////////////////////////////////////////////////////////
  reg   RamRdEnd = 1'h0;   //(O)[DdrRdCtrl]Ram Read End
  
  // always @( posedge SysClk)  RamRdEnd  <= # TCo_C DataRdEnd ;//& DataRdBusy;   //(O)[DdrRdCtrl]Ram Read End

  always @( posedge SysClk)  RamRdEnd  <= # TCo_C DataRdEnd ;//DataRdEn & (~DataRdBusy) ;   //(O)[DdrRdCtrl]Ram Read End

  /////////////////////////////////////////////////////////
  reg                 RamRdDAva   =  1'h0 ; //(O)[DdrRdCtrl]Ram Read Available
  reg   [ADW_C-1:0]   RamRdData   = 32'h0 ; //(O)[DdrRdCtrl]Ram Read Data
  reg   [     31:0]   RamRdAddr   = 32'h0 ; //(O)[DdrRdCtrl]Ram Read Addrdss

  always @( posedge SysClk)                 RamRdDAva <= # TCo_C DataRdEn   ; //(O)[DdrRdCtrl]Ram Read Available
  always @( posedge SysClk)  if (DataRdEn)  RamRdData <= # TCo_C DataRdData ; //(O)[DdrRdCtrl]Ram Read Data
  always @( posedge SysClk)  if (DataRdEn)  RamRdAddr <= # TCo_C RdAddrCnt  ; //(O)[DdrRdCtrl]Ram Read Addrdss


  /////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////

//555555555555555555555555555555555555555555555555555555555

//666666666666666666666666666666666666666666666666666666666
//
//********************************************************/
  /////////////////////////////////////////////////////////
  reg   Read_ID_Right     = 0 ;
  reg   Read_Last_Right   = 0 ;

  always @( posedge SysClk)   if (DataRdEnd)  Read_ID_Right   <=  ( Info_Axi_Rd_ID  ==  RID) ;
  always @( posedge SysClk)   if (DataRdEnd)  Read_Last_Right <=    DataRdEndFlag   ;  

  /////////////////////////////////////////////////////////

//666666666666666666666666666666666666666666666666666666666

//777777777777777777777777777777777777777777777777777777777
//
//********************************************************/
  /////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////

//777777777777777777777777777777777777777777777777777777777

endmodule



/////////////////// DdrRdCtrl ///////////////////////////







/////////////////// Axi4FullDeplex ///////////////////////////
module Axi4FullDeplex
(
  //System Signal
  SysClk    , //System Clock
  Reset_N   , //System Reset
  //Axi Slave Interfac Signal
  AWID      , //(I)[WrAddr]Write address ID.
  AWADDR    , //(I)[WrAddr]Write address.
  AWLEN     , //(I)[WrAddr]Burst length.
  AWSIZE    , //(I)[WrAddr]Burst size.
  AWBURST   , //(I)[WrAddr]Burst type.
  AWLOCK    , //(I)[WrAddr]Lock type.
  AWVALID   , //(I)[WrAddr]Write address valid.
  AWREADY   , //(O)[WrAddr]Write address ready.
  ///////////
  WID       , //(I)[WrData]Write ID tag.
  WDATA     , //(I)[WrData]Write data.
  WSTRB     , //(I)[WrData]Write strobes.
  WLAST     , //(I)[WrData]Write last.
  WVALID    , //(I)[WrData]Write valid.
  WREADY    , //(O)[WrData]Write ready.
  ///////////
  BID       , //(O)[WrResp]Response ID tag.
  BVALID    , //(O)[WrResp]Write response valid.
  BREADY    , //(I)[WrResp]Response ready.
  ///////////
  ARID      , //(I)[RdAddr]Read address ID.
  ARADDR    , //(I)[RdAddr]Read address.
  ARLEN     , //(I)[RdAddr]Burst length.
  ARSIZE    , //(I)[RdAddr]Burst size.
  ARBURST   , //(I)[RdAddr]Burst type.
  ARLOCK    , //(I)[RdAddr]Lock type.
  ARVALID   , //(I)[RdAddr]Read address valid.
  ARREADY   , //(O)[RdAddr]Read address ready.
  ///////////
  RID       , //(O)[RdData]Read ID tag.
  RDATA     , //(O)[RdData]Read data.
  RRESP     , //(O)[RdData]Read response.
  RLAST     , //(O)[RdData]Read last.
  RVALID    , //(O)[RdData]Read valid.
  RREADY    , //(I)[RdData]Read ready.
  /////////////
  //DDR Controner AXI4 Signal
  aid       , //(O)[Addres] Address ID
  aaddr     , //(O)[Addres] Address
  alen      , //(O)[Addres] Address Brust Length
  asize     , //(O)[Addres] Address Burst size
  aburst    , //(O)[Addres] Address Burst type
  alock     , //(O)[Addres] Address Lock type
  avalid    , //(O)[Addres] Address Valid
  aready    , //(I)[Addres] Address Ready
  atype     , //(O)[Addres] Operate Type 0=Read, 1=Write
  /////////////
  wid       , //(O)[Write]  ID
  wdata     , //(O)[Write]  Data
  wstrb     , //(O)[Write]  Data Strobes(Byte valid)
  wlast     , //(O)[Write]  Data Last
  wvalid    , //(O)[Write]  Data Valid
  wready    , //(I)[Write]  Data Ready
  /////////////
  rid       , //(I)[Read]   ID
  rdata     , //(I)[Read]   Data
  rlast     , //(I)[Read]   Data Last
  rvalid    , //(I)[Read]   Data Valid
  rready    , //(O)[Read]   Data Ready
  rresp     , //(I)[Read]   Response
  /////////////
  bid       , //(I)[Answer] Response Write ID
  bvalid    , //(I)[Answer] Response valid
  bready      //(O)[Answer] Response Ready
);

  //Define  Parameter
  /////////////////////////////////////////////////////////
  parameter   TCo_C  = 1;

  parameter   DDR_WRITE_FIRST     = 1'h1;
  parameter   AXI_DATA_WIDTH      = 256 ;

  localparam  AXI_BYTE_NUMBER     = AXI_DATA_WIDTH/8  ;
                                                      
  parameter   AXI_ID_WIDTH    =   8         ;
  
  localparam  AIW                 = AXI_ID_WIDTH      ;
  localparam  ADW_C               = AXI_DATA_WIDTH    ;
  localparam  ABN_C               = AXI_BYTE_NUMBER   ;

  /////////////////////////////////////////////////////////

  //Define Port
  /////////////////////////////////////////////////////////
  //System Signal
  input               SysClk  ; //System Clock
  input               Reset_N ; //System Reset

  /////////////////////////////////////////////////////////
  //AXI4 Full Deplex
  input   [AIW  -1:0] AWID    ; //(I)[WrAddr]Write address ID. This signal is the identification tag for the write address group of signals.
  input   [     31:0] AWADDR  ; //(I)[WrAddr]Write address. The write address gives the address of the first transfer in a write burst transaction.
  input   [      7:0] AWLEN   ; //(I)[WrAddr]Burst length. The burst length gives the exact number of transfers in a burst. This information determines the number of data transfers associated with the address.
  input   [      2:0] AWSIZE  ; //(I)[WrAddr]Burst size. This signal indicates the size of each transfer in the burst.
  input   [      1:0] AWBURST ; //(I)[WrAddr]Burst type. The burst type and the size information, determine how the address for each transfer within the burst is calculated.
  input   [      1:0] AWLOCK  ; //(I)[WrAddr]Lock type. Provides additional information about the atomic characteristics of the transfer.
  input               AWVALID ; //(I)[WrAddr]Write address valid. This signal indicates that the channel is signaling valid write address and control information.
  output              AWREADY ; //(O)[WrAddr]Write address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
  /////////////  
  input   [AIW  -1:0] WID     ; //(I)[WrData]Write ID tag. This signal is the ID tag of the write data transfer.
  input   [ABN_C-1:0] WSTRB   ; //(I)[WrData]Write strobes. This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight bits of the write data bus.
  input               WLAST   ; //(I)[WrData]Write last. This signal indicates the last transfer in a write burst.
  input               WVALID  ; //(I)[WrData]Write valid. This signal indicates that valid write data and strobes are available.
  output              WREADY  ; //(O)[WrData]Write ready. This signal indicates that the slave can accept the write data.
  input   [ADW_C-1:0] WDATA   ; //(I)[WrData]Write data.
  /////////////  
  output  [AIW  -1:0] BID     ; //(O)[WrResp]Response ID tag. This signal is the ID tag of the write response.
  output              BVALID  ; //(O)[WrResp]Write response valid. This signal indicates that the channel is signaling a valid write response.
  input               BREADY  ; //(I)[WrResp]Response ready. This signal indicates that the master can accept a write response.
  /////////////  
  input   [AIW  -1:0] ARID    ; //(I)[RdAddr]Read address ID. This signal is the identification tag for the read address group of signals.
  input   [     31:0] ARADDR  ; //(I)[RdAddr]Read address. The read address gives the address of the first transfer in a read burst transaction.
  input   [      7:0] ARLEN   ; //(I)[RdAddr]Burst length. This signal indicates the exact number of transfers in a burst.
  input   [      2:0] ARSIZE  ; //(I)[RdAddr]Burst size. This signal indicates the size of each transfer in the burst.
  input   [      1:0] ARBURST ; //(I)[RdAddr]Burst type. The burst type and the size information determine how the address for each transfer within the burst is calculated.
  input   [      1:0] ARLOCK  ; //(I)[RdAddr]Lock type. This signal provides additional information about the atomic characteristics of the transfer.
  input               ARVALID ; //(I)[RdAddr]Read address valid. This signal indicates that the channel is signaling valid read address and control information.
  output              ARREADY ; //(O)[RdAddr]Read address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
  /////////////  
  output  [AIW  -1:0] RID     ; //(O)[RdData]Read ID tag. This signal is the identification tag for the read data group of signals generated by the slave.
  output  [      1:0] RRESP   ; //(O)[RdData]Read response. This signal indicates the status of the read transfer.
  output              RLAST   ; //(O)[RdData]Read last. This signal indicates the last transfer in a read burst.
  output              RVALID  ; //(O)[RdData]Read valid. This signal indicates that the channel is signaling the required read data.
  input               RREADY  ; //(I)[RdData]Read ready. This signal indicates that the master can accept the read data and response information.
  output  [ADW_C-1:0] RDATA   ; //(O)[RdData]Read data.

  /////////////////////////////////////////////////////////
  //DDR Controner AXI4 Signal Define
  output  [AIW  -1:0] aid     ; //(O)[Addres]Address ID
  output  [     31:0] aaddr   ; //(O)[Addres]Address
  output  [      7:0] alen    ; //(O)[Addres]Address Brust Length
  output  [      2:0] asize   ; //(O)[Addres]Address Burst size
  output  [      1:0] aburst  ; //(O)[Addres]Address Burst type
  output  [      1:0] alock   ; //(O)[Addres]Address Lock type
  output              avalid  ; //(O)[Addres]Address Valid
  input               aready  ; //(I)[Addres]Address Ready
  output              atype   ; //(O)[Addres]Operate Type 0=Read, 1=Write
  output  [AIW  -1:0] wid     ; //(O)[Write]Data ID
  output  [ABN_C-1:0] wstrb   ; //(O)[Write]Data Strobes(Byte valid)
  output              wlast   ; //(O)[Write]Data Last
  output              wvalid  ; //(O)[Write]Data Valid
  input               wready  ; //(I)[Write]Data Ready
  output  [ADW_C-1:0] wdata   ; //(O)[Write]Data Data
  input   [AIW  -1:0] rid     ; //(I)[Read]Data ID
  input               rlast   ; //(I)[Read]Data Last
  input               rvalid  ; //(I)[Read]Data Valid
  output              rready  ; //(O)[Read]Data Ready
  input   [      1:0] rresp   ; //(I)[Read]Response
  input   [ADW_C-1:0] rdata   ; //(I)[Read]Data Data
  input   [AIW  -1:0] bid     ; //(I)[Answer]Response Write ID
  input               bvalid  ; //(I)[Answer]Response valid
  output              bready  ; //(O)[Answer]Response Ready

//1111111111111111111111111111111111111111111111111111111
//
//  Input：
//  output：
//***************************************************/

  /////////////////////////////////////////////////////////
  reg           OpType = 1'h0;

  wire          AWREADY =  OpType & aready  ; //(O)[WrAddr]Write address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
  wire          ARREADY = ~OpType & aready  ; //(O)[RdAddr]Read address ready. This signal indicates that the slave is ready to accept an address and associated control signals.

  /////////////////////////////////////////////////////////
  reg   OperateSel = 1'h0;

  always @( posedge SysClk) if (aready)
  begin
    if      (AWVALID ^ ARVALID)   OperateSel <= # TCo_C ~DDR_WRITE_FIRST  ;
    else if (AWVALID & ARVALID)   OperateSel <= # TCo_C ~OperateSel       ;
  end

  /////////////////////////////////////////////////////////
  reg   [1:0] OprateAva = 2'h3;

  always @( posedge SysClk or negedge Reset_N )
  begin
    if ( ! Reset_N )      OprateAva <= # TCo_C  2'h3;
    else
    begin
      case (OprateAva)
        2'h0:               OprateAva <= # TCo_C  2'h3;
        2'h1: if (ARREADY)  OprateAva <= # TCo_C  {AWVALID  , 1'h0   };
        2'h2: if (AWREADY)  OprateAva <= # TCo_C  {1'h0     , ARVALID};
        2'h3:
        begin
          case ({AWVALID , ARVALID})
            2'h0:   OprateAva  <= # TCo_C 2'h3;
            2'h1:   OprateAva  <= # TCo_C 2'h1;
            2'h2:   OprateAva  <= # TCo_C 2'h2;
            2'h3:   OprateAva  <= # TCo_C OperateSel ? 2'h2 : 2'h1;
          endcase
        end
      endcase
    end
  end

  /////////////////////////////////////////////////////////
  wire  [1:0]  AddrVal = {AWVALID , ARVALID} & OprateAva;

  always @( * )
  begin
    case (AddrVal)
      2'h0:   OpType  <= # TCo_C OperateSel;
      2'h1:   OpType  <= # TCo_C 1'h0;
      2'h2:   OpType  <= # TCo_C 1'h1;
      2'h3:   OpType  <= # TCo_C OperateSel;
    endcase
  end

//1111111111111111111111111111111111111111111111111111111



//22222222222222222222222222222222222222222222222222222
//
//  Input：
//  output：
//***************************************************/

  /////////////////////////////////////////////////////////
  wire  [AIW  -1:0] aid     = OpType ? AWID     : ARID    ; //(O)[Addres]Address ID
  wire  [     31:0] aaddr   = OpType ? AWADDR   : ARADDR  ; //(O)[Addres]Address
  wire  [      7:0] alen    = OpType ? AWLEN    : ARLEN   ; //(O)[Addres]Address Brust Length
  wire  [      2:0] asize   = OpType ? AWSIZE   : ARSIZE  ; //(O)[Addres]Address Burst size
  wire  [      1:0] aburst  = OpType ? AWBURST  : ARBURST ; //(O)[Addres]Address Burst type
  wire  [      1:0] alock   = OpType ? AWLOCK   : ARLOCK  ; //(O)[Addres]Address Lock type
  wire              avalid  = OpType ? AWVALID  : ARVALID ; //(O)[Addres]Address Valid
  wire              atype   = OpType                      ; //(O)[Addres]Operate Type 0=Read, 1=Write

  /////////////////////////////////////////////////////////
  wire  [AIW  -1:0] wid     = WID     ; //(O)[Write]Data ID
  wire  [ABN_C-1:0] wstrb   = WSTRB   ; //(O)[Write]Data Strobes(Byte valid)
  wire              wlast   = WLAST   ; //(O)[Write]Data Last
  wire              wvalid  = WVALID  ; //(O)[Write]Data Valid
  wire  [ADW_C-1:0] wdata   = WDATA   ; //(O)[Write]Data Data
                                      
  wire              WREADY  = wready  ; //(O)[WrData]Write ready. This signal indicates that the slave can accept the write data.

  /////////////////////////////////////////////////////////
  wire              bready  = BREADY  ; //(O)[Answer]Response Ready
                                      
  wire  [AIW  -1:0] BID     = bid     ; //(O)[WrResp]Response ID tag. This signal is the ID tag of the write response.
  wire              BVALID  = bvalid  ; //(O)[WrResp]Write response valid. This signal indicates that the channel is signaling a valid write response.

  /////////////////////////////////////////////////////////
  wire              rready  = RREADY  ; //(O)[Read]Data Ready
                                      
  wire  [AIW -1:0]  RID     = rid     ; //(O)[RdData]Read ID tag. This signal is the identification tag for the read data group of signals generated by the slave.
  wire  [     1:0]  RRESP   = rresp   ; //(O)[RdData]Read response. This signal indicates the status of the read transfer.
  wire              RLAST   = rlast   ; //(O)[RdData]Read last. This signal indicates the last transfer in a read burst.
  wire              RVALID  = rvalid  ; //(O)[RdData]Read valid. This signal indicates that the channel is signaling the required read data.
  wire [ADW_C-1:0]  RDATA   = rdata   ; //(O)[RdData]Read data.

//22222222222222222222222222222222222222222222222222222

endmodule

/////////////////// Axi4FullDeplex ///////////////////////////









///////////////////////////////////////////////////////////
/**********************************************************
  Function Description:

  Establishment : Richard Zhu
  Create date   : 2022-09-24
  Versions      : V0.1
  Revision of records:
  Ver0.1

**********************************************************/
module  Axi_Test_Info_Fifo
(
  Sys_Clk     , //System Clock
  Sync_Clr    , //Sync Reset
  I_Wr_En     , //(I) FIFO Write Enable
  I_Wr_Data   , //(I) FIFO Write Data
  I_Rd_En     , //(I) FIFO Read Enable
  O_Rd_Data   , //(I) FIFO Read Data
  O_Data_Num  , //(I) FIFO Data Number
  O_Wr_Full   , //(O) FIFO Write Full
  O_Rd_Empty  , //(O) FIFO Write Empty
  O_Fifo_Err    //Fifo Error
);

  //Define  Parameter
  /////////////////////////////////////////////////////////
  parameter   OUT_REG       = "No"  ; //"Yes" Output Register Eanble ; "No"  Output Register Disble
  parameter   DATA_WIDTH    = 32    ; //Data Width
  parameter   DATA_DEPTH    = 8     ; //Address Width
  parameter   INITIAL_VALUE = 8'h0  ;

  localparam  ADDR_WIDTH    = $clog2(DATA_DEPTH)  ;
  localparam  SRL8_NUMBER   = (DATA_DEPTH / 8) + (((DATA_DEPTH % 8) == 0) ? 0 : 1 ) ;


  localparam  DW  = DATA_WIDTH    ;
  localparam  AW  = ADDR_WIDTH    ;
  localparam  SN  = SRL8_NUMBER   ;

  /////////////////////////////////////////////////////////

  // Signal Define
  /////////////////////////////////////////////////////////
  input             Sys_Clk     ; //System Clock
  input             Sync_Clr    ; //Sync Reset
  input             I_Wr_En     ; //(I) Write Enable
  input   [DW-1:0]  I_Wr_Data   ; //(I) Write Data
  input             I_Rd_En     ; //(I) Read Enable
  output  [DW-1:0]  O_Rd_Data   ; //(O) Read Data
  output  [AW  :0]  O_Data_Num  ; //(O) Ram Data Number
  output            O_Wr_Full   ; //(O) FIFO Write Full
  output            O_Rd_Empty  ; //(O) FIFO Write Empty
  output            O_Fifo_Err  ; //(O) FIFO Error

  /////////////////////////////////////////////////////////
//000000000000000000000000000000000000000000000000000000000
//整理输入信号
//********************************************************/
  /////////////////////////////////////////////////////////
  wire            Wr_En     = I_Wr_En     ; //Write Enable
  wire  [DW-1:0]  Wr_Data   = I_Wr_Data   ; //Write Data
  wire            Rd_En     = I_Rd_En     ; //Read Enable

  /////////////////////////////////////////////////////////

//000000000000000000000000000000000000000000000000000000000

//111111111111111111111111111111111111111111111111111111111
//
//********************************************************/
  /////////////////////////////////////////////////////////
  reg   Wr_Full     = 1'h0  ;
  reg   Rd_Empty    = 1'h1  ;

  wire  Fifo_Wr_En  = Wr_En & ( ~Wr_Full  ) ;
  wire  Fifo_Rd_En  = Rd_En & ( ~Rd_Empty ) ;

  /////////////////////////////////////////////////////////
  reg   [AW:0]  Data_Num  = {AW+1{1'h0}}  ;

  always @(posedge Sys_Clk)
  begin
    if (Sync_Clr)           Data_Num  <= {AW+1{1'h0}} ;
    else if (Fifo_Wr_En ^ Fifo_Rd_En)
    begin
      if (Fifo_Wr_En)       Data_Num  <= Data_Num + {{AW{1'h0}},1'h1} ;
      else if (Fifo_Rd_En)  Data_Num  <= Data_Num - {{AW{1'h0}},1'h1} ;
    end
  end

  /////////////////////////////////////////////////////////
  wire    [AW  :0]  Out_Sel  ;

  assign  Out_Sel = (|Data_Num)   ? ( DATA_DEPTH  - Data_Num) : {AW+1{1'h0}} ;

  /////////////////////////////////////////////////////////
  wire    [AW:0]    O_Data_Num  = Data_Num  ; //(O)Data Number In Fifo

  /////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////

//111111111111111111111111111111111111111111111111111111111

//222222222222222222222222222222222222222222222222222222222
//
//********************************************************/
  /////////////////////////////////////////////////////////
  wire  [   2:0]  Shift_Out_Sel   = Out_Sel[2:0]  ;
  wire            Shift_Clk_En    = Fifo_Wr_En    ;

  wire  [DW-1:0]  Shift_Data_In   [SN-1:0]  ;
  wire  [DW-1:0]  Shift_Data_Out  [SN-1:0]  ;
  wire  [DW-1:0]  Shift_Q7_Out    [SN  :0]  ; //(O)Shift Output

  genvar  i , j ;
  generate
    for (i=0; i<SRL8_NUMBER ; i=i+1)
    begin : U_SRL8_D
      if (i==SRL8_NUMBER-1) assign  Shift_Data_In[i]  = ~Wr_Data          ;
      else                  assign  Shift_Data_In[i]  = Shift_Q7_Out[i+1] ;

      for (j=0; j<DATA_WIDTH; j=j+1)
      begin : U_SRL8_W
        EFX_SRL8
        #(
            .CLK_POLARITY ( 1'b1            ) , // clk polarity
            .CE_POLARITY  ( 1'b1            ) , // clk polarity
            .INIT         ( INITIAL_VALUE   )   // 8-bit initial value
        )
        srl8_inst
        (
            .A      ( Shift_Out_Sel         ) ,   // 3-bit address select for Q
            .D      ( Shift_Data_In [i][j]  ) ,   // 1-bit data-in
            .CLK    ( Sys_Clk               ) ,   // clock
            .CE     ( Shift_Clk_En          ) ,   // clock enable
            .Q      ( Shift_Data_Out[i][j]  ) ,   // 1-bit data output
            .Q7     ( Shift_Q7_Out  [i][j]  )     // 1-bit last shift register output
        );
      end
    end
  endgenerate

//222222222222222222222222222222222222222222222222222222222

//333333333333333333333333333333333333333333333333333333333
//
//********************************************************/
  /////////////////////////////////////////////////////////
  reg   [DW-1:0]  Data_Out  = {DW{1'h0}}  ;
  reg   [DW-1:0]  Shift_Out = {DW{1'h0}}  ;

  always @(posedge  Sys_Clk )
  begin
    if (Sync_Clr)               Data_Out  <=  {DW{1'h0}}  ;
    else if (SRL8_NUMBER == 1)  Data_Out  <=  Shift_Data_Out[0][DW-1:0]  ;
    else
    begin
      if (Out_Sel != 0 )        Data_Out  <=  Shift_Data_Out[Out_Sel[AW-1:3]][DW-1:0]  ;
      else if (Shift_Clk_En)    Data_Out  <=  Wr_Data     ;
      else                      Data_Out  <=  Shift_Data_Out[Out_Sel[AW-1:3]][DW-1:0]  ;
    end
  end

  /////////////////////////////////////////////////////////
  reg  [DW-1:0]  Rd_Data   ;

  always @ ( * )
  begin
    if (OUT_REG == "Yes")           Rd_Data = Data_Out  ;
    else if ( (SRL8_NUMBER <= 1) )  Rd_Data = Shift_Data_Out[              0][DW-1:0] ;
    else                            Rd_Data = Shift_Data_Out[Out_Sel[AW:3]][DW-1:0] ;
  end

  /////////////////////////////////////////////////////////
  wire  [DW-1:0]  O_Rd_Data   = Rd_Data ; //(O) Read Data

  /////////////////////////////////////////////////////////
//333333333333333333333333333333333333333333333333333333333

//444444444444444444444444444444444444444444444444444444444
//
//********************************************************/
  /////////////////////////////////////////////////////////
  localparam  [AW:0]  FULL_ENTER      = DATA_DEPTH  - {{AW{1'h0}},1'h1} ;
  localparam  [AW:0]  EMPTY_ENTER     = {{AW{1'h0}} , 1'h1  }  ;

  /////////////////////////////////////////////////////////
  always @(posedge Sys_Clk)
  begin
    if (Sync_Clr)           Wr_Full   <=  1'h0 ;
    else if (Fifo_Rd_En)    Wr_Full   <=  1'h0 ;
    else if (Fifo_Wr_En)    Wr_Full   <=  (Data_Num == FULL_ENTER)  ;
  end

  /////////////////////////////////////////////////////////
  always @(posedge Sys_Clk)
  begin
    if (Sync_Clr)           Rd_Empty  <=  1'h1 ;
    else if (Fifo_Wr_En)    Rd_Empty  <=  1'h0 ;
    else if (Fifo_Rd_En)    Rd_Empty  <=  (Data_Num == EMPTY_ENTER) ;
  end

  /////////////////////////////////////////////////////////
  reg   Fifo_Err  = 1'h0 ;

  always @(posedge Sys_Clk)   Fifo_Err  <=  (Rd_En & Rd_Empty) | (Wr_En & Wr_Full) ;

  /////////////////////////////////////////////////////////
  assign    O_Wr_Full   = Wr_Full   ; //(O) FIFO Write Full
  assign    O_Rd_Empty  = Rd_Empty  ; //(O) FIFO Write Empty
  assign    O_Fifo_Err  = Fifo_Err  ; //(O) Fifo Error

  /////////////////////////////////////////////////////////
//444444444444444444444444444444444444444444444444444444444

endmodule

///////////////////////////////////////////////////////////






