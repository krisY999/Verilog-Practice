//异步复位，同步释放，并转换成高电平有效

module asyn_rst_syn(
    input clk,          //目的时钟域
    input reset_n,      //异步复位，低有效
    
    output syn_reset    //高有效
    );
	
	
	reg  rst1;
	reg  rst2;
	
	assign syn_reset = rst2;
	
	
	always@(posedge clk or negedge reset_n)begin
	if(!reset_n)begin
	      rst1 <= 1'b1;
		  rst2 <= 1'b1;
	end
	else begin
	      rst1 <= 0;
		  rst2 <= rst1;	
	end
end	