module touch_led(
    //input
    input        sys_clk,      //时钟信号50Mhz
    input        sys_rst_n,    //复位信号
    input        touch_key,    //触摸按键 
 
    //output
    output  reg  led           //LED灯
);

//reg define
reg    touch_key_d0;
reg    touch_key_d1;

//wire define
wire   touch_en;


always @ (posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
	     touch_key_d0 <= 0;
		 touch_key_d1 <= 0;
    else begin
	     touch_key_d0 <= touch_key;
		 touch_key_d1 <= touch_key_d0;
      end
   end
   
//捕获触摸按键端口的上升沿，得到一个时钟周期的脉冲信号 
assign    touch_en <= (~touch_key_d1)&(touch_key_d0);

always @ (posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) 
            led <= 1'b1;
    else if(touch_en)
            led <= ~led;
  end
  
  
endmodule