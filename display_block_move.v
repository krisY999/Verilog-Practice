//显示一个方块在屏幕内移动，碰到边框后沿轴对称方向继续移动

module  rgb_display(
    input             pixel_clk,                  //VGA驱动时钟
    input             sys_rst_n,                //同步复位信号
    
    input      [10:0] pixel_xpos,               //像素点横坐标
    input      [10:0] pixel_ypos,               //像素点纵坐标    
    output reg [23:0] pixel_data                //像素点数据
    );    

//parameter define    
parameter  H_DISP  = 11'd1280;                  //分辨率--行
parameter  V_DISP  = 11'd720;                   //分辨率--列

localparam SIDE_W  = 11'd40;                    //屏幕边框宽度
localparam BLOCK_W = 11'd40;                    //方块宽度
localparam BLUE    = 24'b00000000_00000000_11111111;    //屏幕边框颜色 蓝色
localparam WHITE   = 24'b11111111_11111111_11111111;    //背景颜色 白色
localparam BLACK   = 24'b00000000_00000000_00000000;    //方块颜色 黑色

//reg define
reg [10:0] block_x = SIDE_W ;                             //方块左上角横坐标，赋初始值
reg [10:0] block_y = SIDE_W ;                             //方块左上角纵坐标，赋初始值
reg [21:0] div_cnt;                             //时钟分频计数器
reg        h_direct;                            //方块水平移动方向，1：右移，0：左移
reg        v_direct;                            //方块竖直移动方向，1：向下，0：向上

//wire define   
wire move_en;                                   //方块移动使能信号，频率为100hz

//*****************************************************
//**                    main code
//*****************************************************
assign move_en = (div_cnt == 22'd742500) ? 1'b1 : 1'b0;

//通过对vga驱动时钟计数，实现时钟分频
always @(posedge pixel_clk ) begin         
    if (!sys_rst_n)
           div_cnt <= 0;
	else if(div_cnt == 22'd742500)
		   div_cnt <= 0;          //计数10ms后清零
	else
			div_cnt <= div_cnt + 1'b1;		
end

//当方块移动到边界时，改变移动方向
always @(posedge pixel_clk ) begin         
    if (!sys_rst_n) begin
          h_direct <= 1'b1;
	end
	else begin
	     if(block_x == H_DISP - SIDE_W - BLOCK_W)
	      h_direct <= 1'b0;
		 else if(block_x == SIDE_W - 1'b1)
		  h_direct <= 1'b1;
	     else 
		  h_direct <= h_direct;
	end
end

always @(posedge pixel_clk ) begin         
    if (!sys_rst_n) begin
          v_direct <= 1'b1;
	end
	else begin
	     if(block_y == V_DISP - SIDE_W - BLOCK_W)
	      v_direct <= 1'b0;
		 else if(block_y == SIDE_W - 1'b1)
		  v_direct <= 1'b1;
	     else 
		  v_direct <= v_direct;
	end
end

//根据方块移动方向，改变其纵横坐标
always @(posedge pixel_clk ) begin         
    if (!sys_rst_n) begin
          block_x = SIDE_W ; 
		  block_y = SIDE_W ; 
	end
	else if(move_en) begin
	     if(h_direct) 
			block_x = block_x + 1'b1;
		 else 
		    block_x = block_x - 1'b1;
		 
		 if(v_direct)
		    block_y = block_y + 1'b1;
		 else 
		    block_y = block_y - 1'b1;
	 end
	 else begin
	       block_x = block_x;
		   block_y = block_y;
	 end 	
end

//给不同的区域绘制不同的颜色
always @(posedge pixel_clk ) begin         
    if (!sys_rst_n) 
	    pixel_data <= BLACK;
	else  begin
	    if(  (pixel_xpos< SIDE_W)||(pixel_xpos>= H_DISP - SIDE_W)||(pixel_ypos< SIDE_W)||(pixel_ypos>= V_DISP - SIDE_W) )
	     pixel_data <= BLUE;
	    else if(  (pixel_xpos> block_x)&&(pixel_xpos<= block_x + BLOCK_W)&& (pixel_ypos> block_y)&&(pixel_ypos<= block_y + BLOCK_W) )
	     pixel_data <= BLACK;
		else
		 pixel_data <= WHITE;
    end  
end

endmodule 