  
`include "ddr3_controller.vh"

module Debug_Ddr_Controller_Axi
(
  `ifdef  Efinity_Debug

    jtag_inst1_CAPTURE  ,              
    jtag_inst1_DRCK     ,           
    jtag_inst1_RESET    ,            
    jtag_inst1_RUNTEST  ,              
    jtag_inst1_SEL      ,          
    jtag_inst1_SHIFT    ,            
    jtag_inst1_TCK      ,          
    jtag_inst1_TDI      ,          
    jtag_inst1_TMS      ,          
    jtag_inst1_UPDATE   ,             
    jtag_inst1_TDO      ,          
  `else 
    Sim_CfgTestMode     ,
    Sim_CfgBurstLen     ,
    Sim_CfgDataSize     ,
    Sim_CfgFirstAddr    ,
    Sim_CfgTestLen      ,
    Sim_TestStart       ,
    Sim_CfgDataMode     ,

    cal_done    ,                                                      
    cal_pass    ,                                                      
    pass        ,                                                  
    done        ,
  `endif



  clk         ,                                                  
  core_clk    ,                                                       
  twd_clk     ,                                                      
  tdqss_clk   ,                                                        
  tac_clk     ,                                                      
  nrst        ,                                                   
  pll_lock    ,                                                       
  pll1_lock   ,                                                        

  reset       ,                                                        
  cs          ,                                                     
  ras         ,                                                      
  cas         ,                                                      
  we          ,                                                     
  cke         ,                                                      
  addr        ,                                                       
  ba          ,                                                     
  odt         ,         

  o_dm_hi     ,                                                     
  o_dm_lo     ,                                                     

  i_dqs_hi    ,                                                      
  i_dqs_lo    ,                                                      

  i_dqs_n_hi  ,                                                        
  i_dqs_n_lo  ,                                                        


  o_dqs_hi    ,                                                      
  o_dqs_lo    ,                                                      

  o_dqs_n_hi  ,                                                        
  o_dqs_n_lo  ,                                                        


  o_dqs_oe    ,                                                      
  o_dqs_n_oe  ,                                                        

  i_dq_hi     ,                                                     
  i_dq_lo     ,                                                     

  o_dq_hi     ,                                                     
  o_dq_lo     ,                                                     

  o_dq_oe     ,                                                     

  shift       ,                                                   
  shift_sel   ,                                                       
  shift_ena   ,                                                       

  LED                            
);

  //Define  Parameter
  /////////////////////////////////////////////////////////  
  parameter RAM_IDLE          =   `D_RAM_IDLE          ;
  parameter RAM_ACT           =   `D_RAM_ACT           ;
  parameter RAM_WR            =   `D_RAM_WR            ;
  parameter RAM_RD            =   `D_RAM_RD            ;
  parameter RAM_RD2PREA       =   `D_RAM_RD2PREA       ;
  parameter RAM_WR2PREA       =   `D_RAM_WR2PREA       ;
  parameter RAM_WR2RD         =   `D_RAM_WR2RD         ;
  parameter RAM_RD2WR         =   `D_RAM_RD2WR         ;
  parameter RAM_PREA2REF      =   `D_RAM_PREA2REF      ;
  parameter RAM_REF           =   `D_RAM_REF           ;
  parameter RAM_NOP           =   `D_RAM_NOP           ;
  parameter RAM_WPAW          =   `D_RAM_WPAW          ;
  parameter RAM_WPAR          =   `D_RAM_WPAR          ;
  parameter RAM_RPAW          =   `D_RAM_RPAW          ;
  parameter RAM_RPAR          =   `D_RAM_RPAR          ;
  parameter RAM_SRE           =   `D_RAM_SRE           ;
  parameter RAM_SR            =   `D_RAM_SR            ;
  parameter RAM_SRX           =   `D_RAM_SRX           ;
  parameter RAM_INIT          =   `D_RAM_INIT          ;
  parameter RAM_WAITING       =   `D_RAM_WAITING       ;
  parameter BRAM_LEN          =   `D_BRAM_LEN          ;
  parameter BRAM_I_WIDTH      =   `D_BRAM_I_WIDTH      ;
  parameter BRAM_D_WIDTH      =   `D_BRAM_D_WIDTH      ;
  parameter MICRO_SEC         =   `D_MICRO_SEC         ;
  parameter REF_INTERVAL      =   `D_REF_INTERVAL      ;
  parameter DRAM_WIDTH        =   `D_DRAM_WIDTH        ;
  parameter GROUP_WIDTH       =   `D_GROUP_WIDTH       ;
  parameter DRAM_GROUP        =   `D_DRAM_GROUP        ;
  parameter DM_BIT_WIDTH      =   `D_DM_BIT_WIDTH      ;
  parameter ROW               =   `D_ROW               ;
  parameter COL               =   `D_COL               ;
  parameter BANK              =   `D_BANK              ;
  parameter BA_BIT_WIDTH      =   `D_BA_BIT_WIDTH      ;
  parameter WFIFO_WIDTH       =   `D_WFIFO_WIDTH       ;
  parameter BL                =   `D_BL                ;
  parameter usReset           =   `D_usReset           ;
  parameter usCKE             =   `D_usCKE             ;
  parameter tZQinit           =   `D_tZQinit           ;
  parameter ODTH8             =   `D_ODTH8             ;
  parameter tRL               =   `D_tRL               ;
  parameter tWL               =   `D_tWL               ;
  parameter ARBITER_INIT      =   `D_ARBITER_INIT      ;
  parameter ARBITER_COUNT     =   `D_ARBITER_COUNT     ;
  parameter RAM_FILE          =   `D_RAM_FILE          ;
  /////////////   
  parameter   SYS_CLK_PERIOD    = 32'd100_000_000   ; //System Clock Period  
  parameter   RIGHT_CNT_WIDTH   = 27                ; //Data Checker Right Counter Width 

  parameter   AXI_CLK_PERIOD    = 32'd100_000_000   ; //AXI Clock Period(Hz)
  parameter   AXI_DATA_WIDTH    = 128               ; //AXI Data Width(Bit)
  parameter   AXI_WR_ID         = 8'haa             ; //AXI Write ID
  parameter   AXI_RD_ID         = 8'h55             ; //AXI Read ID  
  
  parameter   DDR_CLK_PERIOD    = 32'd800_000_000   ; //DDR Clock Period(Hz)
  parameter   DDR_START_ADDRESS = 32'h00_00_00_00   ; //DDR Memory Start Address
  parameter   DDR_END_ADDRESS   = 32'h00_1f_ff_ff   ; //DDR Memory End Address
  parameter   DDR_DATA_WIDTH    = 16                ; //DDR Data Width(Bit)                                  
  parameter   DDR_WRITE_FIRST   = 1'h1              ; //1:Write First ; 0: Read First   

  
  parameter   AXI_ID_WIDTH    =   8         ;

  localparam  AXI_BYTE_NUMBER = AXI_DATA_WIDTH/8  ;
  localparam  DRAM_DATA_WIDTH = DRAM_WIDTH  ;
  localparam  DRAM_GROUP_NUM  = DRAM_GROUP  ;

  /////////////                 
  localparam  AIW   = AXI_ID_WIDTH      ;
  localparam  ADW   = AXI_DATA_WIDTH    ;
  localparam  ABN   = AXI_BYTE_NUMBER   ;
  localparam  DDW   = DRAM_DATA_WIDTH   ;
  localparam  DGN   = DRAM_GROUP_NUM    ;  
  localparam  DBW   = DM_BIT_WIDTH      ;
  localparam  WFW   = WFIFO_WIDTH       ;  

  /////////////////////////////////////////////////////////


  // Signal Define
  /////////////////////////////////////////////////////////
  `ifdef  Efinity_Debug
  
  input  jtag_inst1_CAPTURE   ;              
  input  jtag_inst1_DRCK      ;           
  input  jtag_inst1_RESET     ;            
  input  jtag_inst1_RUNTEST   ;              
  input  jtag_inst1_SEL       ;          
  input  jtag_inst1_SHIFT     ;            
  input  jtag_inst1_TCK       ;          
  input  jtag_inst1_TDI       ;          
  input  jtag_inst1_TMS       ;          
  input  jtag_inst1_UPDATE    ;             
  output jtag_inst1_TDO       ;  
  
  wire    [31:0]  Sim_CfgFirstAddr;

  `else
  
  input   [ 1:0]   Sim_CfgTestMode  ;
  input   [ 7:0]   Sim_CfgBurstLen  ;
  input   [ 2:0]   Sim_CfgDataSize  ;
  input   [31:0]   Sim_CfgTestLen   ;
  input   [31:0]   Sim_CfgFirstAddr ;
  input            Sim_TestStart    ;
  input   [ 1:0]   Sim_CfgDataMode  ;

  output            cal_done    ;                                                      
  output            cal_pass    ;                                                      
  output            pass        ;                                                  
  output            done        ;             

  `endif         

  input           clk         ;                                                  
  input           core_clk    ;                                                       
  input           twd_clk     ;                                                      
  input           tdqss_clk   ;                                                        
  input           tac_clk     ;                                                      
  input           nrst        ;                                                   
  input           pll_lock    ;                                                       
  input           pll1_lock   ;                                                        

  output          reset       ;                                                        
  output          cs          ;                                                     
  output          ras         ;                                                      
  output          cas         ;                                                      
  output          we          ;                                                     
  output          cke         ;                                                      
  output [15:0]   addr        ;                                                       
  output [2:0]    ba          ;                                                     
  output          odt         ;         

  output  [DRAM_GROUP-1'b1:0]   o_dm_hi     ;                                                     
  output  [DRAM_GROUP-1'b1:0]   o_dm_lo     ;                                                     

  input   [DRAM_GROUP-1'b1:0]   i_dqs_hi    ;                                                      
  input   [DRAM_GROUP-1'b1:0]   i_dqs_lo    ;                                                      

  input   [DRAM_GROUP-1'b1:0]   i_dqs_n_hi  ;                                                        
  input   [DRAM_GROUP-1'b1:0]   i_dqs_n_lo  ;                                                        


  output  [DRAM_GROUP-1'b1:0]   o_dqs_hi    ;                                                      
  output  [DRAM_GROUP-1'b1:0]   o_dqs_lo    ;                                                      

  output  [DRAM_GROUP-1'b1:0]   o_dqs_n_hi  ;                                                        
  output  [DRAM_GROUP-1'b1:0]   o_dqs_n_lo  ;                                                        


  output  [DRAM_GROUP-1'b1:0]   o_dqs_oe    ;                                                      
  output  [DRAM_GROUP-1'b1:0]   o_dqs_n_oe  ;                                                        

  input   [DRAM_WIDTH-1'b1:0]   i_dq_hi     ;                                                     
  input   [DRAM_WIDTH-1'b1:0]   i_dq_lo     ;                                                     

  output  [DRAM_WIDTH-1'b1:0]   o_dq_hi     ;                                                     
  output  [DRAM_WIDTH-1'b1:0]   o_dq_lo     ;                                                     

  output  [DRAM_WIDTH-1'b1:0]   o_dq_oe     ;                                                     

  output  [2:0]     shift       ;                                                   
  output  [4:0]     shift_sel   ;                                                       
  output            shift_ena   ;                                                       
                                        
  output  [1:0]     LED         ;              

  /////////////////////////////////////////////////////////



//000000000000000000000000000000000000000000000000000000000
//
//********************************************************/
  /////////////////////////////////////////////////////////
  wire    Sys_Clk   = clk  ;

  /////////////////////////////////////////////////////////
  reg   [3:0]   Reset_Cnt     = 3'h0  ;
  wire          DdrResetCtrl  ;

  always  @(posedge Sys_Clk )
  begin
    if (~pll_lock)          Reset_Cnt   = 3'h0  ;
    else if (~pll1_lock)    Reset_Cnt   = 3'h0  ;
    else if (DdrResetCtrl)  Reset_Cnt   = 3'h0  ;
    else if (~&Reset_Cnt)   Reset_Cnt   = Reset_Cnt + 3'h1  ;
  end

  wire  Sys_Rst_N  = Reset_Cnt[3]  ;

  /////////////////////////////////////////////////////////
  reg   [31:0]  Led0_Flash_Cnt  = 32'h0 ;
  reg   [31:0]  Led1_Flash_Cnt  = 32'h0 ;
  reg   [ 1:0]  LED             =  2'h1 ;

  always  @(posedge Sys_Clk   or negedge Sys_Rst_N  )
  begin
    if (~Sys_Rst_N)             Led0_Flash_Cnt <= 32'd100_000_000 ; 
    else if (|Led0_Flash_Cnt)   Led0_Flash_Cnt <= Led0_Flash_Cnt  - 32'h1 ;
    else                        Led0_Flash_Cnt <= 32'd100_000_000 ;
  end  
  always  @(posedge Sys_Clk)    if (~|Led0_Flash_Cnt)   LED[0]  <=  ~LED[0] ;
  
  ///////////////////////////
  always  @(posedge core_clk  or negedge Sys_Rst_N  )
  begin
    if (~Sys_Rst_N)             Led1_Flash_Cnt <= 32'd200_000_000 ; 
    else if (|Led1_Flash_Cnt)   Led1_Flash_Cnt <= Led1_Flash_Cnt  - 32'h1 ;
    else                        Led1_Flash_Cnt <= 32'd200_000_000 ;
  end
  always  @(posedge core_clk)   if (~|Led1_Flash_Cnt)   LED[1]  <=  ~LED[1] ;

  /////////////////////////////////////////////////////////
//000000000000000000000000000000000000000000000000000000000

//111111111111111111111111111111111111111111111111111111111
//
//********************************************************/
  /////////////////////////////////////////////////////////
  reg           Ddr_Ready       = 1'h0  ;
  /////////////////////////////////////////////////////////
  wire  [ 1:0]      CfgDataMode     ; //(I)Config Test Data Mode 0: Normal 1:Reverse 2,3:Normal&Revers Alternate 
  wire  [ 1:0]      CfgTestMode     ; //(I)Test Mode: 1:Read Only;2:Write Only;3:Write/Read alternate
  wire  [ 7:0]      CfgBurstLen     ; //(I)Config Burst Length;
  wire  [ 2:0]      CfgDataSize     ; //(I)Config Data Size
  wire  [31:0]      CfgStartAddr    ; //(I)Config Start Address
  wire  [31:0]      CfgFirstAddr    ; //(I)Config First Address
  wire  [31:0]      CfgEndAddr      ; //(I)Config End Address
  wire  [31:0]      CfgTestLen      ; //(I)Cinfig Test Length
  wire              TestStart       ; //(I)Test Start Control
    //Test State                    
  wire              TestBusy        ; //(O)Test Busy State
  wire              TestErr         ; //(O)Test Data Error
  wire              TestRight       ; //(O)Test Data Right
  //AXI4 Operate                    
  wire  [31:0]      AxiWrStartA     ; //Axi4 Write Start Address
  wire              AxiWrEn         ; //Axi4 Write Enable
  wire  [31:0]      AxiWrAddr       ; //Axi4 Write Address
  wire  [ABN-1:0]   AxiWrMask       ; //Axi4 Write Mask
  wire  [  255:0]   AxiWrData       ; //Axi4 Write Data
  wire  [31:0]      AxiRdStartA     ; //Axi4 Read Start Address
  wire              AxiRdAva        ; //Axi4 Read Available
  wire  [31:0]      AxiRdAddr       ; //Axi4 Read Address
  wire  [255:0]     AxiRdData       ; //Axi4 Read Data
  wire              AxiWrDMode      ; //Axi4 Write DDR End
  wire              AxiRdDMode      ; //Axi4 Read DDR End
  //Axi Interfac Signal
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
`ifdef  AXI_FULL_DEPLEX
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
  wire  [AIW-1:0]   Axi_AWID      ; //(I)[WrAddr]Write address ID. This signal is the identification tag for the write address group of signals.
  wire  [   31:0]   Axi_AWADDR    ; //(I)[WrAddr]Write address. The write address gives the address of the first transfer in a write burst transaction.
  wire  [    7:0]   Axi_AWLEN     ; //(I)[WrAddr]Burst length. The burst length gives the exact number of transfers in a burst. This information determines the number of data transfers associated with the address.
  wire  [    2:0]   Axi_AWSIZE    ; //(I)[WrAddr]Burst size. This signal indicates the size of each transfer in the burst.
  wire  [    1:0]   Axi_AWBURST   ; //(I)[WrAddr]Burst type. The burst type and the size information, determine how the address for each transfer within the burst is calculated.
  wire  [    1:0]   Axi_AWLOCK    ; //(I)[WrAddr]Lock type. Provides additional information about the atomic characteristics of the transfer.
  wire              Axi_AWVALID   ; //(I)[WrAddr]Write address valid. This signal indicates that the channel is signaling valid write address and control information.
  wire              Axi_AWREADY   ; //(O)[WrAddr]Write address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
  /////////////
  wire  [AIW-1:0]   Axi_ARID      ; //(I)[RdAddr]Read address ID. This signal is the identification tag for the read address group of signals.
  wire  [   31:0]   Axi_ARADDR    ; //(I)[RdAddr]Read address. The read address gives the address of the first transfer in a read burst transaction.
  wire  [    7:0]   Axi_ARLEN     ; //(I)[RdAddr]Burst length. This signal indicates the exact number of transfers in a burst.
  wire  [    2:0]   Axi_ARSIZE    ; //(I)[RdAddr]Burst size. This signal indicates the size of each transfer in the burst.
  wire  [    1:0]   Axi_ARBURST   ; //(I)[RdAddr]Burst type. The burst type and the size information determine how the address for each transfer within the burst is calculated.
  wire  [    1:0]   Axi_ARLOCK    ; //(I)[RdAddr]Lock type. This signal provides additional information about the atomic characteristics of the transfer.
  wire              Axi_ARVALID   ; //(I)[RdAddr]Read address valid. This signal indicates that the channel is signaling valid read address and control information.
  wire              Axi_ARREADY   ; //(O)[RdAddr]Read address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
  /////////////
  wire  [AIW-1:0]   Axi_WID       ; //(I)[WrData]Write ID tag. This signal is the ID tag of the write data transfer.
  wire  [ABN-1:0]   Axi_WSTRB     ; //(I)[WrData]Write strobes. This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight bits of the write data bus.
  wire              Axi_WLAST     ; //(I)[WrData]Write last. This signal indicates the last transfer in a write burst.
  wire              Axi_WVALID    ; //(I)[WrData]Write valid. This signal indicates that valid write data and strobes are available.
  wire  [ADW-1:0]   Axi_WDATA     ; //(O)[WrData]Write data.
  wire              Axi_WREADY    ; //(I)[WrData]Write ready. This signal indicates that the slave can accept the write data.
  /////////////
  wire  [AIW-1:0]   Axi_BID       ; //(O)[WrResp]Response ID tag. This signal is the ID tag of the write response.
  wire              Axi_BVALID    ; //(O)[WrResp]Write response valid. This signal indicates that the channel is signaling a valid write response.
  wire              Axi_BREADY    ; //(I)[WrResp]Response ready. This signal indicates that the master can accept a write response.
  /////////////      
  wire              Axi_RREADY    ; //(I)[RdData]Read ready. This signal indicates that the master can accept the read data and response information.
  wire  [AIW-1:0]   Axi_RID       ; //(O)[RdData]Read ID tag. This signal is the identification tag for the read data group of signals generated by the slave.
  wire  [    1:0]   Axi_RRESP     ; //(O)[RdData]Read response. This signal indicates the status of the read transfer.
  wire              Axi_RLAST     ; //(O)[RdData]Read last. This signal indicates the last transfer in a read burst.
  wire              Axi_RVALID    ; //(O)[RdData]Read valid. This signal indicates that the channel is signaling the required read data.
  wire  [ADW-1:0]   Axi_RDATA     ; //(O)[RdData]Read data.
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
`else
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
  wire  [ 7:0]  DdrCtrl_AID     ; //(O)[Addres] Address ID
  wire  [31:0]  DdrCtrl_AADDR   ; //(O)[Addres] Address
  wire  [ 7:0]  DdrCtrl_ALEN    ; //(O)[Addres] Address Brust Length
  wire  [ 2:0]  DdrCtrl_ASIZE   ; //(O)[Addres] Address Burst size
  wire  [ 1:0]  DdrCtrl_ABURST  ; //(O)[Addres] Address Burst type
  wire  [ 1:0]  DdrCtrl_ALOCK   ; //(O)[Addres] Address Lock type
  wire          DdrCtrl_AVALID  ; //(O)[Addres] Address Valid
  wire          DdrCtrl_AREADY  ; //(I)[Addres] Address Ready
  wire          DdrCtrl_ATYPE   ; //(O)[Addres] Operate Type 0=Read, 1=Write
  /////////// 
  wire  [ 7:0]  DdrCtrl_WID     ; //(O)[Write]  ID
  wire [127:0]  DdrCtrl_WDATA   ; //(O)[Write]  Data
  wire  [15:0]  DdrCtrl_WSTRB   ; //(O)[Write]  Data Strobes(Byte valid)
  wire          DdrCtrl_WLAST   ; //(O)[Write]  Data Last
  wire          DdrCtrl_WVALID  ; //(O)[Write]  Data Valid
  wire          DdrCtrl_WREADY  ; //(I)[Write]  Data Ready
  /////////// 
  wire  [ 7:0]  DdrCtrl_RID     ; //(I)[Read]   ID
  wire [127:0]  DdrCtrl_RDATA   ; //(I)[Read]   Data
  wire          DdrCtrl_RLAST   ; //(I)[Read]   Data Last
  wire          DdrCtrl_RVALID  ; //(I)[Read]   Data Valid
  wire          DdrCtrl_RREADY  ; //(O)[Read]   Data Ready
  wire  [ 1:0]  DdrCtrl_RRESP   ; //(I)[Read]   Response
  /////////// 
  wire  [ 7:0]  DdrCtrl_BID     ; //(I)[Answer] Response Write ID
  wire          DdrCtrl_BVALID  ; //(I)[Answer] Response valid
  wire          DdrCtrl_BREADY  ; //(O)[Answer] Response Ready
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
`endif 
//&&&&&&&&&&&&&&&&&&&&&&&&&&&    

  DdrTest  
  # (
      .AXI_DATA_WIDTH     ( AXI_DATA_WIDTH    ) ,
      .DDR_WRITE_FIRST    ( DDR_WRITE_FIRST   ) , //1:Write First ; 0: Read First
      .RIGHT_CNT_WIDTH    ( RIGHT_CNT_WIDTH   ) ,
      .DDR_START_ADDRESS  ( DDR_START_ADDRESS ) , //DDR Memory Start Address
      .DDR_END_ADDRESS    ( DDR_END_ADDRESS   ) , //DDR Memory End Address
      .AXI_WR_ID          ( AXI_WR_ID         ) ,
      .AXI_RD_ID          ( AXI_RD_ID         ) 
    )
  U1_DdrTest
  (
    //System Signal
    .SysClk       ( Sys_Clk           ) , //(O)System Clock
    .Reset_N      ( Ddr_Ready         ) , //(I)System Reset (Low Active)
    //Test Configuration & State        
    .CfgTestMode  ( CfgTestMode       ) , //(I)Test Mode: 1:Read Only;2:Write Only;3:Write/Read alternate
    .CfgBurstLen  ( CfgBurstLen       ) , //(I)Config Burst Length;
    .CfgDataSize  ( CfgDataSize       ) , //(I)Config Data Size
    .CfgStartAddr ( CfgStartAddr      ) , //(I)Config Start Address
    .CfgFirstAddr ( CfgFirstAddr      ) , //(I)Config First Address
    .CfgEndAddr   ( CfgEndAddr        ) , //(I)Config End Address
    .CfgTestLen   ( CfgTestLen        ) , //(I)Cinfig Test Length
    .CfgDataMode  ( CfgDataMode       ) , //(I)Config Test Data Mode 0: Nomarl 1:Reverse
    .TestStart    ( TestStart         ) , //(I)Test Start Control
    //Test State  & Result              
    .TestBusy     ( TestBusy          ) , //(O)Test Busy State
    .TestErr      ( TestErr           ) , //(O)Test Data Error
    .TestRight    ( TestRight         ) , //(O)Test Data Right
    //AXI4 Operate                      
    .AxiWrStartA  ( AxiWrStartA       ) , //Axi4 Write Start Address
    .AxiWrEn      ( AxiWrEn           ) , //Axi4 Write Enable
    .AxiWrAddr    ( AxiWrAddr         ) , //Axi4 Write Address
    .AxiWrMask    ( AxiWrMask         ) , //Axi4 Write Mask
    .AxiWrData    ( AxiWrData         ) , //Axi4 Write Data
    .AxiRdStartA  ( AxiRdStartA       ) , //Axi4 Read Start Address
    .AxiRdAva     ( AxiRdAva          ) , //Axi4 Read Available
    .AxiRdAddr    ( AxiRdAddr         ) , //Axi4 Read Address
    .AxiRdData    ( AxiRdData         ) , //Axi4 Read Data
    .AxiWrDMode   ( AxiWrDMode        ) , //Axi4 Write DDR End
    .AxiRdDMode   ( AxiRdDMode        ) , //Axi4 Read DDR End
    //Axi Interfac Signal
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
`ifdef  AXI_FULL_DEPLEX
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
    .AWID       ( Axi_AWID          ) , //(I)[WrAddr]Write address ID. This signal is the identification tag for the write address group of signals.
    .AWADDR     ( Axi_AWADDR        ) , //(I)[WrAddr]Write address. The write address gives the address of the first transfer in a write burst transaction.
    .AWLEN      ( Axi_AWLEN         ) , //(I)[WrAddr]Burst length. The burst length gives the exact number of transfers in a burst. This information determines the number of data transfers associated with the address.
    .AWSIZE     ( Axi_AWSIZE        ) , //(I)[WrAddr]Burst size. This signal indicates the size of each transfer in the burst.
    .AWBURST    ( Axi_AWBURST       ) , //(I)[WrAddr]Burst type. The burst type and the size information, determine how the address for each transfer within the burst is calculated.
    .AWLOCK     ( Axi_AWLOCK        ) , //(I)[WrAddr]Lock type. Provides additional information about the atomic characteristics of the transfer.
    .AWVALID    ( Axi_AWVALID       ) , //(I)[WrAddr]Write address valid. This signal indicates that the channel is signaling valid write address and control information.
    .AWREADY    ( Axi_AWREADY       ) , //(O)[WrAddr]Write address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
    /////////////   
    .ARID       ( Axi_ARID          ) , //(I)[RdAddr]Read address ID. This signal is the identification tag for the read address group of signals.
    .ARADDR     ( Axi_ARADDR        ) , //(I)[RdAddr]Read address. The read address gives the address of the first transfer in a read burst transaction.
    .ARLEN      ( Axi_ARLEN         ) , //(I)[RdAddr]Burst length. This signal indicates the exact number of transfers in a burst.
    .ARSIZE     ( Axi_ARSIZE        ) , //(I)[RdAddr]Burst size. This signal indicates the size of each transfer in the burst.
    .ARBURST    ( Axi_ARBURST       ) , //(I)[RdAddr]Burst type. The burst type and the size information determine how the address for each transfer within the burst is calculated.
    .ARLOCK     ( Axi_ARLOCK        ) , //(I)[RdAddr]Lock type. This signal provides additional information about the atomic characteristics of the transfer.
    .ARVALID    ( Axi_ARVALID       ) , //(I)[RdAddr]Read address valid. This signal indicates that the channel is signaling valid read address and control information.
    .ARREADY    ( Axi_ARREADY       ) , //(O)[RdAddr]Read address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
    /////////////
    .WID        ( Axi_WID           ) , //(I)[WrData]Write ID tag. This signal is the ID tag of the write data transfer.
    .WSTRB      ( Axi_WSTRB         ) , //(I)[WrData]Write strobes. This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight bits of the write data bus.
    .WLAST      ( Axi_WLAST         ) , //(I)[WrData]Write last. This signal indicates the last transfer in a write burst.
    .WVALID     ( Axi_WVALID        ) , //(I)[WrData]Write valid. This signal indicates that valid write data and strobes are available.
    .WDATA      ( Axi_WDATA         ) , //(O)[WrData]Write data.
    .WREADY     ( Axi_WREADY        ) , //(I)[WrData]Write ready. This signal indicates that the slave can accept the write data.
    /////////////
    .BID        ( Axi_BID           ) , //(O)[WrResp]Response ID tag. This signal is the ID tag of the write response.
    .BVALID     ( Axi_BVALID        ) , //(O)[WrResp]Write response valid. This signal indicates that the channel is signaling a valid write response.
    .BREADY     ( Axi_BREADY        ) , //(I)[WrResp]Response ready. This signal indicates that the master can accept a write response.
    /////////////
    .RID        ( Axi_RID           ) , //(O)[RdData]Read ID tag. This signal is the identification tag for the read data group of signals generated by the slave.
    .RRESP      ( Axi_RRESP         ) , //(O)[RdData]Read response. This signal indicates the status of the read transfer.
    .RLAST      ( Axi_RLAST         ) , //(O)[RdData]Read last. This signal indicates the last transfer in a read burst.
    .RVALID     ( Axi_RVALID        ) , //(O)[RdData]Read valid. This signal indicates that the channel is signaling the required read data.
    .RREADY     ( Axi_RREADY        ) , //(I)[RdData]Read ready. This signal indicates that the master can accept the read data and response information.
    .RDATA      ( Axi_RDATA         )   //(O)[RdData]Read data.
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
`else
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
    .avalid       ( DdrCtrl_AVALID    ) , //(O)[Addres] Address Valid
    .aready       ( DdrCtrl_AREADY    ) , //(I)[Addres] Address Ready
    .aaddr        ( DdrCtrl_AADDR     ) , //(O)[Addres] Address
    .aid          ( DdrCtrl_AID       ) , //(O)[Addres] Address ID
    .alen         ( DdrCtrl_ALEN      ) , //(O)[Addres] Address Brust Length
    .asize        ( DdrCtrl_ASIZE     ) , //(O)[Addres] Address Burst size
    .aburst       ( DdrCtrl_ABURST    ) , //(O)[Addres] Address Burst type
    .alock        ( DdrCtrl_ALOCK     ) , //(O)[Addres] Address Lock type
    .atype        ( DdrCtrl_ATYPE     ) , //(O)[Addres] Operate Type 0=Read, 1=Write
    /////////////
    .wid          ( DdrCtrl_WID       ) , //(O)[Write]  ID
    .wvalid       ( DdrCtrl_WVALID    ) , //(O)[Write]  Data Valid
    .wready       ( DdrCtrl_WREADY    ) , //(I)[Write]  Data Ready
    .wdata        ( DdrCtrl_WDATA     ) , //(O)[Write]  Data
    .wstrb        ( DdrCtrl_WSTRB     ) , //(O)[Write]  Data Strobes(Byte valid)
    .wlast        ( DdrCtrl_WLAST     ) , //(O)[Write]  Data Last
    /////////////
    .rvalid       ( DdrCtrl_RVALID    ) , //(I)[Read]   Data Valid
    .rready       ( DdrCtrl_RREADY    ) , //(O)[Read]   Data Ready
    .rdata        ( DdrCtrl_RDATA     ) , //(I)[Read]   Data
    .rid          ( DdrCtrl_RID       ) , //(I)[Read]   ID
    .rresp        ( DdrCtrl_RRESP     ) , //(I)[Read]   Response
    .rlast        ( DdrCtrl_RLAST     ) , //(I)[Read]   Data Last
    /////////////
    .bvalid       ( DdrCtrl_BVALID    ) , //(I)[Answer] Response valid
    .bready       ( DdrCtrl_BREADY    ) , //(O)[Answer] Response Ready  
    .bid          ( DdrCtrl_BID       )   //(I)[Answer] Response Write ID
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
`endif 
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
  );


  /////////////////////////////////////////////////////////
  `ifdef  Efinity_Debug
    
    assign    CfgFirstAddr = DDR_START_ADDRESS  ;

  `else

    assign    CfgFirstAddr = Sim_CfgFirstAddr  ;

  `endif 

  /////////////////////////////////////////////////////////
//111111111111111111111111111111111111111111111111111111111

//222222222222222222222222222222222222222222222222222222222
//
//********************************************************/
  /////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////
  reg [1:0]   TestStartReg  ;
  reg         TestStartEn   ;
  
  always @( posedge Sys_Clk)  TestStartReg <=  {TestStartReg[0],TestStart};
  always @( posedge Sys_Clk)  TestStartEn  <=  (TestStartReg == 2'h1);
  
  wire          StatiClr  = TestStartEn; //(I)Staistics Couter Clear
    
  /////////////////////////////////////////////////////////
  wire  [23:0]  TestTime  ; //(O)Test Time      
  wire  [23:0]  ErrCnt    ; //(O)Test Error Counter   
  wire  [47:0]  OpTotCyc  ; //(O)Total Operate Cycle Counter
  wire  [47:0]  OpActCyc  ; //(O)Actual Operate Cycle Counter
  wire  [ 9:0]  OpEffic   ; //(O)Operate Efficiency
  wire  [15:0]  BandWidth ; //(O)BandWidth  
  wire  [9:0]   WrPeriMin ; //Write Minimum Period For One Burst
  wire  [9:0]   WrPeriAvg ; //Write Average Period For One Burst
  wire  [9:0]   WrPeriMax ; //Write maximum Period For One Burst
  wire  [9:0]   RdPeriMin ; //Read Minimum Period For One Burst
  wire  [9:0]   RdPeriAvg ; //Read Average Period For One Burst
  wire  [9:0]   RdPeriMax ; //Read maximum Period For One Burst
  wire          TimeOut   ; //(O)TimeOut
  
  DdrTestStatic
  # (
      .DDR_CLK_PERIOD ( DDR_CLK_PERIOD  ),
      .DDR_DATA_WIDTH ( DDR_DATA_WIDTH  ),
      .AXI_CLK_PERIOD ( AXI_CLK_PERIOD ),
      .AXI_DATA_WIDTH ( AXI_DATA_WIDTH )
    )
  U2_DdrTestStatis
  ( 
    //System Signal
    .SysClk     ( Sys_Clk           ) , //(O)System Clock
    .Reset_N    ( Ddr_Ready         ) , //(I)System Reset (Low Active)
    //DDR Controner Operate Statistics Control & Result
    .TestBusy   ( TestBusy          ) , //(I)Test Busy State
    .TestErr    ( TestErr           ) , //(I)Test Read Data Error
    .StatiClr   ( StatiClr          ) , //(I)Staistics Couter Clear
    .TestTime   ( TestTime          ) , //(O)Test Time      
    .ErrCnt     ( ErrCnt            ) , //(O)Test Error Counter   
    .OpTotCyc   ( OpTotCyc          ) , //(O)Total Operate Cycle Counter
    .OpActCyc   ( OpActCyc          ) , //(O)Actual Operate Cycle Counter
    .OpEffic    ( OpEffic           ) , //(O)Operate Efficiency
    .BandWidth  ( BandWidth         ) , //(O)BandWidth
    .WrPeriMin  ( WrPeriMin         ) , //Write Minimum Period For One Burst
    .WrPeriAvg  ( WrPeriAvg         ) , //Write Average Period For One Burst
    .WrPeriMax  ( WrPeriMax         ) , //Write maximum Period For One Burst
    .RdPeriMin  ( RdPeriMin         ) , //Read Minimum Period For One Burst
    .RdPeriAvg  ( RdPeriAvg         ) , //Read Average Period For One Burst
    .RdPeriMax  ( RdPeriMax         ) , //Read maximum Period For One Burst
    .TimeOut    ( TimeOut           ) , //(O)TimeOut
    //DDR Controner AXI4 Signal
    .avalid     ( DdrCtrl_AVALID    ) , //(O)[Addres] Address Valid
    .aready     ( DdrCtrl_AREADY    ) , //(I)[Addres] Address Ready
    .atype      ( DdrCtrl_ATYPE     ) , //(O)[Addres] Operate Type 0=Read, 1=Write
    .wlast      ( DdrCtrl_WLAST     ) , //(O)[Write]  Data Last
    .wvalid     ( DdrCtrl_WVALID    ) , //(O)[Write]  Data Valid
    .wready     ( DdrCtrl_WREADY    ) , //(I)[Write]  Data Ready
    .rlast      ( DdrCtrl_RLAST     ) , //(I)[Read]   Data Last
    .rvalid     ( DdrCtrl_RVALID    ) , //(I)[Read]   Data Valid
    .rready     ( DdrCtrl_RREADY    )   //(O)[Read]   Data Ready
  );


  /////////////////////////////////////////////////////////

//222222222222222222222222222222222222222222222222222222222

//333333333333333333333333333333333333333333333333333333333
//
//********************************************************/
  /////////////////////////////////////////////////////////
  //calibration Interface
  wire              [2:0]   Pll_Shift       ; //(O)Pll Shift Value
  wire              [4:0]   Pll_Shift_Sel   ; //(O)Pll Shift Channel Select
  wire                      Pll_Shift_Ena   ; //(O)Pll Shift Enable
  /////////////   
  wire                      Cal_Enable      ; //(I)Calibration Enable
  wire                      Cal_Done        ; //(O)Calibration Done
  wire                      Cal_Pass        ; //(O)Calibration Pass
  wire              [6:0]   Cal_Fail_Log    ; //(O)Calibration Fail Log
  wire              [2:0]   Cal_Shift_Val   ; //(O)Calibration Shift Value
  //DDR Memory Interface
  wire                      reset           ; //(O)DDR Reset
  wire                      cs              ; //(O)DDR Chip Select
  wire                      ras             ; //(O)DDR Row Address Select
  wire                      cas             ; //(O)DDR Column aAddress Select
  wire                      we              ; //(O)DDR Write
  wire                      cke             ; //(O)DDR Clock Enable
  wire    [15:0]            addr            ; //(O)DDR Address
  wire    [2:0]             ba              ; //(O)DDR Bank Address
  wire                      odt             ; //(O)DDR ODT
  wire    [DRAM_GROUP-1:0]  o_dm_hi         ; //(O)DDR Data Mask Output (HI)
  wire    [DRAM_GROUP-1:0]  o_dm_lo         ; //(O)DDR Data Mask Output (LO)
  wire    [DRAM_GROUP-1:0]  o_dqs_hi        ; //(O)DDR DQS output 
  wire    [DRAM_GROUP-1:0]  o_dqs_lo        ; //(O)DDR DQS output 
  wire    [DRAM_GROUP-1:0]  o_dqs_n_hi      ; //(O)DDR DQS output 
  wire    [DRAM_GROUP-1:0]  o_dqs_n_lo      ; //(O)DDR DQS output 
  wire    [DRAM_GROUP-1:0]  o_dqs_oe        ; //(O)DDR DQS 
  wire    [DRAM_GROUP-1:0]  o_dqs_n_oe      ; //(O)DDR DQS 
  wire    [DRAM_WIDTH-1:0]  o_dq_hi         ; //(O)DDR DQ Data Input (HI)
  wire    [DRAM_WIDTH-1:0]  o_dq_lo         ; //(O)DDR DQ Data Input (LO)
  wire    [DRAM_WIDTH-1:0]  o_dq_oe         ; //(O)DDR DQ Data Output Enable

  Ddr_Controller_Axi  U3_Ddr_Controller_Axi
  (
    .Sys_Clk                ( Sys_Clk   ) , //System Clock 
    .Sys_Rst_N              ( Sys_Rst_N ) , //System Reset (Low Active)
    .Ddr_Main_Clk           ( core_clk  ) , //DDR Controller Main Controller Clock        (core_clk )
    .Ddr_DataOut_Clk        ( twd_clk   ) , //DDR Controller DQ/DM Output Clock           (twd_clk  )
    .Ddr_CtrlOut_Clk        ( tdqss_clk ) , //DDR Controller Addr/Ctrl/Dqss Output Clock  (tdqss_clk)  
    .Ddr_DataIn_Clk         ( tac_clk   ) , //DDR Controller DQ/DQS input Clock           (tac_clk  )  
    //Axi Interfac Signal
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
`ifdef  AXI_FULL_DEPLEX
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
    .I_AWID       ( Axi_AWID          ) , //(I)[WrAddr]Write address ID. This signal is the identification tag for the write address group of signals.
    .I_AWADDR     ( Axi_AWADDR        ) , //(I)[WrAddr]Write address. The write address gives the address of the first transfer in a write burst transaction.
    .I_AWLEN      ( Axi_AWLEN         ) , //(I)[WrAddr]Burst length. The burst length gives the exact number of transfers in a burst. This information determines the number of data transfers associated with the address.
    .I_AWSIZE     ( Axi_AWSIZE        ) , //(I)[WrAddr]Burst size. This signal indicates the size of each transfer in the burst.
    .I_AWBURST    ( Axi_AWBURST       ) , //(I)[WrAddr]Burst type. The burst type and the size information, determine how the address for each transfer within the burst is calculated.
    .I_AWLOCK     ( Axi_AWLOCK        ) , //(I)[WrAddr]Lock type. Provides additional information about the atomic characteristics of the transfer.
    .I_AWVALID    ( Axi_AWVALID       ) , //(I)[WrAddr]Write address valid. This signal indicates that the channel is signaling valid write address and control information.
    .O_AWREADY    ( Axi_AWREADY       ) , //(O)[WrAddr]Write address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
    /////////////   
    .I_ARID       ( Axi_ARID          ) , //(I)[RdAddr]Read address ID. This signal is the identification tag for the read address group of signals.
    .I_ARADDR     ( Axi_ARADDR        ) , //(I)[RdAddr]Read address. The read address gives the address of the first transfer in a read burst transaction.
    .I_ARLEN      ( Axi_ARLEN         ) , //(I)[RdAddr]Burst length. This signal indicates the exact number of transfers in a burst.
    .I_ARSIZE     ( Axi_ARSIZE        ) , //(I)[RdAddr]Burst size. This signal indicates the size of each transfer in the burst.
    .I_ARBURST    ( Axi_ARBURST       ) , //(I)[RdAddr]Burst type. The burst type and the size information determine how the address for each transfer within the burst is calculated.
    .I_ARLOCK     ( Axi_ARLOCK        ) , //(I)[RdAddr]Lock type. This signal provides additional information about the atomic characteristics of the transfer.
    .I_ARVALID    ( Axi_ARVALID       ) , //(I)[RdAddr]Read address valid. This signal indicates that the channel is signaling valid read address and control information.
    .O_ARREADY    ( Axi_ARREADY       ) , //(O)[RdAddr]Read address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
    /////////////
    .I_WID        ( Axi_WID           ) , //(I)[WrData]Write ID tag. This signal is the ID tag of the write data transfer.
    .I_WSTRB      ( Axi_WSTRB         ) , //(I)[WrData]Write strobes. This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight bits of the write data bus.
    .I_WLAST      ( Axi_WLAST         ) , //(I)[WrData]Write last. This signal indicates the last transfer in a write burst.
    .I_WVALID     ( Axi_WVALID        ) , //(I)[WrData]Write valid. This signal indicates that valid write data and strobes are available.
    .I_WDATA      ( Axi_WDATA         ) , //(O)[WrData]Write data.
    .O_WREADY     ( Axi_WREADY        ) , //(I)[WrData]Write ready. This signal indicates that the slave can accept the write data.
    /////////////
    .O_BID        ( Axi_BID           ) , //(O)[WrResp]Response ID tag. This signal is the ID tag of the write response.
    .O_BVALID     ( Axi_BVALID        ) , //(O)[WrResp]Write response valid. This signal indicates that the channel is signaling a valid write response.
    .I_BREADY     ( Axi_BREADY        ) , //(I)[WrResp]Response ready. This signal indicates that the master can accept a write response.
    /////////////
    .O_RID        ( Axi_RID           ) , //(O)[RdData]Read ID tag. This signal is the identification tag for the read data group of signals generated by the slave.
    .O_RRESP      ( Axi_RRESP         ) , //(O)[RdData]Read response. This signal indicates the status of the read transfer.
    .O_RLAST      ( Axi_RLAST         ) , //(O)[RdData]Read last. This signal indicates the last transfer in a read burst.
    .O_RVALID     ( Axi_RVALID        ) , //(O)[RdData]Read valid. This signal indicates that the channel is signaling the required read data.
    .I_RREADY     ( Axi_RREADY        ) , //(I)[RdData]Read ready. This signal indicates that the master can accept the read data and response information.
    .O_RDATA      ( Axi_RDATA         ) , //(O)[RdData]Read data.
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
`else
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
    .I_arw_valid            ( DdrCtrl_AVALID  ) , //(I)[Addres] Address Valid
    .O_arw_ready            ( DdrCtrl_AREADY  ) , //(O)[Addres] Address Ready
    .I_arw_payload_addr     ( DdrCtrl_AADDR   ) , //(I)[Addres] Address
    .I_arw_payload_id       ( DdrCtrl_AID     ) , //(I)[Addres] Address ID
    .I_arw_payload_len      ( DdrCtrl_ALEN    ) , //(I)[Addres] Address Brust Length
    .I_arw_payload_size     ( DdrCtrl_ASIZE   ) , //(I)[Addres] Address Burst size
    .I_arw_payload_burst    ( DdrCtrl_ABURST  ) , //(I)[Addres] Address Burst type
    .I_arw_payload_lock     ( DdrCtrl_ALOCK   ) , //(I)[Addres] Address Lock type
    .I_arw_payload_write    ( DdrCtrl_ATYPE   ) , //(I)[Addres] Operate Type 0=Read, 1=Write
    /////////////
    .I_w_payload_id         ( DdrCtrl_WID     ) , //(I)[Write]  ID
    .I_w_valid              ( DdrCtrl_WVALID  ) , //(I)[Write]  Data Valid
    .O_w_ready              ( DdrCtrl_WREADY  ) , //(O)[Write]  Data Ready
    .I_w_payload_data       ( DdrCtrl_WDATA   ) , //(I)[Write]  Data
    .I_w_payload_strb       ( DdrCtrl_WSTRB   ) , //(I)[Write]  Data Strobes(Byte valid)
    .I_w_payload_last       ( DdrCtrl_WLAST   ) , //(I)[Write]  Data Last
    /////////////
    .O_b_valid              ( DdrCtrl_BVALID  ) , //(O)[Answer] Response Ready
    .I_b_ready              ( DdrCtrl_BREADY  ) , //(I)[Answer] Response Write ID
    .O_b_payload_id         ( DdrCtrl_BID     ) , //(O)[Answer] Response valid
    /////////////
    .O_r_valid              ( DdrCtrl_RVALID  ) , //(O)[Read]   Data Valid
    .I_r_ready              ( DdrCtrl_RREADY  ) , //(I)[Read]   Data Ready
    .O_r_payload_data       ( DdrCtrl_RDATA   ) , //(O)[Read]   Data
    .O_r_payload_id         ( DdrCtrl_RID     ) , //(O)[Read]   ID
    .O_r_payload_resp       ( DdrCtrl_RRESP   ) , //(O)[Read]   Response
    .O_r_payload_last       ( DdrCtrl_RLAST   ) , //(O)[Read]   Data Last
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
`endif 
//&&&&&&&&&&&&&&&&&&&&&&&&&&&
    //calibration/Monitor Interface
    .O_Pll_Shift            ( Pll_Shift       ) , //Pll Shift Value
    .O_Pll_Shift_Sel        ( Pll_Shift_Sel   ) , //Pll Shift Channel Select
    .O_Pll_Shift_Ena        ( Pll_Shift_Ena   ) , //Pll Shift Enable  
    /////////////   
    .I_Cal_Enable           ( Cal_Enable      ) , //Calibration Enable
    .O_Cal_Done             ( Cal_Done        ) , //Calibration Done
    .O_Cal_Pass             ( Cal_Pass        ) , //Calibration Pass
    .O_Cal_Fail_Log         ( Cal_Fail_Log    ) , //Calibration Fail Log
    .O_Cal_Shift_Val        ( Cal_Shift_Val   ) , //Calibration Shift Value
    //Hyper Bus Ram Interface
    .Ddr_reset              ( reset           ) , //(O)DDR Reset
    .Ddr_cs                 ( cs              ) , //(O)DDR Chip Select
    .Ddr_ras                ( ras             ) , //(O)DDR Row Address Select
    .Ddr_cas                ( cas             ) , //(O)DDR Column aAddress Select
    .Ddr_we                 ( we              ) , //(O)DDR Write
    .Ddr_cke                ( cke             ) , //(O)DDR Clock Enable
    .Ddr_addr               ( addr            ) , //(O)DDR Address
    .Ddr_ba                 ( ba              ) , //(O)DDR Bank Address
    .Ddr_odt                ( odt             ) , //(O)DDR ODT
    .Ddr_o_dm_hi            ( o_dm_hi         ) , //(O)DDR Data Mask Output (HI)
    .Ddr_o_dm_lo            ( o_dm_lo         ) , //(O)DDR Data Mask Output (LO)
    .Ddr_i_dqs_hi           ( i_dqs_hi        ) , //(I)DDR DQS Input (HI) 
    .Ddr_i_dqs_lo           ( i_dqs_lo        ) , //(I)DDR DQS Input (LO) 
    .Ddr_i_dqs_n_hi         ( i_dqs_n_hi      ) , //(I)DDR DQS Input (HI)
    .Ddr_i_dqs_n_lo         ( i_dqs_n_lo      ) , //(I)DDR DQS Input (LO)
    .Ddr_o_dqs_hi           ( o_dqs_hi        ) , //(O)DDR DQS output 
    .Ddr_o_dqs_lo           ( o_dqs_lo        ) , //(O)DDR DQS output 
    .Ddr_o_dqs_n_hi         ( o_dqs_n_hi      ) , //(O)DDR DQS output 
    .Ddr_o_dqs_n_lo         ( o_dqs_n_lo      ) , //(O)DDR DQS output 
    .Ddr_o_dqs_oe           ( o_dqs_oe        ) , //(O)DDR DQS 
    .Ddr_o_dqs_n_oe         ( o_dqs_n_oe      ) , //(O)DDR DQS 
    .Ddr_i_dq_hi            ( i_dq_hi         ) , //(I)DDR DQ Input (HI)
    .Ddr_i_dq_lo            ( i_dq_lo         ) , //(I)DDR DQ Input (LO)
    .Ddr_o_dq_hi            ( o_dq_hi         ) , //(O)DDR DQ Data Input (HI)
    .Ddr_o_dq_lo            ( o_dq_lo         ) , //(O)DDR DQ Data Input (LO)
    .Ddr_o_dq_oe            ( o_dq_oe         )   //(O)DDR DQ Data Output Enable
  );

  /////////////////////////////////////////////////////////
  always @( posedge Sys_Clk)    Ddr_Ready        <=  Cal_Pass & Cal_Done & Sys_Rst_N;
  
  /////////////////////////////////////////////////////////
  wire  [2:0]   shift       = Pll_Shift       ;                                                   
  wire  [4:0]   shift_sel   = Pll_Shift_Sel   ;                                                       
  wire          shift_ena   = Pll_Shift_Ena   ;      
  wire          cal_done    = Cal_Done        ;                                                      
  wire          cal_pass    = Cal_Pass        ;     

  wire          pass        = 1'h0            ;                                                  
  wire          done        = 1'h0            ;         

  /////////////////////////////////////////////////////////
  assign   Cal_Enable   = 1'h1  ;

  /////////////////////////////////////////////////////////
//333333333333333333333333333333333333333333333333333333333

//444444444444444444444444444444444444444444444444444444444
//
//********************************************************/
  /////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////

//444444444444444444444444444444444444444444444444444444444

///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////


`ifdef  Efinity_Debug  //&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

  /////////////////////////////////////////////////////////
    wire  Axi_clk  = Sys_Clk  ;

    reg             Axi_AVALID          =  1'h0 ;
    reg             Axi_AREADY          =  1'h0 ;
    reg             Axi_ATYPE           =  1'h0 ;
    reg   [ 7:0]    Axi_ALEN            =  8'h0 ;
    reg             Axi_WVALID          =  1'h0 ;
    reg             Axi_WREADY          =  1'h0 ;
    reg             Axi_BVALID          =  1'h0 ;
    reg             Axi_BREADY          =  1'h0 ;
    reg             Axi_RVALID          =  1'h0 ;
    reg             Axi_RREADY          =  1'h0 ;
    reg             Axi_WLAST           =  1'h0 ;
    reg             Axi_RLAST           =  1'h0 ;
    reg   [31:0]    Axi_AADDR           = 32'h0 ;
                                     
    reg             Axi_WrEn            =  1'h0 ;
    reg   [31:0]    Axi_WrAddr          = 32'h0 ;
    reg   [31:0]    Axi_WDATA__31___0   = 32'h0 ;
    reg   [31:0]    Axi_WDATA__63__32   = 32'h0 ;
    reg   [31:0]    Axi_WDATA__95__64   = 32'h0 ;
    reg   [31:0]    Axi_WDATA_127__96   = 32'h0 ;
    reg   [31:0]    Axi_WDATA_159_128   = 32'h0 ;
    reg   [31:0]    Axi_WDATA_191_160   = 32'h0 ;
    reg   [31:0]    Axi_WDATA_223_192   = 32'h0 ;
    reg   [31:0]    Axi_WDATA_255_224   = 32'h0 ;
                                        
    reg             Axi_RdAva           =  1'h0 ;
    reg   [31:0]    Axi_RdAddr          = 32'h0 ;
    reg   [31:0]    Axi_RDATA__31___0   = 32'h0 ;
    reg   [31:0]    Axi_RDATA__63__32   = 32'h0 ;
    reg   [31:0]    Axi_RDATA__95__64   = 32'h0 ;
    reg   [31:0]    Axi_RDATA_127__96   = 32'h0 ;
    reg   [31:0]    Axi_RDATA_159_128   = 32'h0 ;
    reg   [31:0]    Axi_RDATA_191_160   = 32'h0 ;
    reg   [31:0]    Axi_RDATA_223_192   = 32'h0 ;
    reg   [31:0]    Axi_RDATA_255_224   = 32'h0 ;
    
    reg             Axi_TestErr         =  1'h0 ;
    reg             Axi_WrDataMode      =  1'h0 ;
    reg             Axi_RdDataMode      =  1'h0 ;
    reg             Axi_TimeOut         =  1'h0 ;
    reg   [31:0]    Axi_WrStartA        = 32'h0 ;
    reg   [31:0]    Axi_RdStartA        = 32'h0 ;
    
    always @( posedge Axi_clk)    Axi_AVALID        <=  DdrCtrl_AVALID   ;
    always @( posedge Axi_clk)    Axi_AREADY        <=  DdrCtrl_AREADY   ;
    always @( posedge Axi_clk)    Axi_ATYPE         <=  DdrCtrl_ATYPE    ;
    always @( posedge Axi_clk)    Axi_ALEN          <=  DdrCtrl_ALEN     ;
    always @( posedge Axi_clk)    Axi_WVALID        <=  DdrCtrl_WVALID   ;
    always @( posedge Axi_clk)    Axi_WREADY        <=  DdrCtrl_WREADY   ;
    always @( posedge Axi_clk)    Axi_BVALID        <=  DdrCtrl_BVALID   ;
    always @( posedge Axi_clk)    Axi_BREADY        <=  DdrCtrl_BREADY   ;
    always @( posedge Axi_clk)    Axi_RVALID        <=  DdrCtrl_RVALID   ;
    always @( posedge Axi_clk)    Axi_RREADY        <=  DdrCtrl_RREADY   ;
    always @( posedge Axi_clk)    Axi_WLAST         <=  DdrCtrl_WLAST    ;
    always @( posedge Axi_clk)    Axi_RLAST         <=  DdrCtrl_RLAST    ;
    always @( posedge Axi_clk)    Axi_AADDR         <=  DdrCtrl_AADDR    ;    
                                                                               
    always @( posedge Axi_clk)    Axi_WrEn            <= AxiWrEn               ;
    always @( posedge Axi_clk)    Axi_WrAddr          <= AxiWrAddr             ;       
    always @( posedge Axi_clk)    Axi_WDATA__31___0   <= AxiWrData[ 31:  0]    ;
    always @( posedge Axi_clk)    Axi_WDATA__63__32   <= AxiWrData[ 63: 32]    ;
    always @( posedge Axi_clk)    Axi_WDATA__95__64   <= AxiWrData[ 95: 64]    ;
    always @( posedge Axi_clk)    Axi_WDATA_127__96   <= AxiWrData[127: 96]    ;
    always @( posedge Axi_clk)    Axi_WDATA_159_128   <= AxiWrData[159:128]    ;
    always @( posedge Axi_clk)    Axi_WDATA_191_160   <= AxiWrData[191:160]    ;
    always @( posedge Axi_clk)    Axi_WDATA_223_192   <= AxiWrData[223:192]    ;
    always @( posedge Axi_clk)    Axi_WDATA_255_224   <= AxiWrData[255:224]    ;

    always @( posedge Axi_clk)    Axi_RdAva           <= AxiRdAva              ;
    always @( posedge Axi_clk)    Axi_RdAddr          <= AxiRdAddr             ;    
    always @( posedge Axi_clk)    Axi_RDATA__31___0   <= AxiRdData[ 31:  0]    ;
    always @( posedge Axi_clk)    Axi_RDATA__63__32   <= AxiRdData[ 63: 32]    ;
    always @( posedge Axi_clk)    Axi_RDATA__95__64   <= AxiRdData[ 95: 64]    ;
    always @( posedge Axi_clk)    Axi_RDATA_127__96   <= AxiRdData[127: 96]    ;
    always @( posedge Axi_clk)    Axi_RDATA_159_128   <= AxiRdData[159:128]    ;
    always @( posedge Axi_clk)    Axi_RDATA_191_160   <= AxiRdData[191:160]    ;
    always @( posedge Axi_clk)    Axi_RDATA_223_192   <= AxiRdData[223:192]    ;
    always @( posedge Axi_clk)    Axi_RDATA_255_224   <= AxiRdData[255:224]    ;

    always @( * )                 Axi_TestErr         <= TestErr               ; 
    always @( posedge Axi_clk)    Axi_WrDataMode      <= AxiWrDMode            ; 
    always @( posedge Axi_clk)    Axi_RdDataMode      <= AxiRdDMode            ; 
    always @( posedge Axi_clk)    Axi_TimeOut         <= TimeOut               ; 

    always @( posedge Axi_clk)    Axi_WrStartA        <= AxiWrStartA           ;
    always @( posedge Axi_clk)    Axi_RdStartA        <= AxiRdStartA           ;
    
  /////////////////////////////////////////////////////////                                              
    wire  DdrTest_clk = Sys_Clk    ;
                                                                
    wire              DdrTest_TestBusy                = TestBusy  ;
    wire  [23:0]      DdrTest_TestErrCnt              = ErrCnt    ;
    wire              DdrTest_TestRight               = TestRight ;
    wire  [47:0]      DdrTest_Operate_Total_Cycle     = OpTotCyc  ;
    wire  [47:0]      DdrTest_Operate_Actual_Cycle    = OpActCyc  ;
    wire  [ 9:0]      DdrTest_Operate_Efficiency_ppt  = OpEffic   ;
    wire  [15:0]      DdrTest_BandWidth_Mbps          = BandWidth ;
    wire  [ 9:0]      DdrTest_WrPeriod_minimun_Cycle  = WrPeriMin ;
    wire  [ 9:0]      DdrTest_WrPeriod_Average_Cycle  = WrPeriAvg ;
    wire  [ 9:0]      DdrTest_WrPeriod_Maximum_Cycle  = WrPeriMax ;
    wire  [ 9:0]      DdrTest_RdPeriod_minimun_Cycle  = RdPeriMin ;
    wire  [ 9:0]      DdrTest_RdPeriod_Average_Cycle  = RdPeriAvg ;
    wire  [ 9:0]      DdrTest_RdPeriod_Maximum_Cycle  = RdPeriMax ;
    wire  [23:0]      DdrTest_Test_Time_second        = TestTime  ;
                                                      
    wire              DdrTest_DdrReset                ;
    wire  [ 1:0]      DdrTest_CfgDataMode             ;
    wire  [ 1:0]      DdrTest_CfgTestMode             ;
    wire  [ 7:0]      DdrTest_CfgBurstLen             ;
    wire  [31:0]      DdrTest_CfgStartAddr            ;
    wire  [31:0]      DdrTest_CfgEndAddr              ;
    wire  [31:0]      DdrTest_CfgTestLen              ;
    wire              DdrTest_TestStart               ;    
    
  edb_top edb_top_inst (
  ////////////////
    .bscan_CAPTURE        ( jtag_inst1_CAPTURE  ),
    .bscan_DRCK           ( jtag_inst1_DRCK     ),
    .bscan_RESET          ( jtag_inst1_RESET    ),
    .bscan_RUNTEST        ( jtag_inst1_RUNTEST  ),
    .bscan_SEL            ( jtag_inst1_SEL      ),
    .bscan_SHIFT          ( jtag_inst1_SHIFT    ),
    .bscan_TCK            ( jtag_inst1_TCK      ),
    .bscan_TDI            ( jtag_inst1_TDI      ),
    .bscan_TMS            ( jtag_inst1_TMS      ),
    .bscan_UPDATE         ( jtag_inst1_UPDATE   ),
    .bscan_TDO            ( jtag_inst1_TDO      ),
  ////////////////        
    .Axi_clk              ( Axi_clk             ),
    
    .Axi_AVALID           ( Axi_AVALID          ),
    .Axi_AREADY           ( Axi_AREADY          ),
    .Axi_ATYPE            ( Axi_ATYPE           ),
    .Axi_ALEN             ( Axi_ALEN            ),
    .Axi_WVALID           ( Axi_WVALID          ),
    .Axi_WREADY           ( Axi_WREADY          ),
    .Axi_BVALID           ( Axi_BVALID          ),
    .Axi_BREADY           ( Axi_BREADY          ),
    .Axi_RVALID           ( Axi_RVALID          ),
    .Axi_RREADY           ( Axi_RREADY          ),
    .Axi_WLAST            ( Axi_WLAST           ),
    .Axi_RLAST            ( Axi_RLAST           ),
    .Axi_AADDR            ( Axi_AADDR           ),
                                                
    .Axi_WrEn             ( Axi_WrEn            ),
    .Axi_WrAddr           ( Axi_WrAddr          ),
                                                
    .Axi_RdAva            ( Axi_RdAva           ),
    .Axi_RdAddr           ( Axi_RdAddr          ),
                                                
    .Axi_TestErr          ( Axi_TestErr         ),
    .Axi_WrDataMode       ( Axi_WrDataMode      ),
    .Axi_RdDataMode       ( Axi_RdDataMode      ),
    .Axi_TimeOut          ( Axi_TimeOut         ),
    .Axi_WrStartA         ( Axi_WrStartA        ),
    .Axi_RdStartA         ( Axi_RdStartA        ),
                                                
    .Axi_WDATA__31___0    ( Axi_WDATA__31___0   ),
    .Axi_WDATA__63__32    ( Axi_WDATA__63__32   ),
    .Axi_WDATA__95__64    ( Axi_WDATA__95__64   ),
    .Axi_WDATA_127__96    ( Axi_WDATA_127__96   ),
    .Axi_WDATA_159_128    ( Axi_WDATA_159_128   ),
    .Axi_WDATA_191_160    ( Axi_WDATA_191_160   ),
    .Axi_WDATA_223_192    ( Axi_WDATA_223_192   ),
    .Axi_WDATA_255_224    ( Axi_WDATA_255_224   ),
                                                
    .Axi_RDATA__31___0    ( Axi_RDATA__31___0   ),
    .Axi_RDATA__63__32    ( Axi_RDATA__63__32   ),
    .Axi_RDATA__95__64    ( Axi_RDATA__95__64   ),
    .Axi_RDATA_127__96    ( Axi_RDATA_127__96   ),
    .Axi_RDATA_159_128    ( Axi_RDATA_159_128   ),
    .Axi_RDATA_191_160    ( Axi_RDATA_191_160   ),
    .Axi_RDATA_223_192    ( Axi_RDATA_223_192   ),
    .Axi_RDATA_255_224    ( Axi_RDATA_255_224   ),
    
  ////////////////
    .DdrTest_clk                    ( DdrTest_clk                     ),
    
    .DdrTest_TestBusy               ( DdrTest_TestBusy                ),
    .DdrTest_TestErrCnt             ( DdrTest_TestErrCnt              ),
    .DdrTest_TestRight              ( DdrTest_TestRight               ),
    .DdrTest_Operate_Total_Cycle    ( DdrTest_Operate_Total_Cycle     ),
    .DdrTest_Operate_Actual_Cycle   ( DdrTest_Operate_Actual_Cycle    ),
    .DdrTest_Operate_Efficiency_ppt ( DdrTest_Operate_Efficiency_ppt  ),
    .DdrTest_BandWidth_Mbps         ( DdrTest_BandWidth_Mbps          ),
    .DdrTest_WrPeriod_minimun_Cycle ( DdrTest_WrPeriod_minimun_Cycle  ),
    .DdrTest_WrPeriod_Average_Cycle ( DdrTest_WrPeriod_Average_Cycle  ),
    .DdrTest_WrPeriod_Maximum_Cycle ( DdrTest_WrPeriod_Maximum_Cycle  ),
    .DdrTest_RdPeriod_minimun_Cycle ( DdrTest_RdPeriod_minimun_Cycle  ),
    .DdrTest_RdPeriod_Average_Cycle ( DdrTest_RdPeriod_Average_Cycle  ),
    .DdrTest_RdPeriod_Maximum_Cycle ( DdrTest_RdPeriod_Maximum_Cycle  ),
    .DdrTest_Test_Time_second       ( DdrTest_Test_Time_second        ),
    
    .DdrTest_DdrReset               ( DdrTest_DdrReset                ),
    .DdrTest_CfgDataMode            ( DdrTest_CfgDataMode             ),
    .DdrTest_CfgTestMode            ( DdrTest_CfgTestMode             ),
    .DdrTest_CfgBurstLen            ( DdrTest_CfgBurstLen             ),
    .DdrTest_CfgStartAddr           ( DdrTest_CfgStartAddr            ),
    .DdrTest_CfgEndAddr             ( DdrTest_CfgEndAddr              ),
    .DdrTest_CfgTestLen             ( DdrTest_CfgTestLen              ),
    .DdrTest_TestStart              ( DdrTest_TestStart               )
 );

                                              
  /////////////////////////////////////////////////////////
  
  assign  TestStart     = DdrTest_TestStart     ;
  assign  DdrResetCtrl  = DdrTest_DdrReset      ;
  assign  CfgDataMode   = DdrTest_CfgDataMode   ;
  assign  CfgTestMode   = DdrTest_CfgTestMode   ;
  assign  CfgBurstLen   = DdrTest_CfgBurstLen   ;
  assign  CfgStartAddr  = DdrTest_CfgStartAddr  ;
  assign  CfgEndAddr    = DdrTest_CfgEndAddr    ;
  assign  CfgTestLen    = DdrTest_CfgTestLen    ;

  assign  CfgDataSize   = 3'h4;
                                                     
`else //&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
  //Use Simulation
  /////////////////////////////////////////////////////////
  reg   TestBusyReg = 1'h0;
  reg   TestEndFlag = 1'h0;
  
  always @( posedge Sys_Clk)  TestBusyReg  <=  TestBusy;
  always @( posedge Sys_Clk)  TestEndFlag  <=  (~TestBusy)  & TestBusyReg;
  
  /////////////////////////////////////////////////////////
  reg  [3:0]  TestDlyCnt    = 4'h0;
  reg         TestStartFlag = 1'h0;
  
  always @( posedge Sys_Clk or negedge Ddr_Ready)  
  begin
    if (~Ddr_Ready)         TestDlyCnt <=  4'h0;
    else if (TestEndFlag)   TestDlyCnt <=  4'h0;
    else                    TestDlyCnt <=  TestDlyCnt + {3'h0,(~&TestDlyCnt)};
  end
  always @( posedge Sys_Clk) TestStartFlag <=  (TestDlyCnt == 4'hf);
  
  /////////////////////////////////////////////////////////
  reg [1:0] ModeSelCnt = 2'H3;
  
  always @( posedge Sys_Clk)  if (TestEndFlag)
  begin
    if (ModeSelCnt == 2'h1) ModeSelCnt <=2'h3;
    else                    ModeSelCnt <=ModeSelCnt - 2'h1;
  end
  
  /////////////////////////////////////////////////////////  
  assign  CfgTestMode   = Sim_CfgTestMode   ;
  assign  CfgBurstLen   = Sim_CfgBurstLen   ;
  assign  CfgDataSize   = Sim_CfgDataSize   ;
  assign  CfgTestLen    = Sim_CfgTestLen    ;
  assign  TestStart     = Sim_TestStart     ;

  assign  CfgDataMode   = Sim_CfgDataMode   ;
  assign  DdrResetCtrl  = 1'h0              ;
  assign  CfgStartAddr  = 32'h0             ;
  assign  CfgEndAddr    = 32'h1f_ff_ff      ;
  
  // assign  DdrResetCtrl  =  1'h0         ;
  // assign  CfgDataMode   =  2'h2         ;
  // assign  CfgTestMode   = ModeSelCnt    ;
  // assign  CfgBurstLen   =  8'Hf         ;
  // assign  CfgStartAddr  = 32'h0         ;
  // assign  CfgEndAddr    = 32'hff_ff_ff  ;
  // assign  CfgTestLen    = 32'h100       ;
  // assign  TestStart     = TestStartFlag ;

`endif  //&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

endmodule