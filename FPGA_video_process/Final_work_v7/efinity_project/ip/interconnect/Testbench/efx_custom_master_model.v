module efx_custom_master_model # (
    parameter ADDRESS_WIDTH     = 12,
    parameter DATA_OFFSET       = 0,
    parameter BURST_LEN         = 128,
    parameter ID_WIDTH          = 8,
    parameter USER_WIDTH        = 3
) (
    input  wire                     start_op,
// =============== GLOBAL SIGNAL ==============================
    input  wire                     clk,
    input  wire                     rst_n,
// =============== SLAVE WRITE ADDRESS CHANNEL ================
    input   wire                    awready,
    output  reg                     awvalid,
    output  reg  [31:0]             awaddr,
    output  wire [2:0]              awprot, 	
    output  reg  [ID_WIDTH-1:0]     awid,
    output  wire [1:0]              awburst,
    output  wire [7:0]              awlen,
    output  wire [2:0]              awsize,
    output  wire [3:0]              awcache,
    output  wire [3:0]              awqos,
    output  wire [3:0]              awregion,
    output  wire [USER_WIDTH-1:0]   awuser,
// =============== SLAVE WRITE DATA CHANNEL ===================
    output  reg                     wvalid,
    output  wire                    wlast,
    output  wire [31:0]             wdata,
    output  wire [3:0]              wstrb,
    output  wire [USER_WIDTH-1:0]   wuser,
    input   wire                    wready,
// =============== SLAVE WRITE RESPONSE CHANNEL ===============
    output  wire                    bready,
    input   wire [ID_WIDTH-1:0]     bid,
    input   wire [1:0]              bresp,
    input   wire                    bvalid,
// =============== SLAVE READ ADDRESS CHANNEL =================
    output  reg  [31:0]             araddr,
    output  wire [2:0]              arprot,
    output  reg                     arvalid,
    input   wire                    arready,
    output  reg  [ID_WIDTH-1:0]     arid,
    output  wire [1:0]              arburst,
    output  wire [7:0]              arlen,
    output  wire [2:0]              arsize,
    output  wire [3:0]              arcache,
    output  wire [3:0]              arqos,
    output  wire [3:0]              arregion,
    output  wire [USER_WIDTH-1:0]   aruser,
// =============== SLAVE READ DATA CHANNEL ====================
    output  wire                    rready,
    input   wire [31:0]             rdata,
    input   wire [1:0]              rresp,
    input   wire                    rvalid,
    input   wire [ID_WIDTH-1:0]     rid, 
    input   wire                    rlast,
// =============== TC Failed ==================================
    output  reg                     tc_failed,
    output  wire                    tc_passed,
    output  reg                     tc_done
);

reg [3:0]                  state;
reg [3:0]                  next_state;
reg [9:0]                  wtrack_cnt;
reg [31:0]                 data_reg;
reg                        wvalid_int;
reg                        nxt_slave;
reg                        clr_addr;
reg [31:0]                 rdata_r;
reg                        rvalid_r;
reg [ADDRESS_WIDTH-1:0]    addr_gen;
reg [2:0]                  addr_offset;

wire cycle_hit;
wire all_slave_done;
wire wr_burst_hit;

parameter IDLE        = 0,
          PRE_WR_REQ  = 1,
          PRE_WR_ACK  = 2,
          WR_DATA_OP  = 3,
          WR_RESPONSE = 4,
          WCYCLE_DONE = 5,
          ALL_WR_DONE = 6,
          RD_REQ      = 7,          
          RD_ACK      = 8,          
          RD_VERIFY   = 9,          
          RCYCLE_DONE = 10,          
          ALL_RD_DONE = 11,
          OP_END      = 12;
          
assign bready   = 1'b1;

assign rready   = 1'b1;

assign awprot   = 3'b100;
//assign awid     = 'hAA;
assign awburst  = 2'b01;
assign awlen    = BURST_LEN-1;
assign awsize   = 3'h2;
assign awcache  = 4'd1;
assign awqos    = 4'd2;
assign awregion = 4'd3;
assign awuser   = 3'd5;

assign arprot   = 3'b101;
//assign arid     = 'h55;
assign arburst  = 2'b10;
assign arlen    = BURST_LEN-1;
assign arsize   = 3'h1;
assign arcache  = 4'h8;
assign arqos    = 4'h4;
assign arregion = 4'hC;
assign aruser   = 3'hA;

assign wuser    = 'h33;
assign wstrb    = {4{wvalid}} & 4'hf;

assign tc_passed = tc_done & ~tc_failed; 

always @ (posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        state <= 'd0;
    end
    else begin
        state <= next_state;
    end
end

always @ (*) begin
    case (state)
        IDLE        : begin if (start_op)                  next_state = PRE_WR_REQ;  else             next_state = PRE_WR_REQ;  end
        PRE_WR_REQ  : begin if (awready)                   next_state = WR_DATA_OP;  else             next_state = PRE_WR_REQ;  end
        PRE_WR_ACK  : begin if (awready)                   next_state = WR_DATA_OP;  else             next_state = PRE_WR_ACK;  end
        WR_DATA_OP  : begin if (wr_burst_hit)              next_state = WR_RESPONSE; else             next_state = WR_DATA_OP;  end
        WR_RESPONSE : begin if (bvalid)                    next_state = WCYCLE_DONE; else             next_state = WR_RESPONSE; end
        WCYCLE_DONE : begin if (all_slave_done)            next_state = ALL_WR_DONE; else             next_state = PRE_WR_REQ;  end 
        ALL_WR_DONE : begin                                next_state = RD_REQ;                                                 end
        RD_REQ      : begin if (arready)                   next_state = RD_VERIFY;   else             next_state = RD_ACK;      end
        RD_ACK      : begin if (arready)                   next_state = RD_VERIFY;   else             next_state = RD_ACK;      end
        RD_VERIFY   : begin if (rlast && rvalid && rready) next_state = RCYCLE_DONE; else             next_state = RD_VERIFY;   end
        RCYCLE_DONE : begin if (all_slave_done)            next_state = ALL_RD_DONE; else             next_state = RD_REQ;      end 
        ALL_RD_DONE : begin                                next_state = OP_END;                                                 end
        OP_END      : begin                                next_state = OP_END;                                                 end
        default     : begin                                next_state = IDLE;                                                   end
    endcase
end

always @ (*) begin
    awvalid    = 1'b0;
    wvalid_int = 1'b0;
    arvalid    = 1'b0;
    nxt_slave  = 1'b0;
    clr_addr   = 1'b0;
    tc_done    = 1'b0;
    case (state)
        PRE_WR_REQ  : begin awvalid    = 1'b1; end
        PRE_WR_ACK  : begin awvalid    = 1'b1; end
        WR_DATA_OP  : begin wvalid_int = 1'b1; end
        WR_RESPONSE : begin                    end
        WCYCLE_DONE : begin nxt_slave  = 1'b1; end
        ALL_WR_DONE : begin clr_addr   = 1'b1; end
        RD_REQ      : begin arvalid    = 1'b1; end
        RD_ACK      : begin arvalid    = 1'b1; end
        RD_VERIFY   : begin                    end
        RCYCLE_DONE : begin nxt_slave  = 1'b1; end 
        ALL_RD_DONE : begin clr_addr   = 1'b1; end
        OP_END      : begin tc_done    = 1'b1; end
        default     : begin                    end
    endcase
end

always @ (*) begin
    case (addr_offset)
        'd0 : begin awaddr = 'h00000000; araddr = 'h00000000; end
        'd1 : begin awaddr = 'h10000000; araddr = 'h10000000; end
        'd2 : begin awaddr = 'h11000000; araddr = 'h11000000; end
        'd3 : begin awaddr = 'h11100000; araddr = 'h11100000; end
        'd4 : begin awaddr = 'h20000000; araddr = 'h20000000; end
        'd5 : begin awaddr = 'h30000000; araddr = 'h30000000; end
        'd6 : begin awaddr = 'h40000000; araddr = 'h40000000; end
        'd7 : begin awaddr = 'h41000000; araddr = 'h41000000; end
    endcase
end

//assign awaddr         = awvalid ? {addr_offset,addr_gen} : 'd0;
//assign araddr         = arvalid ? {addr_offset,addr_gen} : 'd0;
assign wr_burst_hit   = (wtrack_cnt == BURST_LEN-2);
assign wlast          = (wtrack_cnt == BURST_LEN - 1);
assign all_slave_done = (addr_offset == 'd7);

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		addr_gen <= 'd0;
	end
	else if (clr_addr) begin
		addr_gen <= 'd0;
	end
	else begin
		addr_gen <= 'd0;
	end
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		addr_offset <= 'd0;
	end
	else if (clr_addr) begin
		addr_offset <= 'd0;
	end
	else if (nxt_slave) begin
		addr_offset <= addr_offset + 'd1;
	end
end
		
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        awid <= 'h55;
        arid <= 'hAA;
    end
    else if (bvalid && bready) begin
        awid <= awid ^ wdata[ID_WIDTH-1:0];
    end
    else if (rvalid && rready && rlast) begin
        arid <= arid ^ wdata[ID_WIDTH-1:0];
    end
end

always @ (posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        wtrack_cnt  <= 'd0;
    end
    else if (wlast && wready) begin
        wtrack_cnt  <= 'd0;
    end
    else if (wvalid && wready) begin
        wtrack_cnt  <= wtrack_cnt + 'd1;
    end
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		wvalid <= 'b0;
	end
	else begin
		wvalid <= wvalid_int;
	end
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		data_reg <= 'd0;
	end
	else if (clr_addr) begin
		data_reg <= 'd0;
	end
	else if (wvalid_int && wready || rvalid) begin
		data_reg <= data_reg + 1'd1;
	end
end

efx_crc32 crc32_inst(
    .clk     (clk),
    .reset_n (rst_n),
    .clear   (clr_addr),
    .crc_en  (wvalid_int | rvalid), 
    .data_in (data_reg),
    .crc_out (wdata)
);

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		rdata_r  <= 'h0;
		rvalid_r <= 1'b0;
	end
	else begin
		rdata_r  <= rdata;
		rvalid_r <= rvalid;
	end
end

wire bid_mismatch;
wire rid_mismatch;

assign bid_mismatch = (bvalid & bready)? (awid != bid) : 1'b0;
assign rd_mismatch  = rvalid_r ? (rdata_r != wdata) : 1'b0;
assign rid_mismatch = (rvalid & rready)? (arid != rid) : 1'b0;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		tc_failed  <= 1'b0;
	end
	else if (rd_mismatch || bid_mismatch || rid_mismatch) begin
		tc_failed  <= 1'b1;
	end
end
endmodule
