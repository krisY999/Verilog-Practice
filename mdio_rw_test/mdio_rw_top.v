module mdio_rw_test(
    input 	sys_clk,
    input 	sys_rst_n,

    output 	eth_mdc,
    inout 	eth_mdio,
    output 	eth_rst_n,

    input 	touch_key,
    output   [1:0] led    //LED连接速率指示
	);

    //wire define
    wire  		op_exec;
    wire	[4:0]	op_addr;
    wire  		op_rh_wl;
    wire	[15:0]	op_wr_data;
    wire		op_done;
    wire		op_rd_ack;
    wire		dri_clk ;
    wire	[15:0]	op_rd_data;    

    
    assign 		eth_rst_n = sys_rst_n;

    mdio_dri #(
    .PHY_ADDR 			  (5'h19),    //PHY地址
    .CLK_DIV  			  (6'd10)    //分频系数
   )
    u_mdio_dri(
    .clk       			(sys_clk), 			//时钟信号
    .rst_n     			(sys_rst_n), 		//复位信号,低电平有效
    .op_exec   			(op_exec), 			//触发开始信号
    .op_addr   			(op_addr), 			//
    .op_rh_wl  			(op_rh_wl),
    .op_wr_data			(op_wr_data), 		//写入寄存器的数据
    .op_done   			(op_done),
    .op_rd_ack 			(op_rd_ack), 		//读应答信号 0:应答 1:未应答
    .op_rd_data			(op_rd_data),  		//读出的数据
    .dri_clk   			(dri_clk),

    .eth_mdc   			(eth_mdc), 			//PHY管理接口的时钟信号
    .eth_mdio  			(eth_mdio) 			//PHY管理接口的双向数据信号
    );



    mdio_ctrl  u_mdio_ctrl(
    .clk           			(dri_clk),
    .rst_n         			(sys_rst_n),
    .soft_rst_trig 			(touch_key), //软复位触发信号
    .op_done       			(op_done), //读写完成
    .op_rd_data    			(op_rd_data), //读出的数据
    .op_rd_ack     			(op_rd_ack), //读应答信号 0:应答 1:未应答
    .op_exec       			(op_exec), //触发开始信号
    .op_rh_wl      			(op_rh_wl), //低电平写，高电平读
    .op_addr       			(op_addr), //寄存器地址
    .op_wr_data    			(op_wr_data), //写入寄存器的数据
    .led           			(led) //LED灯指示以太网连接状态
    );

endmodule