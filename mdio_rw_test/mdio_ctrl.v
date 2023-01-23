module mdio_ctrl(
    input                clk           ,    //T=80ns  12.5M(dri_clk)
    input                rst_n         ,
    input                soft_rst_trig , //软复位触发信号
    input                op_done       , //读写完成
    input        [15:0]  op_rd_data    , //读出的数据
    input                op_rd_ack     , //读应答信号 0:应答 1:未应答
    output  reg          op_exec       , //触发开始信号
    output  reg          op_rh_wl      , //低电平写，高电平读
    output  reg  [4:0]   op_addr       , //寄存器地址
    output  reg  [15:0]  op_wr_data    , //写入寄存器的数据
    output       [1:0]   led             //LED灯指示以太网连接状态
    );



    reg          rst_trig_d0;    
    reg          rst_trig_d1;  
    reg          rst_trig_flag;  
    reg  [1:0]   speed_status;
    reg  [1:0]   flow_cnt   ;
    reg  [23:0]  timer_cnt;
    reg          timer_done ;  //定时完成
    

    wire         pos_rst_trig;    //soft_rst_trig信号上升沿

    //采soft_rst_trig信号上升沿
    assign      pos_rst_trig = rst_trig_d0 & (~rst_trig_d1);
    //连接速率 00:未连接或连接失败 01:10Mbps  10:100Mbps  11:1000Mbps
    assign led = speed_status;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_trig_d0 <= 0;
            rst_trig_d1 <= 0;
        end
        else  begin
            rst_trig_d0 <= soft_rst_trig;
            rst_trig_d1 <= rst_trig_d0; 
        end
    end


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
             timer_cnt <= 0;
             timer_done <= 0;
        end
        else if(timer_cnt == 24'd1000000 - 1'b1) begin    //每80us获取一次PHY的状态
                timer_done <= 1'b1;
                timer_cnt <= 0;
        end
        else begin
            timer_cnt <= timer_cnt + 1'b1;
            timer_done <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            op_exec <= 0;
            rst_trig_flag <= 0;
            op_rh_wl <= 0;    //先写
            speed_status <= 0;
            op_addr <= 0;
            op_wr_data <= 0;
            flow_cnt <= 0;
        end
        else  begin
            op_exec <= 0;
            if(pos_rst_trig)
                rst_trig_flag <= 1'b1;
            case(flow_cnt)
                2'd0:begin
                        if(rst_trig_flag) begin   //先写
                            op_exec <= 1'b1;
                            op_rh_wl <= 1'b0;
                            flow_cnt <= 2'd1;
                            op_addr <= 5'd0;
                            op_wr_data <= 16'hB100; //Bit[15]=1'b1,表示软复位
                        end
                        else if(timer_done) begin //定时完成后read
                            op_exec <= 1'b1;
                            op_rh_wl <= 1'b1;
                            op_addr <= 5'h19;
                            flow_cnt <= 2'd2;
                        end

                end

                2'd1:begin
                         if(op_done)begin
                             op_exec <= 0;
                             rst_trig_flag <= 0;
                             flow_cnt <= 2'd0;
                         end
                end

                 2'd2:begin
                        if(op_done)begin
                             if(!op_rd_ack)begin
                                 op_exec <= 0;
                                 flow_cnt <= 2'd3;
                             end
                             else begin
                                 flow_cnt <= 2'd0;
                                 op_exec <= 0;
                             end
                        end
                end

                2'd3: begin
                         flow_cnt <= 0;
                        if(op_rd_data[15] && op_rd_data[2])begin
                              if(op_rd_data[10:9] == 2'b11)
                                    speed_status <= 2'b11;   //1000 M
                              else if((op_rd_data[10:9] == 2'b10) || (op_rd_data[10:8] == 3'b011))
                                    speed_status <= 2'b10;   //100 M ETH
                              else if((op_rd_data[10:8] == 3'b010) || (op_rd_data[10:8] == 3'b001))
                                    speed_status <= 2'b01;   //10 M 
                              else
                                    speed_status <= 2'b00;   //连接失败或者自协商尚未完成
                        end
                        else begin
                            speed_status <= 2'b00;    //连接失败或者自协商尚未完成
                        end
                end
            endcase
        end
    end

endmodule