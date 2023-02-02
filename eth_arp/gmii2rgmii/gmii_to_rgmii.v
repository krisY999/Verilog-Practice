module gmii_to_rgmii(
    input              idelay_clk  , //IDELAY时钟
     //以太网GMII接口
    output             gmii_rx_clk , //GMII接收时钟
    output             gmii_rx_dv  , //GMII接收数据有效信号
    output      [7:0]  gmii_rxd    , //GMII接收数据
    output             gmii_tx_clk , //GMII发送时钟
    input              gmii_tx_en  , //GMII发送数据使能信号
    input       [7:0]  gmii_txd    , //GMII发送数据         
     //以太网RGMII接口   
    input              rgmii_rxc   , //RGMII接收时钟
    input              rgmii_rx_ctl, //RGMII接收数据控制信号
    input       [3:0]  rgmii_rxd   , //RGMII接收数据
    output             rgmii_txc   , //RGMII发送时钟    
    output             rgmii_tx_ctl, //RGMII发送数据控制信号
    output      [3:0]  rgmii_txd     //RGMII发送数据  
    );
    
    //parameter define
    parameter IDELAY_VALUE = 0;  //输入数据IO延时(如果为n,表示延时n*78ps) 
    
    assign gmii_tx_clk = gmii_rx_clk;
    
    
    rgmii_rx  u_rgmii_rx(
        .idelay_clk             (idelay_clk), //200Mhz时钟，IDELAY时钟   
        .rgmii_rxc              (rgmii_rxc), //RGMII接收时钟
        .rgmii_rx_ctl           (rgmii_rx_ctl), //RGMII接收数据控制信号
        .rgmii_rxd              (rgmii_rxd), //RGMII接收数据    
        .gmii_rx_clk            (gmii_rx_clk), //GMII接收时钟
        .gmii_rx_dv             (gmii_rx_dv), //GMII接收数据有效信号
        .gmii_rxd               (gmii_rxd)  //GMII接收数据   
    );
    
    rgmii_tx  u_rgmii_tx(
        .gmii_tx_clk                 (gmii_tx_clk), //GMII发送时钟    
        .gmii_tx_en                  (gmii_tx_en), //GMII输出数据有效信号
        .gmii_txd                    (gmii_txd), //GMII输出数据        
        .rgmii_txc                   (rgmii_txc), //RGMII发送数据时钟    
        .rgmii_tx_ctl                (rgmii_tx_ctl), //RGMII输出数据有效信号
        .rgmii_txd                   (rgmii_txd)   //RGMII输出数据   
    );
    
    
    
endmodule
