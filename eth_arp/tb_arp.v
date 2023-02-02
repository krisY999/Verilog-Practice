//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com 
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           tb_arp
// Last modified Date:  2021/2/19 17:54:24
// Last Version:        V1.0
// Descriptions:        
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2021/2/19 17:54:24
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`timescale  1ns/1ns                     //�������ʱ�䵥λ1ns�ͷ���ʱ�侫��Ϊ1ns

module  tb_arp;

//parameter  define
parameter  T = 8;                       //ʱ������Ϊ8ns  RXC 125Mhz
parameter  OP_CYCLE = 100;              //��������

//������MAC��ַ 00-11-22-33-44-55
parameter  BOARD_MAC = 48'h00_11_22_33_44_55;     
//������IP��ַ 192.168.1.10     
parameter  BOARD_IP  = {8'd192,8'd168,8'd1,8'd10};
//Ŀ��MAC��ַ ff_ff_ff_ff_ff_ff
parameter  DES_MAC   = 48'hff_ff_ff_ff_ff_ff;
//Ŀ��IP��ַ 192.168.1.102
parameter  DES_IP    = {8'd192,8'd168,8'd1,8'd10}; //�Լ������Լ��Ļ��أ��ĳ�һ��

//reg define
reg           gmii_clk;    //ʱ���ź�
reg           sys_rst_n;   //��λ�ź�

reg           arp_tx_en  ; //ARP����ʹ���ź�
reg           arp_tx_type; //ARP�������� 0:����  1:Ӧ��
reg   [3:0]   flow_cnt   ;
reg   [13:0]  delay_cnt  ;

wire          gmii_rx_clk; //GMII����ʱ��
wire          gmii_rx_dv ; //GMII����������Ч�ź�
wire  [7:0]   gmii_rxd   ; //GMII��������
wire          gmii_tx_clk; //GMII����ʱ��
wire          gmii_tx_en ; //GMII��������ʹ���ź�
wire  [7:0]   gmii_txd   ; //GMII��������
              
wire          arp_rx_done; //ARP��������ź�
wire          arp_rx_type; //ARP�������� 0:����  1:Ӧ��
wire  [47:0]  src_mac    ; //���յ�Ŀ��MAC��ַ
wire  [31:0]  src_ip     ; //���յ�Ŀ��IP��ַ    
wire  [47:0]  des_mac    ; //���͵�Ŀ��MAC��ַ
wire  [31:0]  des_ip     ; //���͵�Ŀ��IP��ַ
wire          tx_done    ; //��̫����������ź� 

//*****************************************************
//**                    main code
//*****************************************************

assign gmii_rx_clk = gmii_clk   ;
assign gmii_tx_clk = gmii_clk   ;
assign gmii_rx_dv  = gmii_tx_en ;
assign gmii_rxd    = gmii_txd   ;

assign des_mac = src_mac;
assign des_ip = src_ip;

//�������źų�ʼֵ
initial begin
    gmii_clk           = 1'b0;
    sys_rst_n          = 1'b0;     //��λ
    #(T+1)  sys_rst_n  = 1'b1;     //�ڵ�(T+1)ns��ʱ��λ�ź��ź�����
end

//125Mhz��ʱ�ӣ�������Ϊ1/125Mhz=8ns,����ÿ4ns����ƽȡ��һ��
always #(T/2) gmii_clk = ~gmii_clk;

always @(posedge gmii_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        arp_tx_en <= 1'b0;
        arp_tx_type <= 1'b0;
        delay_cnt <= 1'b0;
        flow_cnt <= 1'b0;
    end
    else begin
        case(flow_cnt)
            'd0 : flow_cnt <= flow_cnt + 1'b1;
            'd1 : begin
                arp_tx_en <= 1'b1;
                arp_tx_type <= 1'b0;  //����ARP����
                flow_cnt <= flow_cnt + 1'b1;
            end
            'd2 : begin 
                arp_tx_en <= 1'b0;
                flow_cnt <= flow_cnt + 1'b1;
            end    
            'd3 : begin
                if(tx_done)
                    flow_cnt <= flow_cnt + 1'b1;
            end
            'd4 : begin
                delay_cnt <= delay_cnt + 1'b1;
                if(delay_cnt == OP_CYCLE - 1'b1)
                    flow_cnt <= flow_cnt + 1'b1;
            end
            'd5 : begin
                arp_tx_en <= 1'b1;
                arp_tx_type <= 1'b1;  //����ARPӦ��   
                flow_cnt <= flow_cnt + 1'b1;                
            end
            'd6 : begin 
                arp_tx_en <= 1'b0;
                flow_cnt <= flow_cnt + 1'b1;
            end 
            'd7 : begin
                if(tx_done)
                    flow_cnt <= flow_cnt + 1'b1;
            end
            default:;
        endcase    
    end
end

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

endmodule
