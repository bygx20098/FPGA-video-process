
`timescale 100ps/10ps

////////////////// DdrTest /////////////////////////////
/**********************************************************
  Function Description: 

  Establishment : Richard Zhu 
  Create date   : 2020-01-09 
  Versions      : V0.1 
  Revision of records: 
  Ver0.1
  
**********************************************************/
`include "ddr3_controller.vh"

module DdrTest
# (
  parameter   AXI_DATA_WIDTH    = 128             ,
  parameter   AXI_ID_WIDTH    =   8               ,
	parameter   DDR_START_ADDRESS = 32'h00_00_10_00 ,  //DDR Memory Start Address
	parameter   DDR_END_ADDRESS   = 32'h0f_ff_ff_ff ,  //DDR Memory End Address
  parameter   DDR_WRITE_FIRST   = 1'h0            ,   //1:Write First ; 0: Read First
  parameter   RIGHT_CNT_WIDTH   = 27              ,      
	parameter   AXI_WR_ID         = 8'haa           ,
	parameter   AXI_RD_ID         = 8'h55           ,
  parameter   AIW               = AXI_ID_WIDTH    ,
  parameter   ADW               = AXI_DATA_WIDTH  ,
  parameter   ABN               = (AXI_DATA_WIDTH/8)    
  )
( 
  //System Signal
  input               SysClk        , //(O)System Clock
  input               Reset_N       , //(I)System Reset (Low Active)
  //Test Configuration & State  
  input   [    1:0]   CfgTestMode   , //(I)Test Mode: 1:Read Only;2:Write Only;3:Write/Read alternate
  input   [    7:0]   CfgBurstLen   , //(I)Config Burst Length;
  input   [    2:0]   CfgDataSize   , //(I)Config Data Size
  input   [   31:0]   CfgStartAddr  , //(I)Config Start Address
  input   [   31:0]   CfgFirstAddr  , //(I)Config First Address
  input   [   31:0]   CfgEndAddr    , //(I)Config End Address
  input   [   31:0]   CfgTestLen    , //(I)Config Test Length
  input   [    1:0]   CfgDataMode   , //Config Test Data Mode 0: Nomarl 1:Reverse
  input               TestStart     , //(I)Test Start Control
  //Test State  & Result        
  output              TestBusy      , //(O)Test Busy State  
  output              TestErr       , //(O)Test Data Error
  output              TestRight     , //(O)Test Data Right
  //AXI4 Operate                      
  output              AxiWrEn       , //Axi4 Write Enable
  output  [   31:0]   AxiWrStartA   , //Axi4 Write Start Address
  output  [   31:0]   AxiWrAddr     , //Axi4 Write Address
  output  [ABN-1:0]   AxiWrMask     , //Axi4 Write Mask
  output  [ADW-1:0]   AxiWrData     , //Axi4 Write Data
  output              AxiWrDMode    , //Axi4 Write DDR End
  output              AxiRdAva      , //Axi4 Read Available
  output  [   31:0]   AxiRdStartA   , //Axi4 Read Start Address
  output  [   31:0]   AxiRdAddr     , //Axi4 Read Address
  output  [ADW-1:0]   AxiRdData     , //Axi4 Read Data
  output              AxiRdDMode    , //Axi4 Read DDR End  
  //Axi Interfac Signal
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
`ifdef  AXI_FULL_DEPLEX
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
  output  [AIW-1:0]   AWID        , //(O)[WrAddr]Write address ID. This signal is the identification tag for the write address group of signals.
  output  [   31:0]   AWADDR      , //(O)[WrAddr]Write address. The write address gives the address of the first transfer in a write burst transaction.
  output  [    7:0]   AWLEN       , //(O)[WrAddr]Burst length. The burst length gives the exact number of transfers in a burst. This information determines the number of data transfers associated with the address.
  output  [    2:0]   AWSIZE      , //(O)[WrAddr]Burst size. This signal indicates the size of each transfer in the burst.
  output  [    1:0]   AWBURST     , //(O)[WrAddr]Burst type. The burst type and the size information, determine how the address for each transfer within the burst is calculated.
  output  [    1:0]   AWLOCK      , //(O)[WrAddr]Lock type. Provides additional information about the atomic characteristics of the transfer.
  output              AWVALID     , //(O)[WrAddr]Write address valid. This signal indicates that the channel is signaling valid write address and control information.
  input               AWREADY     , //(I)[WrAddr]Write address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
  /////////////              
  output  [AIW-1:0]   ARID        , //(O)[RdAddr]Read address ID. This signal is the identification tag for the read address group of signals.
  output  [   31:0]   ARADDR      , //(O)[RdAddr]Read address. The read address gives the address of the first transfer in a read burst transaction.
  output  [    7:0]   ARLEN       , //(O)[RdAddr]Burst length. This signal indicates the exact number of transfers in a burst.
  output  [    2:0]   ARSIZE      , //(O)[RdAddr]Burst size. This signal indicates the size of each transfer in the burst.
  output  [    1:0]   ARBURST     , //(O)[RdAddr]Burst type. The burst type and the size information determine how the address for each transfer within the burst is calculated.
  output  [    1:0]   ARLOCK      , //(O)[RdAddr]Lock type. This signal provides additional information about the atomic characteristics of the transfer.
  output              ARVALID     , //(O)[RdAddr]Read address valid. This signal indicates that the channel is signaling valid read address and control information.
  input               ARREADY     , //(I)[RdAddr]Read address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
  /////////////              
  output  [AIW-1:0]   WID         , //(O)[WrData]Write ID tag. This signal is the ID tag of the write data transfer.
  output  [ABN-1:0]   WSTRB       , //(O)[WrData]Write strobes. This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight bits of the write data bus.
  output              WLAST       , //(O)[WrData]Write last. This signal indicates the last transfer in a write burst.
  output              WVALID      , //(O)[WrData]Write valid. This signal indicates that valid write data and strobes are available.
  input               WREADY      , //(O)[WrData]Write ready. This signal indicates that the slave can accept the write data.
  output  [ADW-1:0]   WDATA       , //(I)[WrData]Write data.
  /////////////                 
  input   [AIW-1:0]   BID         , //(I)[WrResp]Response ID tag. This signal is the ID tag of the write response.
  input               BVALID      , //(I)[WrResp]Write response valid. This signal indicates that the channel is signaling a valid write response.
  output              BREADY      , //(O)[WrResp]Response ready. This signal indicates that the master can accept a write response.
  /////////////                 
  input   [AIW-1:0]   RID         , //(I)[RdData]Read ID tag. This signal is the identification tag for the read data group of signals generated by the slave.
  input   [    1:0]   RRESP       , //(I)[RdData]Read response. This signal indicates the status of the read transfer.
  input               RLAST       , //(I)[RdData]Read last. This signal indicates the last transfer in a read burst.
  input               RVALID      , //(I)[RdData]Read valid. This signal indicates that the channel is signaling the required read data.
  output              RREADY      , //(O)[RdData]Read ready. This signal indicates that the master can accept the read data and response information.
  input   [ADW-1:0]   RDATA         //(I)[RdData]Read data.
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
`else
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
  output  [AIW-1:0]   aid         , //(O)[Addres] Address ID
  output  [   31:0]   aaddr       , //(O)[Addres] Address
  output  [    7:0]   alen        , //(O)[Addres] Address Brust Length
  output  [    2:0]   asize       , //(O)[Addres] Address Burst size
  output  [    1:0]   aburst      , //(O)[Addres] Address Burst type
  output  [    1:0]   alock       , //(O)[Addres] Address Lock type
  output              avalid      , //(O)[Addres] Address Valid
  input               aready      , //(I)[Addres] Address Ready
  output              atype       , //(O)[Addres] Operate Type 0=Read, 1=Write
  /////////////                 
  output  [AIW-1:0]   wid         , //(O)[Write]  ID
  output              wvalid      , //(O)[Write]  Data Valid
  input               wready      , //(I)[Write]  Data Ready
  output  [ADW-1:0]   wdata       , //(O)[Write]  Data
  output  [ABN-1:0]   wstrb       , //(O)[Write]  Data Strobes(Byte valid)
  output              wlast       , //(O)[Write]  Data Last
  /////////////               
  input               rvalid      , //(I)[Read]   Data Valid
  output              rready      , //(O)[Read]   Data Ready
  input   [ADW-1:0]   rdata       , //(I)[Read]   Data
  input   [AIW-1:0]   rid         , //(I)[Read]   ID
  input   [    1:0]   rresp       , //(I)[Read]   Response
  input               rlast       , //(I)[Read]   Data Last
  /////////////                   
  output              bready      , //(O)[Answer] Response Ready
  input   [AIW-1:0]   bid         , //(I)[Answer] Response Write ID
  input               bvalid        //(I)[Answer] Response valid
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
`endif 
//&&&&&&&&&&&&&&&&&&&&&&&&&&&

);

 	//Define  Parameter
	/////////////////////////////////////////////////////////
	parameter		TCo_C   		= 1;    
		
  localparam  AXI_BYTE_NUMBER   = AXI_DATA_WIDTH/8        ;
  localparam  AXI_DATA_SIZE     = $clog2(AXI_BYTE_NUMBER) ;   
  localparam  ADS_C             = AXI_DATA_SIZE           ;
  
  localparam  [7:0] AXI_MAX_BURST     = (4096 / AXI_BYTE_NUMBER) - 1;
  
	/////////////////////////////////////////////////////////

  
//1111111111111111111111111111111111111111111111111111111
//	Process Configuration 
//	Input：
//	output：
//***************************************************/ 
  
  /////////////////////////////////////////////////////////
  reg   [1:0] TestStartReg  = 2'h0; 
  reg         TestConfInEn  = 1'h0;   //Test Config Input Enable
  reg         TestStartEn   = 1'h0;   //Test Start Enable
  reg         TestStopEn    = 1'h0;
  
  always @( posedge SysClk)  TestStartReg <= # TCo_C {TestStartReg[0] , TestStart};  
  always @( posedge SysClk)  TestConfInEn <= # TCo_C (TestStartReg == 2'h1) & (~TestBusy)
                                                    & (|CfgTestMode);     
  always @( posedge SysClk)  TestStartEn  <= # TCo_C TestConfInEn;  
  always @( posedge SysClk)  TestStopEn   <= # TCo_C (TestStartReg == 2'h2);     
                                                    
  /////////////////////////////////////////////////////////
  reg   [31:0]  CalcStartAddr   = 32'h0; //Calculate Start Address for DDR Test
  reg   [31:0]  CalcFirstAddr   = 32'h0; //Calculate First Address for DDR Test
  reg   [31:0]  CalcEndAddr     = 32'h0; //Calculate End Address for DDR Test        
  reg   [ 7:0]  CalcBurstLen    =  8'h8; //Calculate Burst Length for Axi4 Bus
  
  always @( posedge SysClk)  CalcStartAddr  <= # TCo_C (CfgStartAddr  > DDR_START_ADDRESS ) ?
                                                        CfgStartAddr  : DDR_START_ADDRESS   ;
   
  always @( posedge SysClk)  CalcFirstAddr  <= # TCo_C (CfgFirstAddr  > DDR_START_ADDRESS ) ?
                                                        CfgFirstAddr  : DDR_START_ADDRESS   ;
                                                                                                             
  always @( posedge SysClk)  CalcEndAddr    <= # TCo_C (CfgEndAddr    < DDR_END_ADDRESS   ) ?
                                                        CfgEndAddr    : DDR_END_ADDRESS     ;
                                                        
  always @( posedge SysClk)  CalcBurstLen   <= # TCo_C (CfgBurstLen   < AXI_MAX_BURST     ) ?
                                                        CfgBurstLen   : AXI_MAX_BURST       ;
                                                        
  /////////////////////////////////////////////////////////
                                     
  reg   [ 1:0]  TestMode      =  2'h0             ;  //Test Mode: 1:Read Only;2:Write Only;2/3:Write/Read alternate
  reg   [ 7:0]  BurstLen      =  8'h0             ;  
  reg   [31:0]  StartAddr     = DDR_START_ADDRESS ; 
  reg   [31:0]  FirstAddr     = DDR_START_ADDRESS ; 
  reg   [31:0]  EndAddr       = DDR_END_ADDRESS   ; 
  reg   [31:0]  TestLen       = 32'h0             ;
                                                  
  reg   [12:0]  TestBurstLen  = 13'h0             ;
  
  always @( posedge SysClk)   if (TestConfInEn)
  begin
    TestMode      <= # TCo_C    CfgTestMode   ;
    BurstLen      <= # TCo_C    CalcBurstLen  ;
    TestLen       <= # TCo_C    (|CfgTestLen) ? CfgTestLen :  {32{1'h1}};
    
    StartAddr     <= # TCo_C  { CalcStartAddr[31:8]  , 8'h 0  } ;
    FirstAddr     <= # TCo_C  { CalcFirstAddr[31:0]           } ;
    EndAddr       <= # TCo_C  { CalcEndAddr  [31:8]  , 8'hff  } ;
    TestBurstLen  <= # TCo_C  (CalcBurstLen + 8'h1) << CfgDataSize  ; //AXI_DATA_SIZE;
  end
  
//1111111111111111111111111111111111111111111111111111111


//2222222222222222222222222222222222222222222222222222222
//	Write Address
//	Input：
//	output：
//***************************************************/ 
  
  /////////////////////////////////////////////////////////
  reg         WrBurstEn   = 1'h0 ;
  reg [31:0]  WrBurstCnt  = 32'h0;
  
  always @( posedge SysClk or negedge Reset_N)  
  begin
    if (~Reset_N)           WrBurstCnt <= # TCo_C 32'h0       ;  
    else if (TestStopEn)    WrBurstCnt <= # TCo_C 32'h0       ;
    else if (TestStartEn)   WrBurstCnt <= # TCo_C TestLen     ;
    // else if (&WrBurstCnt)   WrBurstCnt <= # TCo_C {32{1'h1}}  ;
    else if (WrBurstEn )    WrBurstCnt <= # TCo_C WrBurstCnt  - {31'h0,{|WrBurstCnt}};
  end
  
  /////////////////////////////////////////////////////////
  wire  RamWrEnd      ; //(O)[DdrWrCtrl]Ram Operate End
  reg   WrBusyFlag    = 1'h0  ;
  
  always @( posedge SysClk or negedge Reset_N) 
  begin
    if (~Reset_N)         WrBusyFlag <= # TCo_C  1'h0;
    else if (WrBusyFlag)
    begin
      // if (TestStopEn)     WrBusyFlag <= # TCo_C  1'h0;
      // else if (&TestLen)  WrBusyFlag <= # TCo_C  1'h1;
      if (&TestLen)       WrBusyFlag <= # TCo_C  1'h1;
      else                WrBusyFlag <= # TCo_C  (|WrBurstCnt);
    end
    else if (TestStartEn) WrBusyFlag <= # TCo_C  CfgTestMode[1];
  end

  /////////////////////////////////////////////////////////
  wire        Axi_Back_Ask  ;
  reg         TestWrBusy    = 1'h0 ;
  reg   [1:0] TestWrOpCnt   = 2'h0 ;

  always @( posedge SysClk or negedge Reset_N) 
  begin
    if (~Reset_N)             TestWrOpCnt   <= # TCo_C  2'h0;
    else if (TestStartEn)     TestWrOpCnt   <= # TCo_C  2'h0;
    else if (WrBurstEn  ^ Axi_Back_Ask)
    begin
      if (WrBurstEn)          TestWrOpCnt   <= # TCo_C  TestWrOpCnt + {1'h0 , (~&TestWrOpCnt  ) } ;
      else if (Axi_Back_Ask)  TestWrOpCnt   <= # TCo_C  TestWrOpCnt - {1'h0 , ( |TestWrOpCnt  ) } ;
    end
  end
  always @( posedge SysClk or negedge Reset_N) 
  begin
    if (~Reset_N)           TestWrBusy <= # TCo_C  1'h0;
    else if (TestStartEn)   TestWrBusy <= # TCo_C  CfgTestMode[1];
    else if (Axi_Back_Ask)  TestWrBusy <= # TCo_C  WrBusyFlag  | (|TestWrOpCnt[1]) ;
  end
  
  /////////////////////////////////////////////////////////
  reg [31:0]  NextWrAddrCnt   = 32'h0;
  reg         TestDdrWrEnd    =  1'h0;
  reg         WrAxiCross4K    =  1'h0;

  always @( posedge SysClk)  
  begin
    if (TestStartEn)          NextWrAddrCnt   <= # TCo_C FirstAddr      + {18'h0,TestBurstLen };
    else if (~TestStart)      NextWrAddrCnt   <= # TCo_C 32'h0 ;
    else if (WrBurstEn)  
    begin
      if (TestDdrWrEnd)       NextWrAddrCnt   <= # TCo_C StartAddr      + {18'h0,TestBurstLen };
      else if (WrAxiCross4K)  NextWrAddrCnt   <= # TCo_C {(NextWrAddrCnt[31:12] + 20'h1),12'h0};
      else                    NextWrAddrCnt   <= # TCo_C NextWrAddrCnt  + {18'h0,TestBurstLen };
    end
  end

  /////////////////////////////////////////////////////////
  wire  [32:0]  WrAddrEndDiff   = {1'h0,EndAddr} - {1'h0,NextWrAddrCnt};  
  wire  [12:0]  WrAddr4KDiff    = 13'h1000 - {1'h0 , NextWrAddrCnt[11:0]} ; 
  
  always @( posedge SysClk)  TestDdrWrEnd   <= # TCo_C ( WrAddrEndDiff < {1'h0,TestBurstLen} );
  always @( posedge SysClk)  WrAxiCross4K   <= # TCo_C ( WrAddr4KDiff  < {1'h0,TestBurstLen} ); 
  
  ///////////////////////////////////////////////////////// 
  reg   [7:0]  WrBurstLen       = 8'h0;
  
  wire  [7:0]  WrAddrRemainder  = (WrAddr4KDiff[11:0] - 12'h1) >> AXI_DATA_SIZE;
  
  always @( posedge SysClk)  
  begin    
    if (TestStartEn)          WrBurstLen <= # TCo_C BurstLen; 
    else if (WrBurstEn)
    begin
      if (TestDdrWrEnd)       WrBurstLen <= # TCo_C BurstLen;   
      else if (WrAxiCross4K)  WrBurstLen <= # TCo_C WrAddrRemainder;
      else                    WrBurstLen <= # TCo_C BurstLen;
    end
  end
  
  ///////////////////////////////////////////////////////// 
  reg [31:0]  TestWrStartAddr = 32'h0;   
  
  always @( posedge SysClk)  
  begin
    if (TestStartEn)      TestWrStartAddr <= # TCo_C FirstAddr ;
    else if (WrBurstEn)   TestWrStartAddr <= # TCo_C TestDdrWrEnd ? StartAddr : NextWrAddrCnt;
  end
  
  ///////////////////////////////////////////////////////// 
  //Operate Control & State
  wire   RamWrStart = WrBurstEn ; //(I)[DdrWrCtrl]Ram Operate Start
  
  wire  [ABN-1:0]   RamWrMask   ; //(I)[DdrWrCtrl]Ram Write Mask
  wire  [ADW-1:0]   RamWrData   ; //(I)[DdrWrCtrl]Ram Write Data
  wire  [   31:0]   RamWrAddr   ; //(O)[DdrWrCtrl]Ram Write Address
  wire              RamWrNext   ; //(O)[DdrWrCtrl]Ram Write Next
  wire              RamWrBusy   ; //(O)[DdrWrCtrl]Ram Write Busy
  wire              RamWrALoad  ; //(O)Ram Write Address Load

  //////////////////////////
  //Config DDR Operate Parameter
  wire  [31:0]    CfgWrAddr   = TestWrStartAddr ; //(I)[DdrWrCtrl]Config Write Start Address
  wire  [ 7:0]    CfgWrBLen   = WrBurstLen      ; //(I)[DdrWrCtrl]Config Write Burst Length
  wire  [ 2:0]    CfgWrSize   = CfgDataSize     ; //(I)Config Write Size

  ////////////////////////
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
`ifndef   AXI_FULL_DEPLEX
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
  wire  [AIW-1:0]   AWID    ; //(O)[WrAddr]Write address ID. This signal is the identification tag for the write address group of signals.
  wire  [   31:0]   AWADDR  ; //(O)[WrAddr]Write address. The write address gives the address of the first transfer in a write burst transaction.
  wire  [    7:0]   AWLEN   ; //(O)[WrAddr]Burst length. The burst length gives the exact number of transfers in a burst. This information determines the number of data transfers associated with the address.
  wire  [    2:0]   AWSIZE  ; //(O)[WrAddr]Burst size. This signal indicates the size of each transfer in the burst.
  wire  [    1:0]   AWBURST ; //(O)[WrAddr]Burst type. The burst type and the size information, determine how the address for each transfer within the burst is calculated.
  wire  [    1:0]   AWLOCK  ; //(O)[WrAddr]Lock type. Provides additional information about the atomic characteristics of the transfer.
  wire              AWVALID ; //(O)[WrAddr]Write address valid. This signal indicates that the channel is signaling valid write address and control information.
  wire              AWREADY ; //(I)[WrAddr]Write address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
  /////////////  
  wire  [AIW-1:0]   WID     ; //(O)[WrData]Write ID tag. This signal is the ID tag of the write data transfer.
  wire  [ABN-1:0]   WSTRB   ; //(O)[WrData]Write strobes. This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight bits of the write data bus.
  wire              WLAST   ; //(O)[WrData]Write last. This signal indicates the last transfer in a write burst.
  wire              WVALID  ; //(O)[WrData]Write valid. This signal indicates that valid write data and strobes are available.
  wire              WREADY  ; //(O)[WrData]Write ready. This signal indicates that the slave can accept the write data.
  wire  [ADW-1:0]   WDATA   ; //(I)[WrData]Write data.
  /////////////
  wire  [AIW-1:0]  BID     ; //(I)[WrResp]Response ID tag. This signal is the ID tag of the write response.
  wire              BVALID  ; //(I)[WrResp]Write response valid. This signal indicates that the channel is signaling a valid write response.
  wire              BREADY  ; //(O)[WrResp]Response ready. This signal indicates that the master can accept a write response.
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
`endif 
//&&&&&&&&&&&&&&&&&&&&&&&&&&&

  DdrWrCtrl
  # (
      .AXI_ID_WIDTH   ( AXI_ID_WIDTH    ) ,
      .AXI_WR_ID      ( AXI_WR_ID       ) ,
      .AXI_DATA_WIDTH ( AXI_DATA_WIDTH  )
    )
  U1_DdrWrCtrl
  (
    //System Signal
    .SysClk     ( SysClk      ) , //System Clock
    .Reset_N    ( Reset_N     ) , //System Reset
    //config AXI&DDR Operate Parameter
    .CfgWrAddr  ( CfgWrAddr   ) , //(I)Config Write Start Address
    .CfgWrBLen  ( CfgWrBLen   ) , //(I)Config Write Burst Length
    .CfgWrSize  ( CfgWrSize   ) , //(I)Config Write Size
    //Operate Control & State   
    .RamWrStart ( RamWrStart  ) , //(I)Ram Operate Start
    .RamWrEnd   ( RamWrEnd    ) , //(O)Ram Operate End
    .RamWrAddr  ( RamWrAddr   ) , //(O)Ram Write Address
    .RamWrNext  ( RamWrNext   ) , //(O)[DdrWrCtrl]Ram Write Next
    .RamWrMask  ( RamWrMask   ) , //(I)[DdrWrCtrl]Ram Write Mask
    .RamWrData  ( RamWrData   ) , //(I)[DdrWrCtrl]Ram Write Data
    .RamWrBusy  ( RamWrBusy   ) , //(O)Ram Write Busy
    .RamWrALoad ( RamWrALoad  ) , //(O)Ram Write Address Load
    //Axi Slave Interfac Signal 
    .AWID       ( AWID        ) , //(O)[WrAddr]Write address ID.
    .AWADDR     ( AWADDR      ) , //(O)[WrAddr]Write address.
    .AWLEN      ( AWLEN       ) , //(O)[WrAddr]Burst length.
    .AWSIZE     ( AWSIZE      ) , //(O)[WrAddr]Burst size.
    .AWBURST    ( AWBURST     ) , //(O)[WrAddr]Burst type.
    .AWLOCK     ( AWLOCK      ) , //(O)[WrAddr]Lock type.
    .AWVALID    ( AWVALID     ) , //(O)[WrAddr]Write address valid.
    .AWREADY    ( AWREADY     ) , //(I)[WrAddr]Write address ready.
    /////////////               
    .WID        ( WID         ) , //(O)[WrData]Write ID tag.
    .WDATA      ( WDATA       ) , //(O)[WrData]Write data.
    .WSTRB      ( WSTRB       ) , //(O)[WrData]Write strobes.
    .WLAST      ( WLAST       ) , //(O)[WrData]Write last.
    .WVALID     ( WVALID      ) , //(O)[WrData]Write valid.
    .WREADY     ( WREADY      ) , //(I)[WrData]Write ready.
    /////////////               
    .BID        ( BID         ) , //(I)[WrResp]Response ID tag.
    .BVALID     ( BVALID      ) , //(I)[WrResp]Write response valid.
    .BREADY     ( BREADY      )   //(O)[WrResp]Response ready.
  );
  
  assign  Axi_Back_Ask  =  BVALID & BREADY ;

  /////////////////////////////////////////////////////////  
  reg   [1:0] WrDdrReturn   = 2'h0 ;
  reg         WrDataMode    = 1'h0 ;
  
  always @( posedge SysClk)  if (RamWrALoad)  
  begin
    WrDdrReturn[1] <=  WrDdrReturn[0];
    WrDdrReturn[0] <= (TestDdrWrEnd & (&CfgTestMode) & (&CfgDataMode));
  end
  
  wire  WrDdrReturnEn = WrDdrReturn[1] & RamWrALoad;
  
  always @( posedge SysClk)  
  begin
    if (TestConfInEn)         WrDataMode  <= # TCo_C (&CfgDataMode);
    else if (WrDdrReturnEn)   WrDataMode  <= # TCo_C (~WrDataMode) ;
  end
  
  /////////////////////////////////////////////////////////  
  wire              WrMaskEn    = ( CfgDataMode == 2'h2 ) ; //(I)[DdrWrDataGen]Write Mask Enable
  wire  [ABN-1:0]   DdrWrMask   ; //(I)[DdrWrDataGen]DDR Write Mask
  wire  [ADW-1:0]   RamWrDOut   ;
  
	DdrWrDataGen  #(.AXI_DATA_WIDTH ( AXI_DATA_WIDTH ))
	U1_DdrWrDataGen
  (   
  	.SysClk     ( SysClk      ) , //System Clock
  	.WrStartEn  ( RamWrALoad  ) , //(I)[DdrWrDataGen]Write Start Enale
  	.WrAddrIn   ( RamWrAddr   ) , //(I)[DdrWrDataGen]Write Address Input 
  	.WriteEn    ( RamWrNext   ) , //(I)[DdrWrDataGen]Write Enable
    .WrMaskEn   ( WrMaskEn    ) , //(I)[DdrWrDataGen]Write Mask Enable
    .DdrWrMask  ( DdrWrMask   ) , //(I)[DdrWrDataGen]DDR Write Mask
  	.DdrWrData  ( RamWrDOut   )   //(O)[DdrWrDataGen]DDR Write Data
  );
  
  assign RamWrMask = DdrWrMask  ;
  assign RamWrData = RamWrDOut  ;
  // assign RamWrData = WrDataMode ? (~RamWrDOut) : RamWrDOut;
  
  /////////////////////////////////////////////////////////
  //AXI4 Operate 
  reg               RamWrNextReg  =  1'h0 ; //Axi4 Write Enable
  reg   [   31:0]   RamWrAddrReg  = 32'h0 ; //Axi4 Write Address
  reg   [ADW-1:0]   RamWrDataReg  = 32'h0 ; //Axi4 Write Data        
  reg   [   31:0]   WrStartAReg   = 32'h0 ;                   
  
  always @( posedge SysClk)                 RamWrNextReg <= # TCo_C  RamWrNext       ; //Axi4 Write Enable   
  always @( posedge SysClk) if(RamWrNext)   RamWrAddrReg <= # TCo_C  RamWrAddr       ; //Axi4 Write Address
  always @( posedge SysClk) if(RamWrNext)   RamWrDataReg <= # TCo_C  RamWrData       ; //Axi4 Write Data
  
  always @( posedge SysClk) if(RamWrALoad)  WrStartAReg  <= # TCo_C  TestWrStartAddr ; //Axi4 Write Start Address
  
  /////////////////////////////////////////////////////////
  assign  AxiWrEn     = RamWrNextReg  ; //Axi4 Write Enable
  assign  AxiWrAddr   = RamWrAddrReg  ; //Axi4 Write Address
  assign  AxiWrMask   = DdrWrMask     ; //Axi4 Write Mask
  assign  AxiWrData   = RamWrDataReg  ; //Axi4 Write Data
  assign  AxiWrStartA = WrStartAReg   ; //Axi4 Write Start Address
  
  assign  AxiWrDMode  = WrDataMode    ; //Axi4 Write DDR End
  
//2222222222222222222222222222222222222222222222222222222


//3333333333333333333333333333333333333333333333333333333
//	
//	Input：
//	output：
//***************************************************/ 
  

  /////////////////////////////////////////////////////////
  reg         RdBurstEn   = 1'h0 ;
  reg [31:0]  RdBurstCnt  = 32'h0;
  
  always @( posedge SysClk or negedge Reset_N)  
  begin
    if (~Reset_N)           RdBurstCnt <= # TCo_C 32'h0       ;  
    else if (TestStopEn)    RdBurstCnt <= # TCo_C 32'h0       ;
    else if (TestStartEn)   RdBurstCnt <= # TCo_C TestLen     ;
    else if (RdBurstEn )    RdBurstCnt <= # TCo_C RdBurstCnt  - {31'h0,{|RdBurstCnt}};
  end
  
  /////////////////////////////////////////////////////////
  wire  RamRdEnd      ; //(O)[DdrRdCtrl]Ram Operate End
  reg   RdBusyFlag    = 1'h0  ;
  
  always @( posedge SysClk or negedge Reset_N) 
  begin
    if (~Reset_N)         RdBusyFlag <= # TCo_C  1'h0;
    else if (RdBusyFlag)
    begin
      // if (TestStopEn)     RdBusyFlag <= # TCo_C  1'h0;
      // else if (&TestLen)  RdBusyFlag <= # TCo_C  1'h1;
      if (&TestLen)       RdBusyFlag <= # TCo_C  1'h1;
      else                RdBusyFlag <= # TCo_C  (|RdBurstCnt);
    end
    else if (TestStartEn) RdBusyFlag <= # TCo_C CfgTestMode[0];
  end

  /////////////////////////////////////////////////////////
  reg         TestRdBusy    = 1'h0  ;
  reg   [3:0] TestRdOpCnt   = 4'h0 ;

  always @( posedge SysClk or negedge Reset_N) 
  begin
    if (~Reset_N)             TestRdOpCnt   <= # TCo_C  4'h0;
    else if (TestStartEn)     TestRdOpCnt   <= # TCo_C  4'h0;
    else if (RdBurstEn  ^ RamRdEnd)
    begin
      if (RdBurstEn)          TestRdOpCnt   <= # TCo_C  TestRdOpCnt + {3'h0 , (~&TestRdOpCnt  ) } ;
      else if (RamRdEnd)      TestRdOpCnt   <= # TCo_C  TestRdOpCnt - {3'h0 , ( |TestRdOpCnt  ) } ;
    end
  end  
  always @( posedge SysClk or negedge Reset_N) 
  begin
    if (~Reset_N)           TestRdBusy <= # TCo_C  1'h0;
    else if (TestStartEn)   TestRdBusy <= # TCo_C  ~CfgTestMode[1];
    else if (RamRdEnd)      TestRdBusy <= # TCo_C  RdBusyFlag | (|TestRdOpCnt[3:1]) ;
    // else if (RamRdEnd)      TestRdBusy <= # TCo_C  RdBusyFlag | (|TestRdOpCnt[3:1]) ;
    // else if (RamRdEnd)      TestRdBusy <= # TCo_C  RdBusyFlag | (|TestRdOpCnt[2:1]) ;
    // else if (RamRdEnd)      TestRdBusy <= # TCo_C  RdBusyFlag | (&TestRdOpCnt[2:1]) ;
  end

  /////////////////////////////////////////////////////////
  reg [31:0]  NextRdAddrCnt   = 32'h0;
  reg         TestDdrRdEnd    =  1'h0;
  reg         RdAxiCross4K    =  1'h0;

  always @( posedge SysClk) 
  begin
    if (TestStartEn)          NextRdAddrCnt   <= # TCo_C FirstAddr      + {18'h0,TestBurstLen};
    else if (~TestStart)      NextRdAddrCnt   <= # TCo_C 32'h0 ;
    else if (RdBurstEn)  
    begin
      if (TestDdrRdEnd)       NextRdAddrCnt   <= # TCo_C StartAddr      + {18'h0,TestBurstLen};
      else if (RdAxiCross4K)  NextRdAddrCnt   <= # TCo_C {(NextRdAddrCnt[31:12] + 20'h1),12'h0};
      else                    NextRdAddrCnt   <= # TCo_C NextRdAddrCnt  + {18'h0,TestBurstLen};
    end
  end

  /////////////////////////////////////////////////////////
  wire  [32:0]  RdAddrEndDiff   = {1'h0,EndAddr} - {1'h0,NextRdAddrCnt};  
  wire  [12:0]  RdAddr4KDiff    = 13'h1000 - {1'h0 , NextRdAddrCnt[11:0]} ; 
  
  always @( posedge SysClk)  TestDdrRdEnd   <= # TCo_C (RdAddrEndDiff < {1'h0,TestBurstLen} );
  always @( posedge SysClk)  RdAxiCross4K   <= # TCo_C (RdAddr4KDiff  < {1'h0,TestBurstLen} ); 
  
  ///////////////////////////////////////////////////////// 
  reg  [7:0]  RdBurstLen    = 8'h0;
    
  wire  [7:0]  RdAddrRemainder  = (RdAddr4KDiff[11:0] - 12'h1) >> AXI_DATA_SIZE;

  always @( posedge SysClk) 
  begin
    if (TestStartEn)          RdBurstLen <= # TCo_C BurstLen; 
    else  if (RdBurstEn)
    begin
      if (TestDdrRdEnd)       RdBurstLen <= # TCo_C BurstLen; 
      else if (RdAxiCross4K)  RdBurstLen <= # TCo_C RdAddrRemainder;
      else                    RdBurstLen <= # TCo_C BurstLen;
    end
  end
  
  ///////////////////////////////////////////////////////// 
  reg [31:0]  TestRdStartAddr = 32'h0;   
  
  always @( posedge SysClk)  
  begin
    if (TestStartEn)        TestRdStartAddr <= # TCo_C FirstAddr    ;
    else if (RdBurstEn)     TestRdStartAddr <= # TCo_C TestDdrRdEnd ? StartAddr : NextRdAddrCnt;
  end
  
  /////////////////////////////////////////////////////////
  //Operate Control & State
  wire              RamRdStart  = RdBurstEn  ; //(I)[DdrRdCtrl]Ram Read Start
  
  // wire              RamRdEnd    ; //(O)[DdrRdCtrl]Ram Read End
  wire  [   31:0]   RamRdAddr   ; //(O)[DdrRdCtrl]Ram Read Addrdss
  wire              RamRdDAva   ; //(O)[DdrRdCtrl]Ram Read Available
  wire  [ADW-1:0]   RamRdData   ; //(O)[DdrRdCtrl]Ram Read Data
  wire              RamRdBusy   ; //(O)Ram Read Busy
  wire              RamRdALoad  ; //(O)Ram Read Address Load

  ////////////////////////////
  //Config DDR & AXI Operate Parameter
  wire  [      2:0] CfgRdSize   = CfgDataSize     ; //(I)Config Read Size
  wire  [      1:0] CfgRdBurst  = 2'b01           ; //(I)Config Read Burst Type
  wire  [      1:0] CfgRdLock   = 2'b00           ; //(I)Config Read Lock Flag
  wire  [     31:0] CfgRdAddr   = TestRdStartAddr ; //(I)[DdrRdCtrl]Config Read Start Address
  wire  [      7:0] CfgRdBLen   = RdBurstLen      ; //(I)[DdrRdCtrl]Config Read Burst Length

  ////////////////////////////
  //Axi4 Read Address & Data Bus
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
`ifndef   AXI_FULL_DEPLEX
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
  wire  [AIW-1:0]   ARID        ; //(I)[RdAddr]Read address ID. This signal is the identification tag for the read address group of signals.
  wire  [    1:0]   ARADDR      ; //(I)[RdAddr]Read address. The read address gives the address of the first transfer in a read burst transaction.
  wire  [    7:0]   ARLEN       ; //(I)[RdAddr]Burst length. This signal indicates the exact number of transfers in a burst.
  wire  [    2:0]   ARSIZE      ; //(I)[RdAddr]Burst size. This signal indicates the size of each transfer in the burst.
  wire  [    1:0]   ARBURST     ; //(I)[RdAddr]Burst type. The burst type and the size information determine how the address for each transfer within the burst is calculated.
  wire  [    1:0]   ARLOCK      ; //(I)[RdAddr]Lock type. This signal provides additional information about the atomic characteristics of the transfer.
  wire              ARVALID     ; //(I)[RdAddr]Read address valid. This signal indicates that the channel is signaling valid read address and control information.
  wire              ARREADY     ; //(O)[RdAddr]Read address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
  /////////////            
  wire  [AIW-1:0]   RID         ; //(O)[RdData]Read ID tag. This signal is the identification tag for the read data group of signals generated by the slave.
  wire  [    1:0]   RRESP       ; //(O)[RdData]Read response. This signal indicates the status of the read transfer.
  wire              RLAST       ; //(O)[RdData]Read last. This signal indicates the last transfer in a read burst.
  wire              RVALID      ; //(O)[RdData]Read valid. This signal indicates that the channel is signaling the required read data.
  wire              RREADY      ; //(I)[RdData]Read ready. This signal indicates that the master can accept the read data and response information.
  wire  [ADW-1:0]   RDATA       ; //(O)[RdData]Read data.
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
`endif 
//&&&&&&&&&&&&&&&&&&&&&&&&&&&

  DdrRdCtrl
  # (
      .AXI_ID_WIDTH   ( AXI_ID_WIDTH    ) ,
      .AXI_RD_ID      ( AXI_RD_ID       ) ,
      .AXI_DATA_WIDTH ( AXI_DATA_WIDTH  )
    )
  U2_DdrRdCtrl
  (
    //System Signal
    .SysClk     ( SysClk    ) , //System Clock
    .Reset_N    ( Reset_N   ) , //System Reset
    //Config DDR & AXI Operate Parameter
    .CfgRdSize  ( CfgRdSize ) , //(I)Config Read Size
    .CfgRdBurst ( CfgRdBurst) , //(I)Config Read Burst Type
    .CfgRdLock  ( CfgRdLock ) , //(I)Config Read Lock Flag
    .CfgRdAddr  ( CfgRdAddr ) , //(I)Config Read Start Address
    .CfgRdBLen  ( CfgRdBLen ) , //(I)[DdrOpCtrl]Config Read Burst Length
    //Operate Control & State 
    .RamRdStart ( RamRdStart) , //(I)Ram Read Start
    .RamRdEnd   ( RamRdEnd  ) , //(O)Ram Read End
    .RamRdAddr  ( RamRdAddr ) , //(O)Ram Read Addrdss
    .RamRdData  ( RamRdData ) , //(O)Ram Read Data
    .RamRdDAva  ( RamRdDAva ) , //(O)Ram Read Available
    .RamRdBusy  ( RamRdBusy ) , //(O)Ram Read Busy
    .RamRdALoad ( RamRdALoad) , //(O)Ram Read Address Load
    //Axi4 Read Address & Dat a Bus
    .ARID       ( ARID      ) , //(O)[RdAddr]Read address ID.
    .ARADDR     ( ARADDR    ) , //(O)[RdAddr]Read address.
    .ARLEN      ( ARLEN     ) , //(O)[RdAddr]Burst length.
    .ARSIZE     ( ARSIZE    ) , //(O)[RdAddr]Burst size.
    .ARBURST    ( ARBURST   ) , //(O)[RdAddr]Burst type.
    .ARLOCK     ( ARLOCK    ) , //(O)[RdAddr]Lock type.
    .ARVALID    ( ARVALID   ) , //(O)[RdAddr]Read address valid.
    .ARREADY    ( ARREADY   ) , //(I)[RdAddr]Read address ready.
    ///////////// 
    .RID        ( RID       ) , //(I)[RdData]Read ID tag.
    .RDATA      ( RDATA     ) , //(I)[RdData]Read data.
    .RRESP      ( RRESP     ) , //(I)[RdData]Read response.
    .RLAST      ( RLAST     ) , //(I)[RdData]Read last.
    .RVALID     ( RVALID    ) , //(I)[RdData]Read valid.
    .RREADY     ( RREADY    )   //(O)[RdData]Read ready.
  );

  /////////////////////////////////////////////////////////  
  reg   [1:0] RdDdrReturn   = 2'h0  ;
  reg         RdDataMode    = 1'h0  ;
  
  always @( posedge SysClk)  if (RamRdALoad)  
  begin
    RdDdrReturn[1] <= RdDdrReturn[0];
    RdDdrReturn[0] <= TestDdrRdEnd & (&CfgTestMode) & (&CfgDataMode);
  end
  
  wire  RdDdrReturnEn = RdDdrReturn[1] & RamRdALoad;
  
  always @( posedge SysClk)  
  begin
    if (TestConfInEn)         RdDataMode  <= # TCo_C (&CfgDataMode);
    else if (RdDdrReturnEn)   RdDataMode  <= # TCo_C (~RdDataMode) ;
  end
  
  wire  [ADW-1:0] RamRdDIn    = RamRdData;
  // wire  [ADW-1:0] RamRdDIn    = RdDataMode ? (~RamRdData) : RamRdData;
  
  /////////////////////////////////////////////////////////  
  
  DdrRdDataChk 
  # (
      .RIGHT_CNT_WIDTH  ( RIGHT_CNT_WIDTH ),
      .AXI_DATA_WIDTH   ( AXI_DATA_WIDTH  )
    )
  U2_DdrRdDataChk
  (   
    .SysClk     ( SysClk    ),  //(I)System Clock
    .RdAddrIn   ( RamRdAddr ),  //(I)[DdrRdDataChk]Read Address Input            
    .RdDataEn   ( RamRdDAva ),  //(I)[DdrRdDataChk]DDR Read Data Valid         
    .DdrRdData  ( RamRdDIn  ),  //(I)[DdrRdDataChk]DDR Read DataOut  
  	.DdrRdError ( TestErr   ),  //(O)[DdrRdDataChk]DDR Prbs Error         
  	.DdrRdRight ( TestRight )   //(O)[DdrRdDataChk]DDR Read Right           
  );
  
  /////////////////////////////////////////////////////////
  //AXI4 Operate 
  reg               RamRdDAvaReg  =  1'h0 ; //Axi4 Read Available
  reg   [     31:0] RamRdAddrReg  = 32'h0 ; //Axi4 Read Address
  reg   [ADW-1:0] RamRdDataReg  = 32'h0 ; //Axi4 Read Data
  reg   [     31:0] RdStartAReg   = 32'h0 ; 
  
  always @( posedge SysClk) RamRdDAvaReg  <= # TCo_C RamRdDAva  ; //Axi4 Read Available
  always @( posedge SysClk) RamRdAddrReg  <= # TCo_C RamRdAddr  ; //Axi4 Read Address
  always @( posedge SysClk) RamRdDataReg  <= # TCo_C RamRdData  ; //Axi4 Read Data
  
  always @( posedge SysClk) if(RamRdALoad)  RdStartAReg  <= # TCo_C TestRdStartAddr  ; 
  
  /////////////////////////////////////////////////////////
  assign  AxiRdAva    = RamRdDAvaReg  ; //Axi4 Read Available
  assign  AxiRdAddr   = RamRdAddrReg  ; //Axi4 Read Address
  assign  AxiRdData   = RamRdDataReg  ; //Axi4 Read Data
  assign  AxiRdStartA = RdStartAReg   ; //Axi4 Read Start Address
  
  assign  AxiRdDMode  = RdDataMode    ; //Axi4 Read DDR End
  
  /////////////////////////////////////////////////////////  
//3333333333333333333333333333333333333333333333333333333

//444444444444444444444444444444444444444444444444444444444
//	
//********************************************************/ 
  /////////////////////////////////////////////////////////
  reg [1:0]   WrFirstDCnt     = 2'h0  ;
  reg         Rd_Burst_Sel    = 1'h0  ;
  reg         Wr_Burst_Sel    = 1'h0  ;
  
  always @( posedge SysClk or negedge Reset_N )  
  begin
    if (~Reset_N)           WrFirstDCnt <= # TCo_C 2'h0;
    // else if (TestStopEn)    WrFirstDCnt <= # TCo_C 2'h0;
    else if (TestStartEn)   WrFirstDCnt <= # TCo_C (|TestLen[31:2]) ? 2'h3 : TestLen[1:0];
    else if (WrBurstEn )    WrFirstDCnt <= # TCo_C WrFirstDCnt - {1'h0,{|WrFirstDCnt}};
  end
  always @( posedge SysClk or negedge Reset_N )  
  begin
    if (~Reset_N)           Wr_Burst_Sel  <= # TCo_C 1'h0;
    else if (~TestBusy)     Wr_Burst_Sel  <= # TCo_C 1'h0;
    else if (~&TestMode)    Wr_Burst_Sel  <= # TCo_C 1'h0;
    else if (RamWrEnd)      Wr_Burst_Sel  <= # TCo_C (~|WrFirstDCnt);
  end
  
  always @( posedge SysClk or negedge Reset_N )  
  begin
    if (~Reset_N)           Rd_Burst_Sel  <= # TCo_C 1'h0;
    else if (~TestBusy)     Rd_Burst_Sel  <= # TCo_C 1'h0;
    else if (~&TestMode)    Rd_Burst_Sel  <= # TCo_C 1'h0;
    else if (RamWrEnd)      Rd_Burst_Sel  <= # TCo_C WrBusyFlag & (~|WrFirstDCnt);
  end
  

  /////////////////////////////////////////////////////////
  reg   TestWrBusyReg = 1'h0;
  reg   TesrWrTestEnd = 1'h0;
  
  always @( posedge SysClk)  TestWrBusyReg  <= # TCo_C TestWrBusy;
  always @( posedge SysClk)  TesrWrTestEnd  <= # TCo_C TestWrBusyReg & (~TestWrBusy)  ;
  
  /////////////////////////////////////////////////////////
  reg     Ar_Ready_Reg  = 1'h0 ;
  reg     Ar_Ready_Rise = 1'h0 ; 
  
  always @( posedge SysClk)   Ar_Ready_Reg  <=  ARREADY & ARVALID  & RdBusyFlag;
  always @( posedge SysClk)   Ar_Ready_Rise <=  ~Ar_Ready_Reg & ARREADY & ARVALID & RdBusyFlag;
 
  /////////////////////////////////////////////////////////
  reg   [2:0]   RamRdItvCnt   = 3'h0 ;
  reg           RamRd_Req     = 1'h0 ;
  
  wire  Rd_Addr_Val   = ARREADY & ARVALID ;

  always @( posedge SysClk)   
  begin
    if (ARVALID)                RamRdItvCnt   <=  3'h2 ;
    // else if (&TestRdOpCnt[3:2]) RamRdItvCnt   <=  3'h2 ;
    else if (&TestRdOpCnt[1]) RamRdItvCnt   <=  3'h2 ;
    else if (|RamRdItvCnt)      RamRdItvCnt   <=  RamRdItvCnt  -  3'h1  ;
  end
  always @( posedge SysClk)   RamRd_Req     <=  (RamRdItvCnt == 3'h1) ;
  // always @( * )   RamRd_Req     <=  Rd_Addr_Val ;

  /////////////////////////////////////////////////////////

  
  /////////////////////////////////////////////////////////
  always @( posedge SysClk)  
  begin
    case (TestMode)
      2'b00:
      begin
        WrBurstEn <= # TCo_C 1'h0;
        RdBurstEn <= # TCo_C 1'h0;
      end
      2'b01:
      begin
        WrBurstEn <= # TCo_C 1'h0;
        RdBurstEn <= # TCo_C  RdBusyFlag  ? RamRd_Req : TestStartEn  ;
      end
      2'b10:
      begin
        WrBurstEn <= # TCo_C WrBusyFlag ? RamWrEnd  : TestStartEn ;
        RdBurstEn <= # TCo_C 1'h0;
      end
      2'b11:
      begin
        if (Wr_Burst_Sel)     WrBurstEn <= # TCo_C  WrBusyFlag  ? RamRd_Req : TestStartEn;
        else                  WrBurstEn <= # TCo_C  WrBusyFlag  ? RamWrEnd  : TestStartEn;

        if (Rd_Burst_Sel)     RdBurstEn <= # TCo_C  RamWrEnd    ;
        else                  RdBurstEn <= # TCo_C  RdBusyFlag  & RamRd_Req ;
      end
    endcase
  end
  
  
  
  /////////////////////////////////////////////////////////
  assign    TestBusy  =  TestWrBusy | TestRdBusy ; //(O)Test Busy State  
  
//4444444444444444444444444444444444444444444444444444444


//5555555555555555555555555555555555555555555555555555555
//	
//	Input：
//	output：
//***************************************************/ 
    
  /////////////////////////////////////////////////////////
	
//5555555555555555555555555555555555555555555555555555555


//6666666666666666666666666666666666666666666666666666666
//	
//	Input：
//	output：
//***************************************************/ 
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
`ifndef   AXI_FULL_DEPLEX
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
  Axi4FullDeplex
  # (
      .AXI_ID_WIDTH     ( AXI_ID_WIDTH    ) ,
      .DDR_WRITE_FIRST  ( DDR_WRITE_FIRST ) ,
      .AXI_DATA_WIDTH   ( AXI_DATA_WIDTH  )
    )
  U2_Axi4FullDeplex_0
  (
    //System Signal
    .SysClk   ( SysClk    ), //System Clock
    .Reset_N  ( Reset_N   ), //System Reset
    //Axi Slave Interfac Signal
    .AWID     ( AWID      ),  //(O)[WrAddr]Write address ID.
    .AWADDR   ( AWADDR    ),  //(O)[WrAddr]Write address.
    .AWLEN    ( AWLEN     ),  //(O)[WrAddr]Burst length.
    .AWSIZE   ( AWSIZE    ),  //(O)[WrAddr]Burst size.
    .AWBURST  ( AWBURST   ),  //(O)[WrAddr]Burst type.
    .AWLOCK   ( AWLOCK    ),  //(O)[WrAddr]Lock type.
    .AWVALID  ( AWVALID   ),  //(O)[WrAddr]Write address valid.
    .AWREADY  ( AWREADY   ),  //(I)[WrAddr]Write address ready.
    ///////////                 
    .WID      ( WID       ),  //(O)[WrData]Write ID tag.
    .WDATA    ( WDATA     ),  //(O)[WrData]Write data.
    .WSTRB    ( WSTRB     ),  //(O)[WrData]Write strobes.
    .WLAST    ( WLAST     ),  //(O)[WrData]Write last.
    .WVALID   ( WVALID    ),  //(O)[WrData]Write valid.
    .WREADY   ( WREADY    ),  //(I)[WrData]Write ready.
    ///////////                 
    .BID      ( BID       ),  //(I)[WrResp]Response ID tag.
    .BVALID   ( BVALID    ),  //(I)[WrResp]Write response valid.
    .BREADY   ( BREADY    ),   //(O)[WrResp]Response ready.
    ///////////                 
    .ARID     ( ARID      ),  //(O)[RdAddr]Read address ID.
    .ARADDR   ( ARADDR    ),  //(O)[RdAddr]Read address.
    .ARLEN    ( ARLEN     ),  //(O)[RdAddr]Burst length.
    .ARSIZE   ( ARSIZE    ),  //(O)[RdAddr]Burst size.
    .ARBURST  ( ARBURST   ),  //(O)[RdAddr]Burst type.
    .ARLOCK   ( ARLOCK    ),  //(O)[RdAddr]Lock type.
    .ARVALID  ( ARVALID   ),  //(O)[RdAddr]Read address valid.
    .ARREADY  ( ARREADY   ),  //(I)[RdAddr]Read address ready.
    ///////////                 
    .RID      ( RID       ),  //(I)[RdData]Read ID tag.
    .RDATA    ( RDATA     ),  //(I)[RdData]Read data.
    .RRESP    ( RRESP     ),  //(I)[RdData]Read response.
    .RLAST    ( RLAST     ),  //(I)[RdData]Read last.
    .RVALID   ( RVALID    ),  //(I)[RdData]Read valid.
    .RREADY   ( RREADY    ),  //(O)[RdData]Read ready.
    /////////////
    //DDR Controner AXI4 Signal
    .aid      ( aid       ),  //(O)[Addres] Address ID
    .aaddr    ( aaddr     ),  //(O)[Addres] Address
    .alen     ( alen      ),  //(O)[Addres] Address Brust Length
    .asize    ( asize     ),  //(O)[Addres] Address Burst size
    .aburst   ( aburst    ),  //(O)[Addres] Address Burst type
    .alock    ( alock     ),  //(O)[Addres] Address Lock type
    .avalid   ( avalid    ),  //(O)[Addres] Address Valid
    .aready   ( aready    ),  //(I)[Addres] Address Ready
    .atype    ( atype     ),  //(O)[Addres] Operate Type 0=Read, 1=Write
    /////////// /////////     
    .wid      ( wid       ),  //(O)[Write]  ID
    .wdata    ( wdata     ),  //(O)[Write]  Data
    .wstrb    ( wstrb     ),  //(O)[Write]  Data Strobes(Byte valid)
    .wlast    ( wlast     ),  //(O)[Write]  Data Last
    .wvalid   ( wvalid    ),  //(O)[Write]  Data Valid
    .wready   ( wready    ),  //(I)[Write]  Data Ready
    /////////// /////////     
    .rid      ( rid       ),  //(I)[Read]   ID
    .rdata    ( rdata     ),  //(I)[Read]   Data
    .rlast    ( rlast     ),  //(I)[Read]   Data Last
    .rvalid   ( rvalid    ),  //(I)[Read]   Data Valid
    .rready   ( rready    ),  //(O)[Read]   Data Ready
    .rresp    ( rresp     ),  //(I)[Read]   Response
    /////////// /////////     
    .bid      ( bid       ),  //(I)[Answer] Response Write ID
    .bvalid   ( bvalid    ),  //(I)[Answer] Response valid
    .bready   ( bready    )   //(O)[Answer] Response Ready
  );
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
`endif 
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
  
//6666666666666666666666666666666666666666666666666666666


endmodule






