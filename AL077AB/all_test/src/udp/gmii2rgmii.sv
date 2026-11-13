// RGMII ↔ GMII 桥接 
// V1.1.0
// - 补全 TX/RX 数据与控制通路 (RGMII 1G / DDR 模式, 125MHz)
// - RGMII 编码: 上升沿传低半字节[3:0]/TX_EN, 下降沿传高半字节[7:4]/TX_EN^TX_ER
//
module gmii2rgmii (
    input                               i_rst_n,
    // RGMII 引脚侧
    input                               i_rgmii_rxc,
    input                       [ 3:0]  i_rgmii_rxd,
    input                               i_rgmii_rxctl,
    output                      [ 3:0]  o_rgmii_txd,
    output                              o_rgmii_txctl,
    output                              o_rgmii_txc,

    output                              o_usr_clk, //i_rgmii_rxc 移相2000ps(~90°) 的125MHz
    // GMII RX (字节流输出)
    output      logic           [ 7:0]  o_rx_data,
    output      logic                   o_rx_dv,
    output      logic                   o_rx_er,
    // GMII TX (字节流输入)
    input                       [ 7:0]  i_tx_data,
    input                               i_tx_en,
    input                               i_tx_er
    );

/////////////////////////////////////////////////////////////////////////////////////////
////////////////////                 内部信号                /////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
// TXD: 下降沿输出高半字节[7:4], 上升沿输出低半字节[3:0]
logic [3:0]                     txd_datain_h;
logic [3:0]                     txd_datain_l;
logic [3:0]                     txd_dataout;
// TXCTL: 下降沿输出TX_EN^TX_ER, 上升沿输出TX_EN
logic                           txctl_datain_h;
logic                           txctl_datain_l;
logic                           txctl_dataout;
// TXC: DDIO输出固定{1,0} -> 与数据边沿对齐的125MHz方波
logic                           txc_datain_h;
logic                           txc_datain_l;
logic                           txc_dataout;

// RXD: 下降沿采样高半字节[7:4], 上升沿采样低半字节[3:0]
logic [3:0]                     rxd_dataout_h;
logic [3:0]                     rxd_dataout_l;
// RXCTL: 下降沿采样RX_DV^RX_ER, 上升沿采样RX_DV
logic                           rxctl_dataout_h;
logic                           rxctl_dataout_l;

/////////////////////////////////////////////////////////////////////////////////////////
////////////////////                GMII TX → RGMII             /////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
// TXD
assign txd_datain_h = i_tx_data[3:0];   // 上升沿 -> 低半字节
assign txd_datain_l = i_tx_data[7:4];   // 下降沿 -> 高半字节
assign o_rgmii_txd  = txd_dataout;

// TXCTL 
assign txctl_datain_h = i_tx_en;
assign txctl_datain_l = i_tx_en ^ i_tx_er;     
assign o_rgmii_txctl = txctl_dataout;

// TXC: 输出{1,0} -> 每周期一个完整方波, 边沿与数据对齐
assign txc_datain_h = 1'b1;
assign txc_datain_l = 1'b0;
assign o_rgmii_txc  = txc_dataout;

/////////////////////////////////////////////////////////////////////////////////////////
////////////////////                RGMII → GMII RX             /////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
// RXD
assign o_rx_data = {rxd_dataout_h, rxd_dataout_l};

// RXCTL: RX_DV在上升沿, RX_DV^RX_ER在下降沿
assign o_rx_dv = rxctl_dataout_l;
assign o_rx_er = rxctl_dataout_h ^ rxctl_dataout_l;

/////////////////////////////////////////////////////////////////////////////////////////
////////////////////                 时钟与DDIO                 /////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
//PLL shift: RXC 125MHz 移相2000ps(~90°) 用于中心对齐采样
// rx_clk_pll rx_clk_pll_m0 (
//     .refclk     (i_rgmii_rxc    ),
//     .rst        (~i_rst_n       ),
//     .outclk_0   (o_usr_clk      )
// );
assign o_usr_clk = i_rgmii_rxc; //直接使用RGMII RXC作为用户时钟

//Altera DDIO OUT: TXD
altddio_out #(
    .WIDTH(4),
    .POWER_UP_HIGH("OFF"),
    .INTENDED_DEVICE_FAMILY("Cyclone V")
) u_altddio_out (
    .datain_h  (txd_datain_h   ),
    .datain_l  (txd_datain_l   ),
    .outclock  (o_usr_clk      ),
    .aclr      (1'b0           ),
    .dataout   (txd_dataout    )
);

//Altera DDIO OUT: TXCTL
altddio_out #(
    .WIDTH(1),
    .POWER_UP_HIGH("OFF"),
    .INTENDED_DEVICE_FAMILY("Cyclone V")
) u_altddio_out_ctl (
    .datain_h  (txctl_datain_h ),
    .datain_l  (txctl_datain_l ),
    .outclock  (o_usr_clk      ),
    .aclr      (1'b0           ),
    .dataout   (txctl_dataout  )
);

//Altera DDIO OUT: TXC
altddio_out #(
    .WIDTH(1),
    .POWER_UP_HIGH("OFF"),
    .INTENDED_DEVICE_FAMILY("Cyclone V")
) u_altddio_out_txc (
    .datain_h  (txc_datain_h   ),
    .datain_l  (txc_datain_l   ),
    .outclock  (o_usr_clk      ),
    .aclr      (1'b0           ),
    .dataout   (txc_dataout    )
);

//Altera DDIO IN: RXD
altddio_in #(
    .WIDTH(4),
    .POWER_UP_HIGH("OFF"),
    .INTENDED_DEVICE_FAMILY("Cyclone V")
) u_altddio_in (
    .datain    (i_rgmii_rxd    ),
    .inclock   (o_usr_clk      ),
    .aclr      (1'b0           ),
    .dataout_h (rxd_dataout_h  ),
    .dataout_l (rxd_dataout_l  )
);

//Altera DDIO IN: RXCTL
altddio_in #(
    .WIDTH(1),
    .POWER_UP_HIGH("OFF"),
    .INTENDED_DEVICE_FAMILY("Cyclone V")
) u_altddio_in_ctl (
    .datain    (i_rgmii_rxctl  ),
    .inclock   (o_usr_clk      ),
    .aclr      (1'b0           ),
    .dataout_h (rxctl_dataout_h),
    .dataout_l (rxctl_dataout_l)
);

endmodule
