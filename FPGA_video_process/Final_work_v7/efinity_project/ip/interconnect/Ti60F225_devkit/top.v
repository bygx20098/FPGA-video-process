module top (
    input  wire pll_clkout,
    input  wire rst_n,
    output wire pll_inst1_RSTN,
    output wire test_fail,
    output wire test_pass,
    output wire test_done
);

localparam S_PORTS    = 1;
localparam M_PORTS    = 8;
localparam ADDR_WIDTH = 32;
localparam DATA_WIDTH = 32;
localparam ID_WIDTH   = 8;
localparam USER_WIDTH = 3;
localparam STRB_WIDTH = 32/8;
localparam DATA_BL    = 128;

wire [S_PORTS-1:0]             s_axi_awvalid_int;
wire [S_PORTS-1:0]             s_axi_arvalid_int;

wire [S_PORTS-1:0]             s_axi_awvalid;
wire [S_PORTS*ID_WIDTH-1:0]    s_axi_awid;
wire [S_PORTS*2-1:0]           s_axi_awburst;
wire [S_PORTS*8-1:0]           s_axi_awlen;
wire [S_PORTS*3-1:0]           s_axi_awsize;
wire [S_PORTS*4-1:0]           s_axi_awcache;
wire [S_PORTS*4-1:0]           s_axi_awqos;
wire [S_PORTS*4-1:0]           s_axi_awregion;
wire [S_PORTS*USER_WIDTH-1:0]  s_axi_awuser;
wire [S_PORTS*ADDR_WIDTH-1:0]  s_axi_awaddr;
wire [S_PORTS*3-1:0]           s_axi_awprot;
wire [S_PORTS-1:0]             s_axi_awready;
// =============== SLAVE WRITE DATA CHANNEL ===================
wire [S_PORTS-1:0]             s_axi_wvalid;
wire [S_PORTS*DATA_WIDTH-1:0]  s_axi_wdata;
wire [S_PORTS*STRB_WIDTH-1:0]  s_axi_wstrb;
wire [S_PORTS-1:0]             s_axi_wlast;
wire [S_PORTS*USER_WIDTH-1:0]  s_axi_wuser;
wire [S_PORTS-1:0]             s_axi_wready;
// =============== SLAVE WRITE RESPONSE CHANNEL ===============
wire [S_PORTS-1:0]             s_axi_bready;
wire [S_PORTS*2-1:0]           s_axi_bresp;
wire [S_PORTS-1:0]             s_axi_bvalid;
wire [S_PORTS*ID_WIDTH-1:0]    s_axi_bid;
wire [S_PORTS*USER_WIDTH-1:0]  s_axi_buser;
// =============== SLAVE READ ADDRESS CHANNEL =================
wire [S_PORTS-1:0]             s_axi_arvalid;
wire [S_PORTS*ID_WIDTH-1:0]    s_axi_arid;
wire [S_PORTS*2-1:0]           s_axi_arburst;
wire [S_PORTS*8-1:0]           s_axi_arlen;
wire [S_PORTS*3-1:0]           s_axi_arsize;
wire [S_PORTS*4-1:0]           s_axi_arcache;
wire [S_PORTS*4-1:0]           s_axi_arqos;
wire [S_PORTS*4-1:0]           s_axi_arwireion;
wire [S_PORTS*USER_WIDTH-1:0]  s_axi_aruser;
wire [S_PORTS*ADDR_WIDTH-1:0]  s_axi_araddr;
wire [S_PORTS*3-1:0]           s_axi_arprot;
wire [S_PORTS-1:0]             s_axi_arready;
// =============== SLAVE READ DATA CHANNEL ====================
wire [S_PORTS-1:0]             s_axi_rready;
wire [S_PORTS*ID_WIDTH-1:0]    s_axi_rid;
wire [S_PORTS*DATA_WIDTH-1:0]  s_axi_rdata;
wire [S_PORTS*2-1:0]           s_axi_rresp;
wire [S_PORTS-1:0]             s_axi_rvalid;
wire [S_PORTS-1:0]             s_axi_rlast;
wire [S_PORTS*USER_WIDTH-1:0]  s_axi_ruser;
// =============== MASTER WRITE ADDRESS CHANNEL ===============
wire [M_PORTS-1:0]             m_axi_awvalid;
wire [M_PORTS*ID_WIDTH-1:0]    m_axi_awid;
wire [M_PORTS*2-1:0]           m_axi_awburst;
wire [M_PORTS*8-1:0]           m_axi_awlen;
wire [M_PORTS*3-1:0]           m_axi_awsize;
wire [M_PORTS*4-1:0]           m_axi_awcache;
wire [M_PORTS*4-1:0]           m_axi_awqos;
wire [M_PORTS*4-1:0]           m_axi_awregion;
wire [M_PORTS*USER_WIDTH-1:0]  m_axi_awuser;
wire [M_PORTS*ADDR_WIDTH-1:0]  m_axi_awaddr;
wire [M_PORTS*3-1:0]           m_axi_awprot;
wire [M_PORTS-1:0]             m_axi_awready;
// =============== MASTER WRITE DATA CHANNEL ==================
wire [M_PORTS*DATA_WIDTH-1:0]  m_axi_wdata;
wire [M_PORTS*STRB_WIDTH-1:0]  m_axi_wstrb;
wire [M_PORTS-1:0]             m_axi_wvalid;
wire [M_PORTS-1:0]             m_axi_wlast;
wire [M_PORTS*USER_WIDTH-1:0]  m_axi_wuser;
wire [M_PORTS-1:0]             m_axi_wready;
// =============== MASTER WRITE RESPONSE CHANNEL ==============
wire [M_PORTS*2-1:0]           m_axi_bresp;
wire [M_PORTS-1:0]             m_axi_bvalid;
wire [M_PORTS*ID_WIDTH-1:0]    m_axi_bid;
wire [M_PORTS*USER_WIDTH-1:0]  m_axi_buser;
wire [M_PORTS-1:0]             m_axi_bready;
// =============== MASTER READ ADDRESS CHANNEL ================
wire [M_PORTS-1:0]             m_axi_arvalid;
wire [M_PORTS*ID_WIDTH-1:0]    m_axi_arid;
wire [M_PORTS*2-1:0]           m_axi_arburst;
wire [M_PORTS*8-1:0]           m_axi_arlen;
wire [M_PORTS*3-1:0]           m_axi_arsize;
wire [M_PORTS*4-1:0]           m_axi_arcache;
wire [M_PORTS*4-1:0]           m_axi_arqos;
wire [M_PORTS*4-1:0]           m_axi_arregion;
wire [M_PORTS*USER_WIDTH-1:0]  m_axi_aruser;
wire [M_PORTS*ADDR_WIDTH-1:0]  m_axi_araddr;
wire [M_PORTS*3-1:0]           m_axi_arprot;
wire [M_PORTS-1:0]             m_axi_arready;
// =============== MASTER READ DATA CHANNEL ===================
wire [M_PORTS*ID_WIDTH-1:0]    m_axi_rid;
wire [M_PORTS*DATA_WIDTH-1:0]  m_axi_rdata;
wire [M_PORTS*2-1:0]           m_axi_rresp;
wire [M_PORTS-1:0]             m_axi_rvalid;
wire [M_PORTS-1:0]             m_axi_rlast;
wire [M_PORTS*USER_WIDTH-1:0]  m_axi_ruser;
wire [M_PORTS-1:0]             m_axi_rready;

assign s_axi_awvalid_int = s_axi_awvalid;
assign s_axi_arvalid_int = s_axi_arvalid;
assign pll_inst1_RSTN    = 1'b1;

interconnect efx_axi_interconnect_inst (
    .clk            (pll_clkout),
    .rst_n          (rst_n),
// =============== SLAVE WRITE ADDRESS CHANNEL ================
    .s_axi_awvalid  (s_axi_awvalid_int),
    .s_axi_awaddr   (s_axi_awaddr),
    .s_axi_awprot   (s_axi_awprot),
    .s_axi_awready  (s_axi_awready),
    .s_axi_awid     (s_axi_awid),
    .s_axi_awburst  (s_axi_awburst),
    .s_axi_awlen    (s_axi_awlen),
    .s_axi_awsize   (s_axi_awsize),
    .s_axi_awcache  (s_axi_awcache),
    .s_axi_awqos    (s_axi_awqos),
    .s_axi_awuser   (s_axi_awuser),
// =============== SLAVE WRITE DATA CHANNEL ===================
    .s_axi_wvalid   (s_axi_wvalid),
    .s_axi_wdata    (s_axi_wdata),
    .s_axi_wstrb    (s_axi_wstrb),
    .s_axi_wready   (s_axi_wready),
    .s_axi_wlast    (s_axi_wlast),
    .s_axi_wuser    (s_axi_wuser),
// =============== SLAVE WRITE RESPONSE CHANNEL ===============
    .s_axi_bready   (s_axi_bready),
    .s_axi_bid      (s_axi_bid),
    .s_axi_bresp    (s_axi_bresp),
    .s_axi_bvalid   (s_axi_bvalid),
// =============== SLAVE READ ADDRESS CHANNEL =================
    .s_axi_arvalid  (s_axi_arvalid_int),
    .s_axi_araddr   (s_axi_araddr),
    .s_axi_arprot   (s_axi_arprot),
    .s_axi_arready  (s_axi_arready),
    .s_axi_arid     (s_axi_arid),
    .s_axi_arburst  (s_axi_arburst),
    .s_axi_arlen    (s_axi_arlen),
    .s_axi_arsize   (s_axi_arsize),
    .s_axi_arcache  (s_axi_arcache),
    .s_axi_arqos    (s_axi_arqos),
    .s_axi_aruser   (s_axi_aruser),
// =============== SLAVE READ DATA CHANNEL ====================
    .s_axi_rready   (s_axi_rready),
    .s_axi_rdata    (s_axi_rdata),
    .s_axi_rid      (s_axi_rid),
    .s_axi_rresp    (s_axi_rresp),
    .s_axi_rvalid   (s_axi_rvalid),
    .s_axi_rlast    (s_axi_rlast),
// =============== MASTER WRITE ADDRESS CHANNEL ===============
    .m_axi_awready  (m_axi_awready),
    .m_axi_awaddr   (m_axi_awaddr),
    .m_axi_awprot   (m_axi_awprot),
    .m_axi_awvalid  (m_axi_awvalid),
    .m_axi_awid     (m_axi_awid),
    .m_axi_awburst  (m_axi_awburst),
    .m_axi_awlen    (m_axi_awlen),
    .m_axi_awsize   (m_axi_awsize),
    .m_axi_awcache  (m_axi_awcache),
    .m_axi_awqos    (m_axi_awqos),
    .m_axi_awregion (m_axi_awregion),
    .m_axi_awuser   (m_axi_awuser),
// =============== MASTER WRITE DATA CHANNEL ==================
    .m_axi_wdata    (m_axi_wdata),
    .m_axi_wstrb    (m_axi_wstrb),
    .m_axi_wvalid   (m_axi_wvalid),
    .m_axi_wready   (m_axi_wready),
    .m_axi_wlast    (m_axi_wlast),
// =============== MASTER WRITE RESPONSE CHANNEL ==============
    .m_axi_bid      (m_axi_bid),
    .m_axi_buser    (m_axi_buser),
    .m_axi_bresp    (m_axi_bresp),
    .m_axi_bvalid   (m_axi_bvalid),
    .m_axi_bready   (m_axi_bready),
// =============== MASTER READ ADDRESS CHANNEL ================
    .m_axi_araddr   (m_axi_araddr),
    .m_axi_arprot   (m_axi_arprot),
    .m_axi_arvalid  (m_axi_arvalid),
    .m_axi_arready  (m_axi_arready),
    .m_axi_arid     (m_axi_arid),
    .m_axi_arburst  (m_axi_arburst),
    .m_axi_arlen    (m_axi_arlen),
    .m_axi_arsize   (m_axi_arsize),
    .m_axi_arcache  (m_axi_arcache),
    .m_axi_arqos    (m_axi_arqos),
    .m_axi_arregion (m_axi_arregion),
    .m_axi_aruser   (m_axi_aruser),
// =============== MASTER READ DATA CHANNEL ===================
    .m_axi_rid      (m_axi_rid),
    .m_axi_rdata    (m_axi_rdata),
    .m_axi_rresp    (m_axi_rresp),
    .m_axi_rlast    (m_axi_rlast),
    .m_axi_rvalid   (m_axi_rvalid),
    .m_axi_rready   (m_axi_rready)
);

genvar i;
generate
    for (i=0;i<S_PORTS;i=i+1) begin
        efx_custom_master_model # (
            .BURST_LEN (DATA_BL)
        ) master (
            .start_op (rst_n),
        // =============== GLOBAL SIGNAL ==============================
            .clk     (pll_clkout),
            .rst_n   (rst_n),
        // =============== SLAVE WRITE ADDRESS CHANNEL ================
            .awvalid (s_axi_awvalid[i]),
            .awaddr  (s_axi_awaddr[i*ADDR_WIDTH+:ADDR_WIDTH]),
            .awprot  (s_axi_awprot[i*3+:3]),
            .awready (s_axi_awready[i]),
            .awid    (s_axi_awid[i*ID_WIDTH+:ID_WIDTH]),
            .awburst (s_axi_awburst[i*2+:2]),
            .awlen   (s_axi_awlen[i*8+:8]),
            .awsize  (s_axi_awsize[i*3+:3]),
            .awcache (s_axi_awcache[i*4+:4]),
            .awqos   (s_axi_awqos[i*4+:4]),
            .awuser  (s_axi_awuser[i*USER_WIDTH+:USER_WIDTH]),
        // =============== SLAVE WRITE DATA CHANNEL ===================
            .wvalid  (s_axi_wvalid[i]),
            .wlast   (s_axi_wlast[i]),
            .wdata   (s_axi_wdata[i*DATA_WIDTH+:DATA_WIDTH]),
            .wstrb   (s_axi_wstrb[i*STRB_WIDTH+:STRB_WIDTH]),
            .wready  (s_axi_wready[i]),
            .wuser   (s_axi_wuser[i*USER_WIDTH+:USER_WIDTH]),
        // =============== SLAVE WRITE RESPONSE CHANNEL ===============
            .bready  (s_axi_bready[i]),
            .bid     (s_axi_bid[i*ID_WIDTH+:ID_WIDTH]),
            .bresp   (s_axi_bresp[i*2+:2]),
            .bvalid  (s_axi_bvalid[i]),
        // =============== SLAVE READ ADDRESS CHANNEL =================
            .araddr  (s_axi_araddr[i*ADDR_WIDTH+:ADDR_WIDTH]),
            .arprot  (s_axi_arprot[i*3+:3]),
            .arvalid (s_axi_arvalid[i]),
            .arready (s_axi_arready[i]),
            .arid    (s_axi_arid[i*ID_WIDTH+:ID_WIDTH]),
            .arburst (s_axi_arburst[i*2+:2]),
            .arlen   (s_axi_arlen[i*8+:8]),
            .arsize  (s_axi_arsize[i*3+:3]),
            .arcache (s_axi_arcache[i*4+:4]),
            .arqos   (s_axi_arqos[i*4+:4]),
            .aruser  (s_axi_aruser[i*USER_WIDTH+:USER_WIDTH]),
        // =============== SLAVE READ DATA CHANNEL ====================
            .rready  (s_axi_rready[i]),
            .rdata   (s_axi_rdata[i*DATA_WIDTH+:DATA_WIDTH]),
            .rid     (s_axi_rid[i*ID_WIDTH+:ID_WIDTH]),
            .rresp   (s_axi_rresp[i*2+:2]),
            .rvalid  (s_axi_rvalid[i]), 
            .rlast   (s_axi_rlast[i]), 
        // =============== TEST STATUS SIGNAL =========================
            .tc_done   (test_done), 
            .tc_passed (test_pass), 
            .tc_failed (test_fail) 
        );
    end
endgenerate

generate
    for (i=0;i<M_PORTS;i=i+1) begin
        efx_custom_slave_model # (
            .CFG_DEPTH (DATA_BL),
            .ID_WIDTH  (ID_WIDTH)
        ) slave (
        // =============== GLOBAL SIGNAL ==============================
            .clk     (pll_clkout),
            .rst_n   (rst_n),
        // =============== SLAVE WRITE ADDRESS CHANNEL ================
            .awvalid (m_axi_awvalid[i]),
            .awid    (m_axi_awid[i*ID_WIDTH+:ID_WIDTH]),
            .awaddr  (m_axi_awaddr[i*ADDR_WIDTH+:ADDR_WIDTH]),
            .awprot  (m_axi_awprot[i*3+:3]),
            .awlen   (m_axi_awlen[i*8+:8]),
            .awready (m_axi_awready[i]),
        // =============== SLAVE WRITE DATA CHANNEL ===================
            .wvalid  (m_axi_wvalid[i]),
            .wdata   (m_axi_wdata[i*DATA_WIDTH+:DATA_WIDTH]),
            .wstrb   (m_axi_wstrb[i*STRB_WIDTH+:STRB_WIDTH]),
            .wlast   (m_axi_wlast[i]),
            .wready  (m_axi_wready[i]),
        // =============== SLAVE WRITE RESPONSE CHANNEL ===============
            .bready  (m_axi_bready[i]),
            .bid     (m_axi_bid[i*ID_WIDTH+:ID_WIDTH]),
            .bresp   (m_axi_bresp[i*2+:2]),
            .bvalid  (m_axi_bvalid[i]),
        // =============== SLAVE READ ADDRESS CHANNEL =================
            .araddr  (m_axi_araddr[i*ADDR_WIDTH+:ADDR_WIDTH]),
            .arid    (m_axi_arid[i*ID_WIDTH+:ID_WIDTH]),
            .arprot  (m_axi_arprot[i*3+:3]),
            .arlen   (m_axi_arlen[i*8+:8]),
            .arvalid (m_axi_arvalid[i]),
            .arready (m_axi_arready[i]),
        // =============== SLAVE READ DATA CHANNEL ====================
            .rready  (m_axi_rready[i]),
            .rid     (m_axi_rid[i*ID_WIDTH+:ID_WIDTH]),
            .rdata   (m_axi_rdata[i*DATA_WIDTH+:DATA_WIDTH]),
            .rresp   (m_axi_rresp[i*2+:2]),
            .rlast   (m_axi_rlast[i]),
            .rvalid  (m_axi_rvalid[i])  
        );
    end
endgenerate
endmodule
