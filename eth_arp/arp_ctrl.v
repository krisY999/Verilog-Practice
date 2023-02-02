module arp_ctrl(
      input                 clk     ,  //时钟信号
      input                 rst_n   ,  //复位信号，低电平有效
      
      input               touch_key,   //触摸按键,用于触发开发板发出ARP请求   
      input               arp_rx_done, //ARP接收完成信号
      input               arp_rx_type, //ARP接收类型 0:请求  1:应答
      output  reg         arp_tx_en  , //ARP发送使能信号
      output  reg         arp_tx_type //ARP发送类型 0:请求  1:应答  
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
                arp_tx_type <= 1'b0;   //发送arp请求信号
          end
          else if(arp_rx_done && (arp_rx_type == 1'b0))begin  //接收到ARP请求,开始控制ARP发送模块应答
                 arp_tx_en <= 1'b1 ;
                 arp_tx_type <= 1'b1;   //发送arp应答信号
          end
          else
                arp_tx_en <= 1'b0 ;
    end
 end
    
    
endmodule
