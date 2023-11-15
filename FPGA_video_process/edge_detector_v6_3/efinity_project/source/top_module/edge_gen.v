module  edge_gen
(
    input   wire    sys_clk  ,
    input   wire    sys_rst_n,
    input   wire    inf_in   ,
    
    output  wire    rise_flag,
    output  wire    fall_flag
);

reg     inf_r1;
reg     inf_r2;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 0)
    begin
        inf_r1 <= 1'b1;
        inf_r2 <= 1'b1;
    end
    else
    begin
        inf_r1 <= inf_in;
        inf_r2 <= inf_r1;
    end

assign  rise_flag = ((inf_r1 == 1) && (inf_r2 == 0));
assign  fall_flag = ((inf_r1 == 0) && (inf_r2 == 1));




endmodule