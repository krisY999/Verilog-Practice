module eth_arp_test(
       input            sys_clk,
       input            sys_rst_n,
       input            touch_key,   //触摸按键,用于触发开发板发出ARP请求
       //以太网RGMII接口
       input            eth_rxc,
       input            eth_rx_ctl,
       input  [3:0]     eth_rxd,
       output           eth_txc,
       output           eth_tx_ctl, //RGMII输出数据有效信号
       output  [3:0]    eth_txd,
       output           eth_rst_n    //以太网硬件复位
    );
    
    //parameter define
    //开发板MAC地址 00-11-22-33-44-55
    parameter  BOARD_MAC = 48'h00_11_22_33_44_55;     
    //开发板IP地址 192.168.1.10     
    parameter  BOARD_IP  = {8'd192,8'd168,8'd1,8'd10};
    //目的MAC地址 ff_ff_ff_ff_ff_ff
    parameter  DES_MAC   = 48'hff_ff_ff_ff_ff_ff;
    //目的IP地址 192.168.1.102
    parameter  DES_IP    = {8'd192,8'd168,8'd1,8'd102};
    //输入数据IO延时(如果为n,表示延时n*78ps) 
    parameter IDELAY_VALUE = 0;
    
    //wire define
    wire          clk_200m   ; //用于IO延时的时钟 
    wire          locked     ;
    
    wire          gmii_rx_clk; //GMII接收时钟
    wire          gmii_rx_dv ; //GMII接收数据有效信号
    wire  [7:0]   gmii_rxd   ; //GMII接收数据
    wire          gmii_tx_clk; //GMII发送时钟
    wire          gmii_tx_en ; //GMII发送数据使能信号
    wire  [7:0]   gmii_txd   ; //GMII发送数据
    
    
    wire  [47:0]  src_mac    ; //接收到的源MAC地址
    wire  [31:0]  src_ip     ; //接收到的源IP地址  
    wire  [47:0]  des_mac    ; //发送的目标MAC地址
    wire  [31:0]  des_ip     ; //发送的目标IP地址 
    wire          arp_rx_done; //ARP接收完成信号
    wire          arp_rx_type; //ARP接收类型 0:请求  1:应答 
    wire          arp_tx_en  ; //ARP发送使能信号
    wire          arp_tx_type; //ARP发送类型 0:请求  1:应答
    wire          tx_done    ; //以太网发送完成信号
//*****************************************************
//**                    main code
//*****************************************************
    
    assign des_mac = src_mac;
    assign des_ip = src_ip;
    assign eth_rst_n = sys_rst_n;
    
    
    
    clk_wiz_0 u_clk_wiz
   (
        .clk_out1(clk_200m),     // output clk_out1
        // Status and control signals
        .reset(~sys_rst_n), // input reset
        .locked(locked),       // output locked
       // Clock in ports
        .clk_in1(sys_clk)
    );      // input clk_in1
    
    
    gmii_to_rgmii u_gmii_to_rgmii(
    .idelay_clk          (clk_200m), //IDELAY时钟
    
    .gmii_rx_clk         (gmii_rx_clk), //GMII接收时钟
    .gmii_rx_dv          (gmii_rx_dv), //GMII接收数据有效信号
    .gmii_rxd            (gmii_rxd), //GMII接收数据
    .gmii_tx_clk         (gmii_tx_clk), //GMII发送时钟
    .gmii_tx_en          (gmii_tx_en), //GMII发送数据使能信号
    .gmii_txd            (gmii_txd), //GMII发送数据     
        
    .rgmii_rxc           (eth_rxc), //RGMII接收时钟
    .rgmii_rx_ctl        (eth_rx_ctl), //RGMII接收数据控制信号
    .rgmii_rxd           (eth_rxd), //RGMII接收数据
    .rgmii_txc           (eth_txc), //RGMII发送时钟    
    .rgmii_tx_ctl        (eth_tx_ctl), //RGMII发送数据控制信号
    .rgmii_txd           (eth_txd)   //RGMII发送数据  
    );
    
    //ARP通信
    arp                                             
   #(
    .BOARD_MAC     (BOARD_MAC),      //参数例化
    .BOARD_IP      (BOARD_IP ),
    .DES_MAC       (DES_MAC  ),
    .DES_IP        (DES_IP   )
    )
   u_arp(
    .rst_n         (sys_rst_n  ),
                    
    .gmii_rx_clk   (gmii_rx_clk),
    .gmii_rx_dv    (gmii_rx_dv ),
    .gmii_rxd      (gmii_rxd   ),
    .gmii_tx_clk   (gmii_tx_clk),
    .gmii_tx_en    (gmii_tx_en ),
    .gmii_txd      (gmii_txd   ),
                    
    .arp_rx_done   (arp_rx_done),
    .arp_rx_type   (arp_rx_type),
    .src_mac       (src_mac    ),
    .src_ip        (src_ip     ),
    .arp_tx_en     (arp_tx_en  ),
    .arp_tx_type   (arp_tx_type),
    .des_mac       (des_mac    ),
    .des_ip        (des_ip     ),
    .tx_done       (tx_done    )
    );
    
    
    arp_ctrl u_arp_ctrl(
    .clk           (gmii_rx_clk),
    .rst_n         (sys_rst_n),
                   
    .touch_key     (touch_key),
    .arp_rx_done   (arp_rx_done),
    .arp_rx_type   (arp_rx_type),
    .arp_tx_en     (arp_tx_en),
    .arp_tx_type   (arp_tx_type)
    );
    
endmodule
