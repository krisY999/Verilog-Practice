module key_debounce(
      input 	clk,
      input 	rst_n,
	  input     key,
      
      output    key_value,
	  output	key_flag//标志按键抖动结束，数据有效
    );
    
     reg [19:0] cnt;
	 reg key_reg;
    
    always@(posedge clk or negedge rst_n) begin
       if(!rst_n)begin
            cnt <= 0;
			key_reg <= 1'b1;
        end
       else  begin
	        key_reg <= key;
		    if(key_reg != key)
			  cnt <= 20'd1000000;
			else begin 
			if(cnt > 20'd0)
			  cnt <= cnt - 1'b1;
			else
			  cnt <= cnt;
		    end
		end
   end
    
	
   always@(posedge clk or negedge rst_n) begin
       if(!rst_n)begin  
        key_value <= 1'b1;
		key_flag <= 0;
	   end
	   else if(cnt == 20'd1)
        begin  
         key_value <= key;
		 key_flag <= 1'b1; 
        end		
	   else begin
	     key_value <= key_value;
		 key_flag <= 0; 
	   end
	     
   end
  
    
endmodule







