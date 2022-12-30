module pcf8563_ctrl #(
// 初始时间设置，从高到低为年到秒，各占 8bit
 parameter TIME_INIT = 48'h19_10_26_09_30_00)(
	 input clk , //时钟信号
	 input rst_n , //复位信号
	 
	 //i2c interface
	 output reg i2c_rh_wl , //I2C 读写控制信号
	 output reg i2c_exec , //I2C 触发执行信号
	 output reg [15:0] i2c_addr , //I2C 器件内地址
	 output reg [7:0] i2c_data_w, //I2C 要写的数据
	 input [7:0] i2c_data_r, //I2C 读出的数据
	 input i2c_done , //I2C 一次操作完成
	 
	 //PCF8563T 的秒、分、时、日、月、年数据
	 output reg [7:0] sec, //秒
	 output reg [7:0] min, //分
	 output reg [7:0] hour, //时
	 output reg [7:0] day, //日
	 output reg [7:0] mon, //月
	 output reg [7:0] year //年
 );
  	
  	reg [3:0]   	flow_cnt;
  	reg [12:0]		wait_cnt;


  	//先向 PCF8563 中写入初始化日期和时间，再从中读出日期和时间
  	always @(posedge clk or negedge rst_n) begin   //dri_clk的周期为1us,1Mhz的时钟
  		if (rst_n) begin
  			i2c_rh_wl <= 0;      //初始为0:写
  			i2c_exec <= 0;
  			i2c_addr <= 0;
			i2c_data_w <= 0;
			sec <= 0;
  			min <= 0;
  			hour <= 0;
  			day  <= 0;
  			mon <= 0;
  			year <= 0;
  			flow_cnt <= 0;
  			wait_cnt <= 0;
  		end
  		else begin
  	 		i2c_exec <= 1’b0;	
  	 		case(flow_cnt)
  	 		//上电初始化
	 			4'd0:begin
	 			 	if(wait_cnt == 13'd8000)    //8ms 的power-on,dri_clk周期为1us
	 			    begin
	 			    	 flow_cnt <= flow_cnt + 1'b1;
	 			    	 wait_cnt <= 0;
	 			    end
	 			    else begin
	 			    	wait_cnt <= wait_cnt + 1'b1;
	 			    end
	 		    end
	 		 //写读秒
	 		    4'd1:begin
	 		    	 i2c_exec <= 1'b1;
	 		    	 i2c_addr <= 8'h02;
	 		    	 i2c_data_w <= TIME_INIT[7:0];
	 		    	 flow_cnt <= flow_cnt + 1'b1;
 				end

 				4'd2:begin
 					if(i2c_done)begin
 						sec <= i2c_data_r[6:0];
 						flow_cnt <= flow_cnt + 1'b1;
 					end
 				end
			  //写读分
	 		    4'd3:begin
	 		    	 i2c_exec <= 1'b1;
	 		    	 i2c_addr <= 8'h03;
	 		    	 i2c_data_w <= TIME_INIT[15:8];
	 		    	 flow_cnt <= flow_cnt + 1'b1;
 				end

 				4'd4:begin
 					if(i2c_done)begin
 						min <= i2c_data_r[6:0];
 						flow_cnt <= flow_cnt + 1'b1;
 					end
 				end
				//写读时
	 		    4'd5:begin
	 		    	 i2c_exec <= 1'b1;
	 		    	 i2c_addr <= 8'h04;
	 		    	 i2c_data_w <= TIME_INIT[23:16];
	 		    	 flow_cnt <= flow_cnt + 1'b1;
 				end

 				4'd6:begin
 					if(i2c_done)begin
 						hour <= i2c_data_r[5:0];
 						flow_cnt <= flow_cnt + 1'b1;
 					end
 				end

				//写读day
	 		    4'd7:begin
	 		    	 i2c_exec <= 1'b1;
	 		    	 i2c_addr <= 8'h05;
	 		    	 i2c_data_w <= TIME_INIT[31:24];
	 		    	 flow_cnt <= flow_cnt + 1'b1;
 				end

 				4'd8:begin
 					if(i2c_done)begin
 						day <= i2c_data_r[5:0];
 						flow_cnt <= flow_cnt + 1'b1;
 					end
 				end

				//写读月
	 		    4'd9:begin
	 		    	 i2c_exec <= 1'b1;
	 		    	 i2c_addr <= 8'h07;
	 		    	 i2c_data_w <= TIME_INIT[39:32];
	 		    	 flow_cnt <= flow_cnt + 1'b1;
 				end

 				4'd10:begin
 					if(i2c_done)begin
 						mon <= i2c_data_r[4:0];
 						flow_cnt <= flow_cnt + 1'b1;
 					end
 				end

				//写读year
	 		    4'd11:begin
	 		    	 i2c_exec <= 1'b1;
	 		    	 i2c_addr <= 8'h08;
	 		    	 i2c_data_w <= TIME_INIT[47:40];
	 		    	 flow_cnt <= flow_cnt + 1'b1;
 				end

 				4'd12:begin
 					if(i2c_done)begin
 						year <= i2c_data_r[7:0];
 						flow_cnt <= 1'b1;
 						i2c_rh_wl <= 1'b1;
 					end
 				end
 				default: flow_cnt <= 4'd0;
	 		endcase
  		end
  	end
endmodule