module uart_send(
      input 				sys_clk,
      input 				sys_rst_n,
      input  [7:0] 			uart_din,
	  input 				uart_en,
	  
      output 				uart_txd,
      output 				uart_tx_busy //发送忙状态标志                
    );
    
   parameter CLK_FREQ = 50_000_000;
   parameter UART_BPS = 115200;      //串口波特率
   parameter BPS_CNT = CLK_FREQ/UART_BPS; //为得到指定波特率，需要对系统时钟计数 BPS_CNT 次
    
	
    reg  	uart_en_d0;
    reg  	uart_en_d1;
    reg  	tx_flag;
    reg [3:0] 	tx_cnt;
    reg	 [15:0] clk_cnt;
    reg [7:0]   tx_data;
    
    wire  	en_flag;
    
    assign  en_flag = (~uart_en_d1) && uart_en_d0;
	assign  uart_tx_busy = tx_flag;
	
	
    always@(posedge sys_clk or negedge sys_rst_n) begin
    if(~sys_rst_n)begin
             uart_en_d0  <=  1'b0; 
             uart_en_d1  <=  1'b0;  
    end
    else begin
             uart_en_d0  <=  uart_en; 
             uart_en_d1  <=  uart_en_d0;    
    end
 end   
  
    
    always@(posedge sys_clk or negedge sys_rst_n) begin
    if(~sys_rst_n)
           	 tx_flag <= 1'b0;
    else if(en_flag)
             tx_flag <= 1'b1;
    else if((tx_cnt == 4'd9)&&(clk_cnt == BPS_CNT-(BPS_CNT/16) - 1'b1))
             tx_flag <= 1'b0;
    else
             tx_flag <= tx_flag;
  end
  

	always@(posedge sys_clk or negedge sys_rst_n) begin
    if(~sys_rst_n)
           	 tx_data <= 8'd0;
    else if(en_flag)
             tx_data <= uart_din;
    else if((tx_cnt == 4'd9)&&(clk_cnt == BPS_CNT-(BPS_CNT/16) - 1'b1))
             tx_data <= 8'd0;
  end
	
	
      always@(posedge sys_clk or negedge sys_rst_n) begin
       if(~sys_rst_n)
               clk_cnt <= 16'd0;
        else if(tx_flag)begin
           if(clk_cnt < BPS_CNT - 1'b1)
               clk_cnt <= clk_cnt + 1'b1;
           else
               clk_cnt <= 16'd0;
        end
        else
               clk_cnt <= 16'd0; 
   end 
   
   
    always@(posedge sys_clk or negedge sys_rst_n) begin
       if(~sys_rst_n)
               tx_cnt <= 4'd0;
        else if(tx_flag)begin
           if(clk_cnt == BPS_CNT - 1'b1)
               tx_cnt <= tx_cnt + 1'b1;
           else
               tx_cnt <= tx_cnt;
        end
        else
               tx_cnt <= 4'd0; 
     end 
   
   always@(posedge sys_clk or negedge sys_rst_n) begin
       if(~sys_rst_n)
               uart_txd <= 1'd1;
       else if(tx_flag && (clk_cnt == 0))begin
           case(tx_cnt)
		        4'd0: uart_txd   <= 0;
                4'd1: uart_txd <= tx_data[0];
                4'd2: uart_txd <= tx_data[1];
                4'd3: uart_txd <= tx_data[2];
                4'd4: uart_txd <= tx_data[3];
                4'd5: uart_txd <= tx_data[4];
                4'd6: uart_txd <= tx_data[5];
                4'd7: uart_txd <= tx_data[6];
                4'd8: uart_txd <= tx_data[7];
				4'd9: uart_txd <= 1'b1;
                default:;
           endcase
       end
  end           
endmodule



module uart_loop(
      input 				sys_clk,
      input 				sys_rst_n,
      input  [7:0] 			recv_data,
	  input 				recv_done,
	  input 				tx_busy,
      output 	reg[7:0]		send_data,
      output 	reg			send_en            
    );

   
   reg   recv_done_d0;
   reg   recv_done_d1;
   reg   send_ready;
   
   wire recv_done_flag;
   assign  recv_done_flag = (~recv_done_d1) && recv_done_d0;
 
 
   always@(posedge sys_clk or negedge sys_rst_n) begin
       if(~sys_rst_n)begin
	         recv_done_d0 <= 1'b0;
			 recv_done_d0 <= 1'b0;
	   end
       else   begin
	         recv_done_d0 <= recv_done;
			 recv_done_d1 <= recv_done_d0;
	   end
 end
  
    always@(posedge sys_clk or negedge sys_rst_n) begin
       if(~sys_rst_n)begin
              send_data <= 8'd0;
              send_en <= 1'b0;
			  send_ready <= 1'b0;
	   end
	   else if(recv_done_flag) begin 
	             send_data <= recv_data;
				 send_ready <= 1'b1;
				 send_en <= 1'b0;
			 end
	   else if (send_ready && (!tx_busy) ) begin
	             send_en <= 1'b1;
				 send_ready <= 1'b0;
	   end
 end	   
	   

endmodule