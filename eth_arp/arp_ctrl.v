module arp_ctrl(
      input                 clk     ,  //ʱ���ź�
      input                 rst_n   ,  //��λ�źţ��͵�ƽ��Ч
      
      input               touch_key,   //��������,���ڴ��������巢��ARP����   
      input               arp_rx_done, //ARP��������ź�
      input               arp_rx_type, //ARP�������� 0:����  1:Ӧ��
      output  reg         arp_tx_en  , //ARP����ʹ���ź�
      output  reg         arp_tx_type //ARP�������� 0:����  1:Ӧ��  
    );
    
    reg     touch_key_d0;
    reg     touch_key_d1;
    
    wire    pos_touch_key;
    
    assign  pos_touch_key = (~touch_key_d1)&touch_key_d0;
    
   always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
            touch_key_d0 <= 0;
            touch_key_d1 <= 0;
    end
    else begin
            touch_key_d0 <= touch_key;
            touch_key_d1 <= touch_key_d0;
    end
end
    
    always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
            arp_tx_en <= 0;
            arp_tx_type <= 0;
    end
    else begin
          if(pos_touch_key) begin
                arp_tx_en <= 1'b1 ;
                arp_tx_type <= 1'b0;   //����arp�����ź�
          end
          else if(arp_rx_done && (arp_rx_type == 1'b0))begin  //���յ�ARP����,��ʼ����ARP����ģ��Ӧ��
                 arp_tx_en <= 1'b1 ;
                 arp_tx_type <= 1'b1;   //����arpӦ���ź�
          end
          else
                arp_tx_en <= 1'b0 ;
    end
 end
    
    
endmodule
