module eth_arp_test(
       input            sys_clk,
       input            sys_rst_n,
       input            touch_key,   //��������,���ڴ��������巢��ARP����
       //��̫��RGMII�ӿ�
       input            eth_rxc,
       input            eth_rx_ctl,
       input  [3:0]     eth_rxd,
       output           eth_txc,
       output           eth_tx_ctl, //RGMII���������Ч�ź�
       output  [3:0]    eth_txd,
       output           eth_rst_n    //��̫��Ӳ����λ
    );
    
    //parameter define
    //������MAC��ַ 00-11-22-33-44-55
    parameter  BOARD_MAC = 48'h00_11_22_33_44_55;     
    //������IP��ַ 192.168.1.10     
    parameter  BOARD_IP  = {8'd192,8'd168,8'd1,8'd10};
    //Ŀ��MAC��ַ ff_ff_ff_ff_ff_ff
    parameter  DES_MAC   = 48'hff_ff_ff_ff_ff_ff;
    //Ŀ��IP��ַ 192.168.1.102
    parameter  DES_IP    = {8'd192,8'd168,8'd1,8'd102};
    //��������IO��ʱ(���Ϊn,��ʾ��ʱn*78ps) 
    parameter IDELAY_VALUE = 0;
    
    //wire define
    wire          clk_200m   ; //����IO��ʱ��ʱ�� 
    wire          locked     ;
    
    wire          gmii_rx_clk; //GMII����ʱ��
    wire          gmii_rx_dv ; //GMII����������Ч�ź�
    wire  [7:0]   gmii_rxd   ; //GMII��������
    wire          gmii_tx_clk; //GMII����ʱ��
    wire          gmii_tx_en ; //GMII��������ʹ���ź�
    wire  [7:0]   gmii_txd   ; //GMII��������
    
    
    wire  [47:0]  src_mac    ; //���յ���ԴMAC��ַ
    wire  [31:0]  src_ip     ; //���յ���ԴIP��ַ  
    wire  [47:0]  des_mac    ; //���͵�Ŀ��MAC��ַ
    wire  [31:0]  des_ip     ; //���͵�Ŀ��IP��ַ 
    wire          arp_rx_done; //ARP��������ź�
    wire          arp_rx_type; //ARP�������� 0:����  1:Ӧ�� 
    wire          arp_tx_en  ; //ARP����ʹ���ź�
    wire          arp_tx_type; //ARP�������� 0:����  1:Ӧ��
    wire          tx_done    ; //��̫����������ź�
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
    .idelay_clk          (clk_200m), //IDELAYʱ��
    
    .gmii_rx_clk         (gmii_rx_clk), //GMII����ʱ��
    .gmii_rx_dv          (gmii_rx_dv), //GMII����������Ч�ź�
    .gmii_rxd            (gmii_rxd), //GMII��������
    .gmii_tx_clk         (gmii_tx_clk), //GMII����ʱ��
    .gmii_tx_en          (gmii_tx_en), //GMII��������ʹ���ź�
    .gmii_txd            (gmii_txd), //GMII��������     
        
    .rgmii_rxc           (eth_rxc), //RGMII����ʱ��
    .rgmii_rx_ctl        (eth_rx_ctl), //RGMII�������ݿ����ź�
    .rgmii_rxd           (eth_rxd), //RGMII��������
    .rgmii_txc           (eth_txc), //RGMII����ʱ��    
    .rgmii_tx_ctl        (eth_tx_ctl), //RGMII�������ݿ����ź�
    .rgmii_txd           (eth_txd)   //RGMII��������  
    );
    
    //ARPͨ��
    arp                                             
   #(
    .BOARD_MAC     (BOARD_MAC),      //��������
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
