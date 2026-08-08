module video_driver#(
    parameter H_SYNC    =   12'd32  ,   //行同步
    parameter H_BP      =   12'd80  ,   //行时序后沿
    parameter H_VALID   =   12'd1920 ,  //行有效数据
    parameter H_FP      =   12'd48   ,  //行时序前沿
    parameter V_SYNC    =   12'd5   ,   //场同步
    parameter V_BP      =   12'd23  ,   //场时序后沿
    parameter V_VALID   =   12'd1080 ,  //场有效数据
    parameter V_FP      =   12'd3   ,    //场时序前沿
    parameter HS_Polarity = 1'b1,      //行同步极性
    parameter VS_Polarity = 1'b0       //场同步极性
)(
    input           pixel_clk     ,
    input           sys_rst_n     ,

    //RGB接口
    output          video_hs      ,   //行同步信号
    output          video_vs      ,   //场同步信号
    output          video_de      ,   //数据使能
    output  [23:0]  video_rgb     ,   //RGB888颜色数据
    
    output  [11:0]  pixel_xpos    ,   //像素点横坐标
    output  [11:0]  pixel_ypos        //像素点纵坐标
);

//parameter define
parameter  H_TOTAL  =  H_SYNC + H_BP + H_VALID + H_FP; //行扫描周期
parameter  V_TOTAL  =  V_SYNC + V_BP + V_VALID + V_FP;  //场扫描周期

//reg define
reg  [12:0] cnt_h;
reg  [12:0] cnt_v;

//wire define
wire       video_en;


//*****************************************************
//**                    main code
//*****************************************************

assign video_de  = video_en;

assign video_hs  = ( cnt_h < H_SYNC ) ? ~HS_Polarity : HS_Polarity;  //行同步信号赋值
assign video_vs  = ( cnt_v < V_SYNC ) ? ~VS_Polarity : VS_Polarity;  //场同步信号赋值

//使能RGB数据输出
assign video_en  = (((cnt_h >= H_SYNC+H_BP) && (cnt_h < H_SYNC+H_BP+H_VALID))
                 &&((cnt_v >= V_SYNC+V_BP) && (cnt_v < V_SYNC+V_BP+V_VALID)))
                 ?  1'b1 : 1'b0;

//RGB888数据输出
reg [23:0]pixel_data; 

assign video_rgb = video_en ? pixel_data : 24'd0;

//像素点坐标
assign pixel_xpos = video_en ? (cnt_h - (H_SYNC + H_BP - 1'b1)) : 12'd0;
assign pixel_ypos = video_en ? (cnt_v - (V_SYNC + V_BP - 1'b1)) : 12'd0;

//行计数器对像素时钟计数
always @(posedge pixel_clk ) begin
    if (!sys_rst_n)
        cnt_h <= 13'd0;
    else begin
        if(cnt_h < H_TOTAL - 1'b1)
            cnt_h <= cnt_h + 1'b1;
        else 
            cnt_h <= 13'd0;
    end
end

//场计数器对行计数
always @(posedge pixel_clk ) begin
    if (!sys_rst_n)
        cnt_v <= 13'd0;
    else if(cnt_h == H_TOTAL - 1'b1) begin
        if(cnt_v < V_TOTAL - 1'b1)
            cnt_v <= cnt_v + 1'b1;
        else 
            cnt_v <= 13'd0;
    end
end

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//

parameter   RGB_0     =   24'h800000; //RGB888 测试 0
parameter   RGB_1     =   24'h400000; //RGB888 测试 1
parameter   RGB_2     =   24'h200000; //RGB888 测试 2
parameter   RGB_3     =   24'h100000; //RGB888 测试 3
parameter   RGB_4     =   24'h080000; //RGB888 测试 4
parameter   RGB_5     =   24'h040000; //RGB888 测试 5
parameter   RGB_6     =   24'h020000; //RGB888 测试 6
parameter   RGB_7     =   24'h010000; //RGB888 测试 7
parameter   RGB_8     =   24'h008000; //RGB888 测试 8
parameter   RGB_9     =   24'h004000; //RGB888 测试 9
parameter   RGB_10    =   24'h002000; //RGB888 测试 10
parameter   RGB_11    =   24'h001000; //RGB888 测试 11
parameter   RGB_12    =   24'h000800; //RGB888 测试 12
parameter   RGB_13    =   24'h000400; //RGB888 测试 13
parameter   RGB_14    =   24'h000200; //RGB888 测试 14
parameter   RGB_15    =   24'h000100; //RGB888 测试 15
parameter   RGB_16    =   24'h000080; //RGB888 测试 16
parameter   RGB_17    =   24'h000040; //RGB888 测试 17
parameter   RGB_18    =   24'h000020; //RGB888 测试 18
parameter   RGB_19    =   24'h000010; //RGB888 测试 19
parameter   RGB_20    =   24'h000008; //RGB888 测试 20
parameter   RGB_21    =   24'h000004; //RGB888 测试 21
parameter   RGB_22    =   24'h000002; //RGB888 测试 22
parameter   RGB_23    =   24'h000001; //RGB888 测试 23

//********************************************************************//
//***************************** Main Code ****************************//
//********************************************************************//
//pixel_data:输出像素点色彩信息,根据当前像素点坐标指定当前像素点颜色数据
always@(posedge pixel_clk)begin
    if(sys_rst_n == 1'b0)
        pixel_data    <= 24'd0;
    else    if((pixel_xpos >= 0) && (pixel_xpos < (H_VALID/24)*1))
        pixel_data    <=  RGB_0;
    else    if((pixel_xpos >= (H_VALID/24)*1) && (pixel_xpos < (H_VALID/24)*2))
        pixel_data    <=  RGB_1;
    else    if((pixel_xpos >= (H_VALID/24)*2) && (pixel_xpos < (H_VALID/24)*3))
        pixel_data    <=  RGB_2;
    else    if((pixel_xpos >= (H_VALID/24)*3) && (pixel_xpos < (H_VALID/24)*4))
        pixel_data    <=  RGB_3;
    else    if((pixel_xpos >= (H_VALID/24)*4) && (pixel_xpos < (H_VALID/24)*5))
        pixel_data    <=  RGB_4;  
    else    if((pixel_xpos >= (H_VALID/24)*5) && (pixel_xpos < (H_VALID/24)*6))
        pixel_data    <=  RGB_5;
    else    if((pixel_xpos >= (H_VALID/24)*6) && (pixel_xpos < (H_VALID/24)*7))
        pixel_data    <=  RGB_6;
    else    if((pixel_xpos >= (H_VALID/24)*7) && (pixel_xpos < (H_VALID/24)*8))
        pixel_data    <=  RGB_7;
    else    if((pixel_xpos >= (H_VALID/24)*8) && (pixel_xpos < (H_VALID/24)*9))
        pixel_data    <=  RGB_8;
    else    if((pixel_xpos >= (H_VALID/24)*9) && (pixel_xpos < (H_VALID/24)*10))
        pixel_data    <=  RGB_9;
    else    if((pixel_xpos >= (H_VALID/24)*10) && (pixel_xpos < (H_VALID/24)*11))
        pixel_data    <=  RGB_10;
    else    if((pixel_xpos >= (H_VALID/24)*11) && (pixel_xpos < (H_VALID/24)*12))
        pixel_data    <=  RGB_11;
    else    if((pixel_xpos >= (H_VALID/24)*12) && (pixel_xpos < (H_VALID/24)*13))
        pixel_data    <=  RGB_12;
    else    if((pixel_xpos >= (H_VALID/24)*13) && (pixel_xpos < (H_VALID/24)*14))
        pixel_data    <=  RGB_13;
    else    if((pixel_xpos >= (H_VALID/24)*14) && (pixel_xpos < (H_VALID/24)*15))
        pixel_data    <=  RGB_14;
    else    if((pixel_xpos >= (H_VALID/24)*15) && (pixel_xpos < (H_VALID/24)*16))
        pixel_data    <=  RGB_15;
    else    if((pixel_xpos >= (H_VALID/24)*16) && (pixel_xpos < (H_VALID/24)*17))
        pixel_data    <=  RGB_16;
    else    if((pixel_xpos >= (H_VALID/24)*17) && (pixel_xpos < (H_VALID/24)*18))
        pixel_data    <=  RGB_17;
    else    if((pixel_xpos >= (H_VALID/24)*18) && (pixel_xpos < (H_VALID/24)*19))
        pixel_data    <=  RGB_18;
    else    if((pixel_xpos >= (H_VALID/24)*19) && (pixel_xpos < (H_VALID/24)*20))
        pixel_data    <=  RGB_19;
    else    if((pixel_xpos >= (H_VALID/24)*20) && (pixel_xpos < (H_VALID/24)*21))
        pixel_data    <=  RGB_20;
    else    if((pixel_xpos >= (H_VALID/24)*21) && (pixel_xpos < (H_VALID/24)*22))
        pixel_data    <=  RGB_21;
    else    if((pixel_xpos >= (H_VALID/24)*22) && (pixel_xpos < (H_VALID/24)*23))
        pixel_data    <=  RGB_22;
    else    if((pixel_xpos >= (H_VALID/24)*23) && (pixel_xpos < (H_VALID/24)*24))
        pixel_data    <=  RGB_23;
    else
        pixel_data    <=  24'd0; //默认黑色
end

endmodule