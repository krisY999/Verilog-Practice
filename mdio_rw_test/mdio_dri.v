module mdio_dri #(
    parameter  PHY_ADDR = 5'h19,    //PHY地址
    parameter  CLK_DIV  = 6'd10    //分频系数
   )
    (
    input                clk       , //时钟信号
    input                rst_n     , //复位信号,低电平有效
    input                op_exec   , //触发开始信号
    input       [4:0]    op_addr   , //
    input                op_rh_wl  ,
    input      [15:0]    op_wr_data, //写入寄存器的数据
    output  reg          op_done   ,
    output  reg          op_rd_ack , //读应答信号 0:应答 1:未应答
    output  reg [15:0]   op_rd_data,
    output  reg          dri_clk   , //驱动时钟，至少是mdc频率的2倍

    output  reg          eth_mdc   , //PHY管理接口的时钟信号
    inout                eth_mdio    //PHY管理接口的双向数据信号
    );

    //parameter define
    localparam st_idle    = 6'b00_0001;  //空闲状态
    localparam st_pre     = 6'b00_0010;  //发送前导码
    localparam st_start   = 6'b00_0100;  //开始状态,发送ST(开始)+OP(操作码)
    localparam st_addr    = 6'b00_1000;  //写地址,发送PHY地址+寄存器地址
    localparam st_wr_data = 6'b01_0000;  //TA+写数据
    localparam st_rd_data = 6'b10_0000;  //TA+读数据


    //reg define
    reg        [5:0]        cur_state   ;
    reg        [5:0]        next_state  ;

    reg                     mdio_dir    ;      //MDIO数据方向控制
    reg                     mdio_out    ;
    reg         [5:0]        clk_cnt    ;         //分频计数   
    reg         [6:0]       cnt         ;         //计数器
    reg                     st_done     ;         //状态开始跳转信号
    reg         [1:0]       op_code     ;       //操作码  2'b01(写)  2'b10(读)  
    reg         [4:0]       addr_t      ;           //缓存寄存器地址
    reg         [15:0]      wr_data_t   ;
    reg         [15:0]      rd_data_t   ;



    //wire define
    wire                    mdio_in ;
    wire   [5:0]            clk_divide ;   //dri_clk的分频系数



    //
    //
    //main logic
    assign  eth_mdio = mdio_dir ? mdio_out:1'bz;
    assign  mdio_in  =  eth_mdio ;

    //将PHY_CLK的分频系数除以2,得到dri_clk的分频系数,方便对MDC和MDIO信号操作
    assign  clk_divide = CLK_DIV >> 1;   //==5


    //偶数分频，有误差，得到dri_clk
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt <= 0;
            dri_clk <= 0;
        end
        else if (clk_cnt == clk_divide[5:1] - 1'b1) begin
            clk_cnt <= 0;
            dri_clk <= ~dri_clk;
        end
        else begin
            clk_cnt <= clk_cnt + 1'b1;
        end
    end



    //得到 eth_mdc
    always @(posedge dri_clk or negedge rst_n) begin
        if (!rst_n) begin
            eth_mdc <= 1'b1;
        end
        else if (cnt[0] == 0) begin
            eth_mdc <= 1'b1;
        end
        else begin
            eth_mdc <= 1'b0;
        end
    end


   always @(posedge dri_clk or negedge rst_n) begin
       if (!rst_n) begin
           cur_state <= st_idle     ;
       end
       else begin
           cur_state <= next_state  ;
       end
   end


   always@(*) begin
         next_state = st_idle;
         case(cur_state)
            st_idle:  begin
                        if(op_exec)
                            next_state = st_pre;
                      else begin
                            next_state = st_idle;
                      end
                     end

             st_pre:  begin
                        if(st_done)
                            next_state = st_start;
                      else begin
                            next_state = st_pre;
                      end
                    end

             st_start:  begin
                        if(st_done)
                            next_state = st_addr;
                      else begin
                            next_state = st_start;
                      end
                    end

              st_addr:  begin
                        if(st_done)begin
                              if(op_code == 2'b01)
                                  next_state = st_wr_data;
                              else                 
                                  next_state = st_rd_data;
                        end
                        else begin
                                      next_state = st_addr;
                        end
                    end
              
              st_wr_data:  begin
                        if(st_done)
                            next_state = st_idle;
                        else begin
                            next_state = st_wr_data;
                        end
                    end

              st_rd_data:  begin
                        if(st_done)
                            next_state = st_idle;
                        else begin
                            next_state = st_rd_data;
                        end
                    end
         
            default:  next_state = st_idle;
         endcase
   end



   //state output
   always @(posedge dri_clk or negedge rst_n) begin
       if (!rst_n) begin
           cnt <=   0     ;
           op_code <= 0   ;
           op_done <= 1'b0;
           st_done <= 1'b0;
           op_rd_ack <= 1'b1;
           op_rd_data <= 16'd0;
           addr_t <= 0;
           wr_data_t <= 0;
           rd_data_t <= 0;
           mdio_dir <= 1'b0;
           mdio_out <= 1'b1;   //都可以
       end
       else begin
           st_done <= 1'b0  ;
           cnt <= cnt + 1'b1;
           case(cur_state)
                st_idle : begin
                     mdio_dir <= 1'b0;
                     mdio_out <= 1'b1;   //都可以
                     op_done  <= 0;
                     cnt <= 7'd0;
                     if(op_exec)begin
                         op_code <= {op_rh_wl,~op_rh_wl};   //OP_CODE: 2'b01(写)  2'b10(读) 
                         addr_t <= op_addr;
                         wr_data_t <= op_wr_data;
                         op_rd_ack <= 1'b1;
                     end
                end

                st_pre :begin
                      mdio_dir <= 1'b1;                   //切换MDIO引脚方向:输出
                      mdio_out <= 1'b1;                   //MDIO引脚输出高电平,发32个1 
                      if(cnt == 7'd62)
                         st_done <= 1'b1;
                      else if(cnt == 7'd63)
                         cnt <= 0;
                end

                st_start:begin
                      case(cnt)
                         7'd1 : mdio_out <= 1'b0;        //发送开始信号 2'b01      
                         7'd3 : mdio_out <= 1'b1; 
                         7'd5 : mdio_out <= op_code[1];
                         7'd6 : st_done <= 1'b1;    //提前一个时钟周期拉高，因为next给cur还需要一个周期dri_clk
                         7'd7 : begin
                                cnt <= 0;
                                mdio_out <= op_code[0];
                         end
                        default: ;
                      endcase
                end

                st_addr: begin
                      case(cnt)
                         7'd1 : mdio_out <= PHY_ADDR[4];            
                         7'd3 : mdio_out <= PHY_ADDR[3]; 
                         7'd5 : mdio_out <= PHY_ADDR[2];
                         7'd7 : mdio_out <= PHY_ADDR[1];    
                         7'd9 : mdio_out <= PHY_ADDR[0];  
                         7'd11: mdio_out <= addr_t[4];  //发送寄存器地址
                         7'd13: mdio_out <= addr_t[3];
                         7'd15: mdio_out <= addr_t[2];
                         7'd17: mdio_out <= addr_t[1]; 
                         7'd18 : st_done <= 1'b1;    //提前一个时钟周期拉高，因为next给cur还需要一个周期dri_clk
                         7'd19 : begin
                                cnt <= 0;
                                mdio_out <= addr_t[0];
                         end
                        default: ;
                      endcase
                end

                st_wr_data: begin
                      case(cnt)
                         7'd1 : mdio_out <= 1'b1;            //TA位 ：写为10
                         7'd3 : mdio_out <= 1'b0; 
                         7'd5 : mdio_out <= wr_data_t[15];
                         7'd7 : mdio_out <= wr_data_t[14];    
                         7'd9 : mdio_out <= wr_data_t[13];  
                         7'd11: mdio_out <= wr_data_t[12];  
                         7'd13: mdio_out <= wr_data_t[11];
                         7'd15: mdio_out <= wr_data_t[10];
                         7'd17: mdio_out <= wr_data_t[9]; 
                         7'd19: mdio_out <= wr_data_t[8];  
                         7'd21: mdio_out <= wr_data_t[7];
                         7'd23: mdio_out <= wr_data_t[6];
                         7'd25: mdio_out <= wr_data_t[5]; 
                         7'd27: mdio_out <= wr_data_t[4];
                         7'd29: mdio_out <= wr_data_t[3];
                         7'd31: mdio_out <= wr_data_t[2];
                         7'd33: mdio_out <= wr_data_t[1];
                         7'd35: mdio_out <= wr_data_t[0];
                         7'd37: begin
                                    mdio_dir <= 1'b0;
                                    mdio_out <= 1'b1;
                                end
                         7'd39 : st_done <= 1'b1;    //提前一个时钟周期拉高，因为next给cur还需要一个周期dri_clk
                         7'd40 : begin
                                cnt <= 0;
                                op_done <= 1'b1;      //写操作完成
                         end
                        default: ;
                      endcase
                end

                st_rd_data: begin
                      case(cnt)
                         7'd1 : begin
                                mdio_dir <= 1'b0;     //MDIO引脚切换成输入
                                mdio_out <= 1'b1;
                         end
                         7'd2 : ;    //TA[1]位,该位为高阻状态,不操作
                         7'd4 : op_rd_ack <= mdio_in;   //TA[0]位,0(应答) 1(未应答)
                         7'd6 : rd_data_t[15] <= mdio_in; 
                         7'd8 : rd_data_t[14] <= mdio_in; 
                         7'd10 :rd_data_t[13] <= mdio_in;    
                         7'd12 :rd_data_t[12] <= mdio_in;   
                         7'd14: rd_data_t[11] <= mdio_in;  
                         7'd16: rd_data_t[10] <= mdio_in; 
                         7'd18: rd_data_t[9] <= mdio_in; 
                         7'd20: rd_data_t[8] <= mdio_in; 
                         7'd22: rd_data_t[7] <= mdio_in;  
                         7'd24: rd_data_t[6] <= mdio_in; 
                         7'd26: rd_data_t[5] <= mdio_in;
                         7'd28: rd_data_t[4] <= mdio_in; 
                         7'd30: rd_data_t[3] <= mdio_in; 
                         7'd32: rd_data_t[2] <= mdio_in;  
                         7'd34: rd_data_t[1] <= mdio_in; 
                         7'd36: rd_data_t[0] <= mdio_in;

                         7'd39 : st_done <= 1'b1;    //提前一个时钟周期拉高，因为next给cur还需要一个周期dri_clk
                         7'd40 : begin
                                cnt <= 0;
                                op_done <= 1'b1;      //读操作完成
                                op_rd_data <= rd_data_t;
                                rd_data_t <= 16'd0;
                         end
                         default: ;
                      endcase
                end


                default: ;
          endcase          
       end
   end

endmodule