// Descriptions:        等精度频率计模块，测量被测信号频率

module cymometer
   #(parameter    CLK_FS = 26'd50_000_000) // 基准时钟频率值
    (   //system clock
        input                 clk_fs ,     // 基准时钟信号
        input                 rst_n  ,     // 复位信号

        //cymometer interface
        input                 clk_fx ,     // 被测时钟信号
        output   reg [19:0]   data_fx      // 被测时钟频率输出
);

    localparam   GATE_TIME = 16'd5_000;        // 门控时间设置
    localparam   MAX       =  6'd32;           // 定义fs_cnt、fx_cnt的最大位宽

    reg        [15:0]   gate_cnt     ;           //门控计数
    reg                 gate       ;
    reg                 gate_fs     ;           // 同步到基准时钟的门控信号
    reg                 gate_fs_r   ;           // 用于同步gate信号的寄存器
    reg                 gate_fx_d0   ;
    reg                 gate_fx_d1   ;
    reg                 gate_fs_d0   ;
    reg                 gate_fs_d1   ;
    reg    [MAX-1:0]    fs_cnt      ;           // 门控时间内基准时钟的计数值
    reg    [MAX-1:0]    fs_cnt_temp ;           // fs_cnt 临时值
    reg    [MAX-1:0]    fx_cnt      ;           // 门控时间内被测时钟的计数值
    reg    [MAX-1:0]    fx_cnt_temp ;           // fx_cnt 临时值
    reg    [   63:0]   data_fx_t    ;

   wire               neg_gate_fs;            // 基准时钟下门控信号下降沿
   wire               neg_gate_fx;            // 被测时钟下门控信号下降沿



    //****************************main*********************

    assign          neg_gate_fs =  (!gate_fs_d0)&& gate_fs_d1;
    assign          neg_gate_fx =  (!gate_fx_d0)&& gate_fx_d1;


    //门控信号计数器，使用被测时钟计数
     always@(posedge clk_fx or negedge rst_n) begin
        if(!rst_n)
                gate_cnt <= 16'd0;
        else begin
                if(gate_cnt == GATE_TIME + 5'd20)
                  gate_cnt <= 16'd0 ;
                else begin
                  gate_cnt <= gate_cnt + 1'b1;
                end
         end
     end

    always@(posedge clk_fx or negedge rst_n) begin
      if(!rst_n)
            gate <= 0;
      else if(gate_cnt < 4'd10)
            gate <= 0;
      else if(gate_cnt < GATE_TIME + 4'd10)
            gate <= 1'b1;
      else if(gate_cnt <= GATE_TIME + 5'd20)
            gate <= 0;
      else
            gate <= 0;
    end

    //将门控信号同步到基准时钟下
    always@(posedge clk_fs or negedge rst_n) begin
      if(!rst_n)begin
            gate_fs <= 0;
            gate_fs_r <= 0;
      end
      else begin
            gate_fs_r <= gate;
            gate_fs <= gate_fs_r;
      end
   end

   always@(posedge clk_fx or negedge rst_n) begin
      if(!rst_n)begin
            gate_fx_d0 <= 0;
            gate_fx_d1 <= 0;
      end
      else begin
            gate_fx_d0 <= gate;
            gate_fx_d1 <= gate_fx_d0;
      end
    end

    always@(posedge clk_fs or negedge rst_n) begin
      if(!rst_n)begin
            gate_fs_d0 <= 0;
            gate_fs_d1 <= 0;
      end
      else begin
            gate_fs_d0 <= gate_fs;
            gate_fs_d1 <= gate_fs_d0;
      end
    end

     always@(posedge clk_fs or negedge rst_n) begin
      if(!rst_n)begin
            fs_cnt <= 0;
            fs_cnt_temp <= 0;
      end
      else if(gate_fs)
           fs_cnt_temp <= fs_cnt_temp + 1'b1;
      else if(neg_gate_fs)
           begin
              fs_cnt_temp <= 0;
              fs_cnt <= fs_cnt_temp;
           end
    end

    //门控时间内对被测时钟计数
    always@(posedge clk_fx or negedge rst_n) begin
      if(!rst_n)begin
            fx_cnt <= 0;
            fx_cnt_temp <= 0;
      end
      else if(gate)
           fx_cnt_temp <= fx_cnt_temp + 1'b1;
      else if(neg_gate_fx)
           begin
              fx_cnt_temp <= 0;
              fx_cnt <= fx_cnt_temp;
           end
    end

    //calculate frequency
    always@(posedge clk_fs or negedge rst_n) begin
      if(!rst_n)begin
            data_fx_t <= 0;
      end
      else if(gate_fs == 0)begin
            data_fx_t <= fx_cnt * CLK_FS;
      end
   end
     
    always@(posedge clk_fs or negedge rst_n) begin
      if(!rst_n)begin
            data_fx <= 0;
      end
      else if(gate_fs == 0)begin
            data_fx <= data_fx_t / fs_cnt;
      end
   end


endmodule