// =====================================================
// =============== AXI4 Lite Slave Model ===============
// =====================================================
// Only model basic functionality such as write, write response, and read

module efx_custom_slave_model # (
    parameter CFG_DEPTH       = 64,
    parameter ID_WIDTH        = 8,
    parameter CFG_ADDR_WIDTH  = clog2(CFG_DEPTH)
) (
// =============== GLOBAL SIGNAL ==============================
    input  wire                    clk,
    input  wire                    rst_n,
// =============== SLAVE WRITE ADDRESS CHANNEL ================
    input  wire                    awvalid,
    input  wire [ID_WIDTH-1:0]     awid,
    input  wire [31:0]             awaddr,
    input  wire [7:0]              awlen,
    input  wire [2:0]              awprot,
    output wire                    awready,
// =============== SLAVE WRITE DATA CHANNEL ===================
    input  wire                    wvalid,
    input  wire                    wlast,
    input  wire [31:0]             wdata,
    input  wire [3:0]              wstrb,
    output wire                    wready,
// =============== SLAVE WRITE RESPONSE CHANNEL ===============
    input  wire                    bready,
    output wire [ID_WIDTH-1:0]     bid,
    output wire [1:0]              bresp,
    output reg                     bvalid,
// =============== SLAVE READ ADDRESS CHANNEL =================
    input  wire [31:0]             araddr,
    input  wire [2:0]              arprot,
    input  wire [ID_WIDTH-1:0]     arid,
    input  wire [7:0]              arlen,
    input  wire                    arvalid,
    output wire                    arready,
// =============== SLAVE READ DATA CHANNEL ====================
    input  wire                    rready,
    output wire [31:0]             rdata,
    output wire [1:0]              rresp,
    output wire [ID_WIDTH-1:0]     rid,
    output reg                     rlast,    
    output wire                    rvalid    
);

integer i;

reg [7:0]          awlen_hold;
reg [7:0]          arlen_hold;
reg [7:0]          read_count;
reg                arvalid_hold;
reg [ID_WIDTH-1:0] awid_hold;
reg [ID_WIDTH-1:0] arid_hold;

wire full;
wire rden;

assign awready    = 1'b1;
assign arready    = 1'b1;
assign rresp      = 2'b00;
assign rid        = {8{rvalid}} & arid_hold;
assign bresp      = 2'b00;
assign bid        = {8{bvalid}} & awid_hold;

// ======== Hold the AWLEN Signal ========
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        awlen_hold <= 1'b0;
        awid_hold  <= 1'b0;
    end
    else if (bready && bvalid) begin
        awlen_hold <= 1'b0;
        awid_hold  <= 1'b0;
    end
    else if (awready && awvalid) begin
        awlen_hold <= awlen;
        awid_hold  <= awid;
    end
end

// ======== Hold the ARLEN Signal ========
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        arlen_hold <= 1'b0;
        arid_hold  <= 1'b0;
    end
    else if (rready && rlast) begin
        arlen_hold <= 1'b0;
        arid_hold  <= 1'b0;
    end
    else if (arready && arvalid) begin
        arlen_hold <= arlen;
        arid_hold  <= arid;
    end
end

// ======== Hold the ARVALID Signal ========
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        arvalid_hold <= 1'b0;
    end
    else if (arready && arvalid) begin
        arvalid_hold <= arvalid;
    end
    else if (bvalid) begin
        arvalid_hold <= 1'b0;
    end
end

// ======== READ Tracking Counter ========
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        read_count <= 'd0;
    end
    else if (rlast) begin
        read_count <= 'd0;
    end
    else if (rready && arvalid_hold && read_count <= arlen_hold) begin
        read_count <= read_count + 1'd1;
    end
end

// ======== Hold the AWADDR Signal ========
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        rlast <= 'h0;
    end
    else if (rready && rlast) begin
        rlast <= 1'b0;
    end
    else if (rvalid && read_count == arlen_hold) begin
        rlast <= 1'b1;
    end
end


// ======== Hold the AWADDR Signal ========
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        bvalid <= 'h0;
    end
    else if (bready && bvalid) begin
        bvalid <= 1'b0;
    end
    else if (wready && wvalid && wlast) begin
        bvalid <= 1'b1;
    end
end

assign wready = ~full;
assign rden   = rready && arvalid_hold && (read_count <= arlen_hold);

efx_fifo_top # (
    .FAMILY             ("TITANIUM"),
    .SYNC_CLK           (0),
    .BYPASS_RESET_SYNC  (0),
    .MODE               ("STANDARD"),
    .DEPTH              (CFG_DEPTH),
    .DATA_WIDTH         (32),
    .PIPELINE_REG       (1),
    .OPTIONAL_FLAGS     (1),
    .OUTPUT_REG         (0),
    .PROGRAMMABLE_FULL  ("NONE"),
    .PROGRAMMABLE_EMPTY ("NONE"),
    .ASYM_WIDTH_RATIO   (4)
) wr_data_fifo (
    .a_rst_i            (~rst_n),
    .wr_clk_i           (clk),
    .rd_clk_i           (clk),
    .wr_en_i            (wvalid & wready),
    .rd_en_i            (rden),
    .wdata              (wdata),
    .full_o             (full),
    .empty_o            (),
    .almost_empty_o     (),
    .rd_valid_o         (rvalid),
    .rdata              (rdata)
);

function integer clog2;
    input integer value;
          integer temp;
    begin
        temp = value - 1;
        for (clog2 = 0; temp > 0; clog2 = clog2 + 1) begin
            temp = temp >> 1;
        end
    end
endfunction
endmodule
