module arp(
      input                 rst_n,
      
      input                gmii_rx_clk,
      input                gmii_rx_dv , //GMII����������Ч�ź�
      input        [7:0]   gmii_rxd   , //GMII��������
      input                gmii_tx_clk, //GMII��������ʱ��
      output               gmii_tx_en , //GMII���������Ч�ź�
      output       [7:0]   gmii_txd   , //GMII�������
      
      //�û��ӿ�
     output               arp_rx_done, //ARP��������ź�
     output               arp_rx_type, //ARP�������� 0:����  1:Ӧ��
     output       [47:0]  src_mac    , //���յ�Ŀ��MAC��ַ
     output       [31:0]  src_ip     , //���յ�Ŀ��IP��ַ    
     input                arp_tx_en  , //ARP����ʹ���ź�
     input                arp_tx_type, //ARP�������� 0:����  1:Ӧ��
     input        [47:0]  des_mac    , //���͵�Ŀ��MAC��ַ
     input        [31:0]  des_ip     , //���͵�Ŀ��IP��ַ
     output               tx_done      //��̫����������ź�
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
    
    
    
    //wire define
    wire           crc_en  ; //CRC��ʼУ��ʹ��
    wire           crc_clr ; //CRC���ݸ�λ�ź� 
    wire   [7:0]   crc_d8  ; //�����У��8λ����
    wire   [31:0]  crc_data; //CRCУ������
    wire   [31:0]  crc_next; //CRC�´�У���������
    
    assign     crc_d8 = gmii_txd ;
    
    arp_rx
    #(
       .BOARD_MAC           (BOARD_MAC),  
       .BOARD_IP            (BOARD_IP)      
    )
    u_arp_rx(
      .clk                   (gmii_rx_clk),     //ʱ���ź�
      .rst_n                 (rst_n),        //��λ�źţ��͵�ƽ��Ч
                           
      .gmii_rx_dv            (gmii_rx_dv),  //GMII����������Ч�ź�
      .gmii_rxd              (gmii_rxd),    //GMII��������
      .arp_rx_done           (arp_rx_done),            //ARP��������ź�
      .arp_rx_type           (arp_rx_type),            //ARP�������� 0:����  1:Ӧ��
      .src_mac               (src_mac),            //���յ���ԴMAC��ַ
      .src_ip                (src_ip)             //���յ���ԴIP��ַ
    );
    
    arp_tx  u_arp_tx(
        .clk              (gmii_tx_clk)  , //ʱ���ź�
        .rst_n            (rst_n)   , //��λ�źţ��͵�ƽ��Ч

        .arp_tx_en        (arp_tx_en)  , //ARP����ʹ���ź�
        .arp_tx_type      (arp_tx_type)  , //ARP�������� 0:����  1:Ӧ��
        .des_mac          (des_mac)  , //���͵�Ŀ��MAC��ַ
        .des_ip           (des_ip)  , //���͵�Ŀ��IP��ַ
        .crc_data         (crc_data)   , //CRCУ������
        .crc_next         (crc_next[31:24])    , //CRC�´�У���������
        .tx_done          (tx_done)   , //��̫����������ź�
        .gmii_tx_en       (gmii_tx_en)   , //GMII���������Ч�ź�
        .gmii_txd         (gmii_txd)    , //GMII�������
        .crc_en           (crc_en)    , //CRC��ʼУ��ʹ��
        .crc_clr          (crc_clr)      //CRC���ݸ�λ�ź�     
    );
    
    crc32_d8   u_crc32_d8(
    .clk                (gmii_tx_clk)           ,  //ʱ���ź�
    .rst_n              (rst_n)           ,  //��λ�źţ��͵�ƽ��Ч
    .data               (crc_d8)           ,  //�����У��8λ����
    .crc_en             (crc_en)           ,  //crcʹ�ܣ���ʼУ���־
    .crc_clr            (crc_clr)           ,  //crc���ݸ�λ�ź�            
    .crc_data           (crc_data)           ,  //CRCУ������
    .crc_next           (crc_next)               //CRC�´�У���������
    );
    
    
    
endmodule
