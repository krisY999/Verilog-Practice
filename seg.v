module seg(
        clk,
		rst_n,
		
		key,
		  //
		led,
		seg,
		seg_sel
 )
 
 input clk;
 input rst_n;
 
 input [7:0]key;
 
 output [7:0]led;
 output [7:0]seg;
 output reg[2:0]seg_sel; 
 
 
 assign led = ~key;
 
 //--------------二进制码转成BCD码-----------------------8次移位，7次判断,先判断的话，8次判断，8次移位
 reg [3:0]unit;
 reg [3:0]ten;
 reg [3:0]hundred;
 
 integer i;
 
    always@(key) begin
         begin
		      unit =0;
			  ten = 0;
			 hundred = 0;
		 end 
	else
  begin 	
    for(i=7;i>=0;i--)  begin
         //judge
	   if(unit[2:0]>=3'd5)  begin  unit = unit + 2'd3;  else   unit =unit;
	   if(ten[2:0]>=3'd5)  begin  ten = ten + 2'd3;  else   ten =ten;
	   if(hundred[2:0]>=3'd5)  begin  hundred = hundred + 2'd3;  else   hundred =hundred;
	    //shift
	    hundred=hundred<<1;
        hundred[0]=ten[3];
		
		ten=ten<<1;
        ten[0]=unit[3];
		
		unit=unit<<1;
        unit[0]=key[7];
		key =key<<1;
	end
  end
  //--------------Seg_state switching---------------------
    reg [19:0]cnt;
	reg [1:0]state;
	
	always@(posedge clk or negedge rst_n) begin
       if(!rst_n)	begin
             state<=0;
			 cnt<=0;
		end
	  else  begin  
	        if(cnt>= 20'd250,000) begin  state<=state+1'd1;   cnt<=0; end			
			else   begin cnt<=cnt+1'd1;   state<=state;   end 
	  end
end
   //--------------Seg data&sel assignment-----------------  
     reg [3:0] seg_data;
     always@(state)
	 begin
	    case(state)
	     2'b00:   begin   seg_data<=unit[3:0]; seg_sel<=3'b110; end
	     2'b01:   begin   seg_data<=ten[3:0]; seg_sel<=3'b101; end
         2'b10:   begin   seg_data<=hundred[3:0]; seg_sel<=3'b011; end
         2'b11:   begin   seg_data<=unit[3:0]; seg_sel<=3'b110; end   //随便哪一个都行
        default: ;
		endcase
     end  
   
    //--------------Seg value converted to display-----------  
	reg [7:0] seg;
   
   always@(seg_data)
     begin
         case (seg_data)
           4'b0000: seg <= 8'b11000000;  //0
           4'b0001: seg <= 8'b11111001;  //1
           4'b0010: seg <= 8'b10100100;  //2
           4'b0011: seg <= 8'b10110000;  //3
           4'b0100: seg <= 8'b10011001;  //4
           4'b0101: seg <= 8'b10010010;  //5
           4'b0110: seg <= 8'b10000010;  //6
           4'b0111: seg <= 8'b11111000;  //7
           4'b1000: seg <= 8'b10000000;  //8
           4'b1001: seg <= 8'b10010000;  //9   
           default: seg <= 'bz;
         endcase
    end
	
endmodule	
	