module Median_filter
    (
    input   clk,    //cmos 像素时钟
    input   rst_n,  
    //预处理数据
    input       per_frame_vsync, 
    input       per_frame_href,  
    input       per_frame_de, 
    input [7:0] per_img_Y,       
    //处理后的数据
    output      post_img_vsync, 
    output      post_img_href ,  
    output      post_img_de   , 
    output [7:0] post_img_gray    
);

//wire define 
wire        matrix_img_vsync; 
wire        matrix_img_href;  
wire        matrix_img_de; 

//输出3X3 矩阵
wire [7:0]  matrix_p11; 
wire [7:0]  matrix_p12; 
wire [7:0]  matrix_p13; 
wire [7:0]  matrix_p21; 
wire [7:0]  matrix_p22; 
wire [7:0]  matrix_p23;
wire [7:0]  matrix_p31; 
wire [7:0]  matrix_p32; 
wire [7:0]  matrix_p33;


//3x3矩阵
VIP_Matrix_Generate_3X3_8Bit u_VIP_Matrix_Generate_3X3_8Bit(
    .clk  (clk),    
    .rst_n  (rst_n),
    //预处理数据
    .per_frame_vsync (per_frame_vsync), 
    .per_frame_href  (per_frame_href),  
    .per_frame_clken (per_frame_de), 
    .per_img_Y       (per_img_Y),       
    
    //处理后的数据
    .matrix_frame_vsync (matrix_img_vsync), 
    .matrix_frame_href  (matrix_img_href),  
    .matrix_frame_clken (matrix_img_de), 
    .matrix_p11         (matrix_p11), 
    .matrix_p12         (matrix_p12), 
    .matrix_p13         (matrix_p13), //输出 3X3 矩阵
    .matrix_p21         (matrix_p21), 
    .matrix_p22         (matrix_p22),  
    .matrix_p23         (matrix_p23),
    .matrix_p31         (matrix_p31), 
    .matrix_p32         (matrix_p32),  
    .matrix_p33         (matrix_p33)
);

reg             [7:0]           row1_min_data;
reg             [7:0]           row1_med_data;
reg             [7:0]           row1_max_data;

always @(posedge clk)
begin
    if((matrix_p11 <= matrix_p12)&&(matrix_p11 <= matrix_p13))
        row1_min_data <= matrix_p11;
    else if((matrix_p12 <= matrix_p11)&&(matrix_p12 <= matrix_p13))
        row1_min_data <= matrix_p12;
    else
        row1_min_data <= matrix_p13;
end

always @(posedge clk)
begin
    if((matrix_p11 <= matrix_p12)&&(matrix_p11 >= matrix_p13)||(matrix_p11 >= matrix_p12)&&(matrix_p11 <= matrix_p13))
        row1_med_data <= matrix_p11;
    else if((matrix_p12 <= matrix_p11)&&(matrix_p12 >= matrix_p13)||(matrix_p12 >= matrix_p11)&&(matrix_p12 <= matrix_p13))
        row1_med_data <= matrix_p12;
    else
        row1_med_data <= matrix_p13;
end

always @(posedge clk)
begin
    if((matrix_p11 >= matrix_p12)&&(matrix_p11 >= matrix_p13))
        row1_max_data <= matrix_p11;
    else if((matrix_p12 >= matrix_p11)&&(matrix_p12 >= matrix_p13))
        row1_max_data <= matrix_p12;
    else
        row1_max_data <= matrix_p13;
end

reg             [7:0]           row2_min_data;
reg             [7:0]           row2_med_data;
reg             [7:0]           row2_max_data;

always @(posedge clk)
begin
    if((matrix_p21 <= matrix_p22)&&(matrix_p21 <= matrix_p23))
        row2_min_data <= matrix_p21;
    else if((matrix_p22 <= matrix_p21)&&(matrix_p22 <= matrix_p23))
        row2_min_data <= matrix_p22;
    else
        row2_min_data <= matrix_p23;
end

always @(posedge clk)
begin
    if((matrix_p21 <= matrix_p22)&&(matrix_p21 >= matrix_p23)||(matrix_p21 >= matrix_p22)&&(matrix_p21 <= matrix_p23))
        row2_med_data <= matrix_p21;
    else if((matrix_p22 <= matrix_p21)&&(matrix_p22 >= matrix_p23)||(matrix_p22 >= matrix_p21)&&(matrix_p22 <= matrix_p23))
        row2_med_data <= matrix_p22;
    else
        row2_med_data <= matrix_p23;
end

always @(posedge clk)
begin
    if((matrix_p21 >= matrix_p22)&&(matrix_p21 >= matrix_p23))
        row2_max_data <= matrix_p21;
    else if((matrix_p22 >= matrix_p21)&&(matrix_p22 >= matrix_p23))
        row2_max_data <= matrix_p22;
    else
        row2_max_data <= matrix_p23;
end

reg             [7:0]           row3_min_data;
reg             [7:0]           row3_med_data;
reg             [7:0]           row3_max_data;

always @(posedge clk)
begin
    if((matrix_p31 <= matrix_p32)&&(matrix_p31 <= matrix_p33))
        row3_min_data <= matrix_p31;
    else if((matrix_p32 <= matrix_p31)&&(matrix_p32 <= matrix_p33))
        row3_min_data <= matrix_p32;
    else
        row3_min_data <= matrix_p33;
end

always @(posedge clk)
begin
    if((matrix_p31 <= matrix_p32)&&(matrix_p31 >= matrix_p33)||(matrix_p31 >= matrix_p32)&&(matrix_p31 <= matrix_p33))
        row3_med_data <= matrix_p31;
    else if((matrix_p32 <= matrix_p31)&&(matrix_p32 >= matrix_p33)||(matrix_p32 >= matrix_p31)&&(matrix_p32 <= matrix_p33))
        row3_med_data <= matrix_p32;
    else
        row3_med_data <= matrix_p33;
end

always @(posedge clk)
begin
    if((matrix_p31 >= matrix_p32)&&(matrix_p31 >= matrix_p33))
        row3_max_data <= matrix_p31;
    else if((matrix_p32 >= matrix_p31)&&(matrix_p32 >= matrix_p33))
        row3_max_data <= matrix_p32;
    else
        row3_max_data <= matrix_p33;
end

//----------------------------------------------------------------------
reg             [7:0]           max_of_min_data;
reg             [7:0]           med_of_med_data;
reg             [7:0]           min_of_max_data;

always @(posedge clk)
begin
    if((row1_min_data >= row2_min_data)&&(row1_min_data >= row3_min_data))
        max_of_min_data <= row1_min_data;
    else if((row2_min_data >= row1_min_data)&&(row2_min_data >= row3_min_data))
        max_of_min_data <= row2_min_data;
    else
        max_of_min_data <= row3_min_data;
end

always @(posedge clk)
begin
    if((row1_med_data >= row2_med_data)&&(row1_med_data <= row3_med_data)||(row1_med_data <= row2_med_data)&&(row1_med_data >= row3_med_data))
        med_of_med_data <= row1_med_data;
    else if((row2_med_data >= row1_med_data)&&(row2_med_data <= row3_med_data)||(row2_med_data <= row1_med_data)&&(row2_med_data >= row3_med_data))
        med_of_med_data <= row2_med_data;
    else
        med_of_med_data <= row3_med_data;
end

always @(posedge clk)
begin
    if((row1_max_data <= row2_max_data)&&(row1_max_data <= row3_max_data))
        min_of_max_data <= row1_max_data;
    else if((row2_max_data <= row1_max_data)&&(row2_max_data <= row3_max_data))
        min_of_max_data <= row2_max_data;
    else
        min_of_max_data <= row3_max_data;
end

//----------------------------------------------------------------------
reg             [7:0]           pixel_data;

always @(posedge clk)
begin
    if((max_of_min_data >= med_of_med_data)&&(max_of_min_data <= min_of_max_data)||(max_of_min_data <= med_of_med_data)&&(max_of_min_data >= min_of_max_data))
        pixel_data <= max_of_min_data;
    else if((med_of_med_data >= max_of_min_data)&&(med_of_med_data <= min_of_max_data)||(med_of_med_data <= max_of_min_data)&&(med_of_med_data >= min_of_max_data))
        pixel_data <= med_of_med_data;
    else
        pixel_data <= min_of_max_data;
end

//----------------------------------------------------------------------
//  lag 3 clocks signal sync
reg             [2:0]           matrix_img_vsync_r1;
reg             [2:0]           matrix_img_href_r1;
reg             [2:0]           matrix_img_de_r1;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        matrix_img_vsync_r1 <= 3'b0;
        matrix_img_href_r1  <= 3'b0;
        matrix_img_de_r1  <= 3'b0;
    end
    else
    begin
        matrix_img_vsync_r1 <= {matrix_img_vsync_r1[1:0],matrix_img_vsync};
        matrix_img_href_r1  <= {matrix_img_href_r1[1:0],matrix_img_href};
        matrix_img_de_r1  <= {matrix_img_de_r1[1:0],matrix_img_de};
    end
end


//----------------------------------------------------------------------
//  result output
always @(posedge clk) post_img_gray <= pixel_data;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        post_img_vsync <= 1'b0;
        post_img_href  <= 1'b0;
        post_img_de    <= 1'b0;
    end
    else
    begin
        post_img_vsync <= matrix_img_vsync_r1[2];
        post_img_href  <= matrix_img_href_r1[2];
        post_img_de    <= matrix_img_de_r1[2];
    end
end







endmodule 