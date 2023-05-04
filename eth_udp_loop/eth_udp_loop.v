module eth_udp_loop(
    input              sys_clk   , //ϵͳʱ��
    input              sys_rst_n , //ϵͳ��λ�źţ��͵�ƽ��Ч 
    //��̫��RGMII�ӿ�   
    input              eth_rxc   , //RGMII��������ʱ��
    input              eth_rx_ctl, //RGMII����������Ч�ź�
    input       [3:0]  eth_rxd   , //RGMII��������
    output             eth_txc   , //RGMII��������ʱ��    
    output             eth_tx_ctl, //RGMII���������Ч�ź�
    output      [3:0]  eth_txd   , //RGMII�������          
    output             eth_rst_n   //��̫��оƬ��λ�źţ��͵�ƽ��Ч   
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
//��������IO��ʱ,�˴�Ϊ0,������ʱ(���Ϊn,��ʾ��ʱn*78ps) 
parameter IDELAY_VALUE = 0;
  
wire          clk_200m   ; //����IO��ʱ��ʱ�� 

wire          gmii_rx_clk; //GMII����ʱ��
wire          gmii_rx_dv ; //GMII����������Ч�ź�
wire  [7:0]   gmii_rxd   ; //GMII��������
wire          gmii_tx_clk; //GMII����ʱ��
wire          gmii_tx_en ; //GMII��������ʹ���ź�
wire  [7:0]   gmii_txd   ; //GMII��������   

wire          arp_gmii_tx_en; //ARP GMII���������Ч�ź� 
wire  [7:0]   arp_gmii_txd  ; //ARP GMII�������
wire          arp_rx_done   ; //ARP��������ź�
wire          arp_rx_type   ; //ARP�������� 0:����  1:Ӧ��
wire  [47:0]  src_mac       ; //���յ�Ŀ��MAC��ַ
wire  [31:0]  src_ip        ; //���յ�Ŀ��IP��ַ    
wire          arp_tx_en     ; //ARP����ʹ���ź�
wire          arp_tx_type   ; //ARP�������� 0:����  1:Ӧ��
wire  [47:0]  des_mac       ; //���͵�Ŀ��MAC��ַ
wire  [31:0]  des_ip        ; //���͵�Ŀ��IP��ַ   
wire          arp_tx_done   ; //ARP��������ź�

wire          udp_gmii_tx_en; //UDP GMII���������Ч�ź� 
wire  [7:0]   udp_gmii_txd  ; //UDP GMII�������
wire          rec_pkt_done  ; //UDP�������ݽ�������ź�
wire          rec_en        ; //UDP���յ�����ʹ���ź�
wire  [31:0]  rec_data      ; //UDP���յ�����
wire  [15:0]  rec_byte_num  ; //UDP���յ���Ч�ֽ��� ��λ:byte 
wire          tx_start_en;
wire  [15:0]  tx_byte_num   ; //UDP���͵���Ч�ֽ��� ��λ:byte 
wire          udp_tx_done   ; //UDP��������ź�
wire          tx_req        ; //UDP�����������ź�
wire  [31:0]  tx_data       ; //UDP����������
//*****************************************************
//**                    main code
//*****************************************************
assign    tx_start_en = rec_pkt_done;
assign     tx_byte_num = rec_byte_num;
assign des_mac = src_mac;
assign des_ip = src_ip;
assign eth_rst_n = sys_rst_n;
  
  //MMCM/PLL
clk_wiz_0 u_clk_wiz
(
    .clk_in1   (sys_clk   ),
    .clk_out1  (clk_200m  ),    
    .reset     (~sys_rst_n), 
    .locked    (locked)
);
 
 //GMII�ӿ�תRGMII�ӿ�
gmii_to_rgmii 
    #(
     .IDELAY_VALUE (IDELAY_VALUE)
     )
    u_gmii_to_rgmii(
    .idelay_clk    (clk_200m    ),

    .gmii_rx_clk   (gmii_rx_clk ),
    .gmii_rx_dv    (gmii_rx_dv  ),
    .gmii_rxd      (gmii_rxd    ),
    .gmii_tx_clk   (gmii_tx_clk ),
    .gmii_tx_en    (gmii_tx_en  ),
    .gmii_txd      (gmii_txd    ),
    
    .rgmii_rxc     (eth_rxc     ),
    .rgmii_rx_ctl  (eth_rx_ctl  ),
    .rgmii_rxd     (eth_rxd     ),
    .rgmii_txc     (eth_txc     ),
    .rgmii_tx_ctl  (eth_tx_ctl  ),
    .rgmii_txd     (eth_txd     )
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
    .gmii_tx_en    (arp_gmii_tx_en ),
    .gmii_txd      (arp_gmii_txd),
                    
    .arp_rx_done   (arp_rx_done),
    .arp_rx_type   (arp_rx_type),
    .src_mac       (src_mac    ),
    .src_ip        (src_ip     ),
    .arp_tx_en     (arp_tx_en  ),
    .arp_tx_type   (arp_tx_type),
    .des_mac       (des_mac    ),
    .des_ip        (des_ip     ),
    .tx_done       (arp_tx_done)
    ); 
 
 //UDPͨ��
udp                                             
   #(
    .BOARD_MAC     (BOARD_MAC),      //��������
    .BOARD_IP      (BOARD_IP ),
    .DES_MAC       (DES_MAC  ),
    .DES_IP        (DES_IP   )
    )
   u_udp(
    .rst_n                                      (sys_rst_n), //��λ�źţ��͵�ƽ��Ч
    //GMII�ӿ�
    .gmii_rx_clk                                (gmii_rx_clk), //GMII��������ʱ��
    .gmii_rx_dv                                 (gmii_rx_dv), //GMII����������Ч�ź�
    .gmii_rxd                                   (gmii_rxd), //GMII��������
    .gmii_tx_clk                                (gmii_tx_clk), //GMII��������ʱ��
    .gmii_tx_en                                 (udp_gmii_tx_en), //GMII���������Ч�ź�
    .gmii_txd                                   (udp_gmii_txd), //GMII������� 

    .rec_pkt_done                               (rec_pkt_done), //��̫���������ݽ�������ź�
    .rec_en                                     (rec_en), //��̫�����յ�����ʹ���ź�
    .rec_data                                   (rec_data), //��̫�����յ�����
    .rec_byte_num                               (rec_byte_num), //��̫�����յ���Ч�ֽ��� ��λ:byte     
    .tx_start_en                                (tx_start_en), //��̫����ʼ�����ź�
    .tx_data                                    (tx_data), //��̫������������  
    .tx_byte_num                                (tx_byte_num), //��̫�����͵���Ч�ֽ��� ��λ:byte  
    .des_mac                                    (des_mac), //���͵�Ŀ��MAC��ַ
    .des_ip                                     (des_ip), //���͵�Ŀ��IP��ַ    
    .tx_done                                    (udp_tx_done), //��̫����������ź�
    .tx_req                                     (tx_req)  //�����������ź�              
    ); 
 
 
 fifo_generator_0 u_sync_fifo_2048x32b (
  .clk(gmii_rx_clk),      // input wire clk
  .srst(~sys_rst_n),    // input wire srst
  .din(rec_data),      // input wire [31 : 0] din
  .wr_en(rec_en),  // input wire wr_en
  .rd_en(tx_req),  // input wire rd_en
  .dout(tx_data),    // output wire [31 : 0] dout
  .full(),    // output wire full
  .empty()  // output wire empty
);   

  
  eth_ctrl  u_eth_ctrl(
       . clk                   (gmii_rx_clk) ,     //ϵͳʱ��
       . rst_n                 (~sys_rst_n)  ,     //ϵͳ��λ�źţ��͵�ƽ��Ч 
      
       .  arp_rx_done          (arp_rx_done)     , //ARP��������ź�
       .  arp_rx_type          (arp_rx_type)     , //ARP�������� 0:����  1:Ӧ��
       . arp_tx_en             (arp_tx_en)     , 
       .  arp_tx_type          (arp_tx_type)     ,
       . arp_tx_done           (arp_tx_done)     ,    //ARP��������ź�
       . arp_gmii_tx_en        (arp_gmii_tx_en)     , //ARP GMII���������Ч�ź� 
       . arp_gmii_txd          (arp_gmii_txd)     ,   //ARP GMII�������

       . udp_gmii_tx_en        (udp_gmii_tx_en)     , 
       . udp_gmii_txd          (udp_gmii_txd)     ,   
       . udp_tx_start_en       (tx_start_en )     ,//UDP��ʼ�����ź�
       . udp_tx_done           (udp_tx_done)     ,    //UDP��������ź�
                          
      . gmii_tx_en                 (gmii_tx_en) ,     //GMII���������Ч�ź� 
      . gmii_txd                    (gmii_txd)       //UDP GMII������� 
    );
  
endmodule
