
module uart_parse(
input		wire				clk,
input		wire				rst_n,

input		wire				rx_valid,
input		wire	[7:0]	rx_data,

output	reg					tx_valid,
output	reg		[7:0] tx_data,
input		wire				tx_req,
output	reg		[15:0] packet_end,
output	reg		[31:0]  ctrl_time,    
output	reg						time_valid,
output  reg		[199:0] ctrl_io,
output  reg						io_valid
 
);

	 
	localparam PKT_HD0 	= 3'd0;
	localparam PKT_HD1 	= 3'd1;
	localparam RX_DATA 	= 3'd2;
	localparam PKT_END0 = 3'd3;
	localparam PKT_END1 = 3'd4;
	localparam WR_RAM		= 3'd5;
	
	localparam TIME_OUT_COUNT = 24'h2932E0;
	reg [2:0] state = PKT_HD0;

	reg	[215:0]	rx_data1 = 0;
	
	reg	[23:0] time_out_cnt  = 0;
	reg				 time_out = 1'b0;
	reg				 time_out_en = 1'b0;

	reg [3:0] packet_type = 'd0;
	reg	[4:0] data_num = 'd0;
	reg [4:0] data_cnt = 'd0;
	
	always @( posedge clk or negedge rst_n)
	begin
		if( ~rst_n ) begin
				state <= PKT_HD0;
		end else if(time_out ) begin
				state <= PKT_HD0;
		end else begin
			
			case( state )  
			PKT_HD0 : begin 					
					if( rx_valid && rx_data == 8'd0 ) begin//���յ�ַ
							state <= PKT_HD1;
					end 
			end
			PKT_HD1 : begin//��������0
					if( rx_valid && rx_data[7:4] == 4'hf) begin
							packet_type <= rx_data[3:0];
							state <= RX_DATA;
					end 
			end
			RX_DATA : begin//��������1
					if( rx_valid ) begin						
						if( data_cnt == data_num-1 ) begin
								state <= PKT_END0;
								data_cnt <= 'd0;
						end else begin
								data_cnt <= data_cnt + 1'b1;
						end 
					end
			end
			PKT_END0 : begin
					if( rx_valid && rx_data == 8'hff ) begin
							packet_end[7:0] <= rx_data;
							state <= PKT_END1;
					end 
			end 
			PKT_END1 : begin
					if( rx_valid  && rx_data == 8'h00) begin//recevie FF
								state <= WR_RAM;
								packet_end[15:8] <= rx_data;
					end 
			end
			WR_RAM : begin
					state <= PKT_HD0;
			end	
			default: begin
				state <= PKT_HD0;
			end	
			endcase       
		end             
			
	end   
	
	always @( posedge clk )
	begin
			tx_data <= rx_data;
			tx_valid <= rx_valid;
	end 
	
		always @( posedge clk or negedge rst_n )
	begin
			if( !rst_n ) data_num <= 'd0;
			else if(PKT_HD1 == state && rx_valid ) begin		
					case(rx_data[3:0])	
						4'd0 : data_num <= 4;
						4'd1 : data_num <= 27;
						default: data_num <= 4;
					endcase
			end 
	end 
	
	always @( posedge clk )
	begin
			if( state != PKT_HD0 ) begin
					if( rx_valid ) time_out_en <= 1'b0;
					else 					 time_out_en <= 1'b1;
					
			end else begin
					time_out_en <= 1'b0;
			end 
			
	end 
	always @( posedge clk )
	begin
			if(time_out_en ) begin
					if( time_out_cnt == TIME_OUT_COUNT-1 ) begin
							time_out <= 1'b1;
					end else begin
							time_out_cnt <= time_out_cnt + 1'b1;
							time_out <= 1'b0;
					end	
			end else begin
					time_out_cnt <= 0;
					time_out <= 1'b0;
			end	
	end
	
	always @( posedge clk )
	begin
			if( state == RX_DATA && rx_valid )
						rx_data1 <= {rx_data,rx_data1[215:8]};   
	end  
	
	always @( posedge clk )
	begin
			if(WR_RAM == state ) begin
					case(packet_type[3:0])	
						4'd0 : begin ctrl_time <= rx_data1[215:184]; time_valid <= 1'b1; end 
						4'd1 : begin ctrl_io 	 <= rx_data1[199:0] ; io_valid <= 1'b1; end 
						default: ;
					endcase
			end else begin                              
					time_valid <= 1'b0;
					io_valid <= 1'b0;
			end 
			
	end       
                      


	
		
endmodule