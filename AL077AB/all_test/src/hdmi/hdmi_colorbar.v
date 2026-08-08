module  hdmi_colorbar
(
    input   wire            sys_clk     ,   //输入工作时钟,频率50MHz
    input   wire            sys_rst_n   ,   //输入复位信号,低电平有效

    output  wire            tmds_clk_p  ,
    output  wire            tmds_clk_n  ,   //HDMI时钟差分信号
    output  wire    [2:0]   tmds_data_p ,
    output  wire    [2:0]   tmds_data_n     //HDMI图像差分信号
);

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//
//                       1280*720(74.25) ////   1920*1080 RVB2(133.3)  // //1920*1080(148.5)       //   1280*720(74.25) ////   640*480(25)  
parameter H_FP        =    12'd110 ;         // 12'd8    ;  //行时序前沿  // 12'd88   ;  //行时序前沿  //   12'd110 ;         //   12'd16       ; 
parameter H_SYNC      =   12'd40  ;         //  12'd32   ;  //行同步      // 12'd44   ;  //行同步     //   12'd40  ;         //   12'd96       ; 
parameter H_BP        =    12'd220 ;         // 12'd40   ;  //行时序后沿  // 12'd148  ;  //行时序后沿  //   12'd220 ;         //   12'd48       ; 
parameter H_VALID     =    12'd1280;         // 12'd1920 ;  //行有效数据  // 12'd1920 ;  //行有效数据  //   12'd1280;         //   12'd640      ; 
parameter V_FP        =    12'd5   ;         // 12'd17   ;  //场时序前沿  // 12'd4    ;  //场时序前沿  //   12'd5   ;         //   12'd10       ; 
parameter V_SYNC      =   12'd5   ;         //  12'd8    ;  //场同步      // 12'd5    ;  //场同步     //   12'd5   ;         //   12'd2        ; 
parameter V_BP        =    12'd20  ;         // 12'd6    ;  //场时序后沿  // 12'd36   ;  //场时序后沿  //   12'd20  ;         //   12'd33       ; 
parameter V_VALID     =    12'd720 ;         // 12'd1080 ;  //场有效数据  // 12'd1080 ;  //场有效数据  //   12'd720 ;         //   12'd480      ; 
parameter HS_Polarity =  1'b1     ;  //行同步极性
parameter VS_Polarity =  1'b0     ;  //场同步极性


//wire define
wire [23:0 ] video_rgb ;
wire         video_hs  ;
wire         video_vs  ;
wire         video_de  ;

//*****************************************************
//**                    main code
//***************************************************** 
wire       clk_x1  ;   //VGA工作时钟,频率x1 MHz
wire       clk_x5  ;   //VGA工作时钟,频率x5 MHz
clk_gen clk_gen_inst(
    .rst        (~sys_rst_n ),  //输入复位信号,高电平有效,1bit
    .refclk     (sys_clk    ),  //输入50MHz晶振时钟,1bit

    .outclk_0   (clk_x5     ),  //输出VGA工作时钟,频率x5 Mhz,1bit
    .outclk_1   (clk_x1     ),
    .locked     (           )   //输出pll locked信号,1bit
);

//例化视频显示驱动模块
video_driver #(
    .H_SYNC         (H_SYNC     ),
    .H_BP           (H_BP       ),
    .H_VALID        (H_VALID    ),
    .H_FP           (H_FP       ),
    .V_SYNC         (V_SYNC     ),
    .V_BP           (V_BP       ),
    .V_VALID        (V_VALID    ),
    .V_FP           (V_FP       ),
    .HS_Polarity    (HS_Polarity),
    .VS_Polarity    (VS_Polarity)
) u_video_driver(
    .pixel_clk      (clk_x1          ),
    .sys_rst_n      (sys_rst_n       ),

    .video_hs       (video_hs        ),
    .video_vs       (video_vs        ),
    .video_de       (video_de        ),
    .video_rgb      (video_rgb       ),

    .pixel_xpos     (                ),
    .pixel_ypos     (                )
    );

//例化HDMI驱动模块
dvi_transmitter_top u_rgb2dvi_0(
    .pclk           (clk_x1         ),
    .pclk_x5        (clk_x5         ),
    .reset_n        (sys_rst_n      ),
                
    .video_hsync    (video_hs       ), 
    .video_vsync    (video_vs       ),
    .video_de       (video_de       ),
    .video_din      (video_rgb      ),
                
    .tmds_clk_p     (tmds_clk_p     ),
    .tmds_clk_n     (tmds_clk_n     ),
    .tmds_data_p    (tmds_data_p    ),
    .tmds_data_n    (tmds_data_n    )
    );
	 
endmodule