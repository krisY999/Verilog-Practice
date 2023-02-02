module gmii_to_rgmii(
    input              idelay_clk  , //IDELAYʱ��
     //��̫��GMII�ӿ�
    output             gmii_rx_clk , //GMII����ʱ��
    output             gmii_rx_dv  , //GMII����������Ч�ź�
    output      [7:0]  gmii_rxd    , //GMII��������
    output             gmii_tx_clk , //GMII����ʱ��
    input              gmii_tx_en  , //GMII��������ʹ���ź�
    input       [7:0]  gmii_txd    , //GMII��������         
     //��̫��RGMII�ӿ�   
    input              rgmii_rxc   , //RGMII����ʱ��
    input              rgmii_rx_ctl, //RGMII�������ݿ����ź�
    input       [3:0]  rgmii_rxd   , //RGMII��������
    output             rgmii_txc   , //RGMII����ʱ��    
    output             rgmii_tx_ctl, //RGMII�������ݿ����ź�
    output      [3:0]  rgmii_txd     //RGMII��������  
    );
    
    //parameter define
    parameter IDELAY_VALUE = 0;  //��������IO��ʱ(���Ϊn,��ʾ��ʱn*78ps) 
    
    assign gmii_tx_clk = gmii_rx_clk;
    
    
    rgmii_rx  u_rgmii_rx(
        .idelay_clk             (idelay_clk), //200Mhzʱ�ӣ�IDELAYʱ��   
        .rgmii_rxc              (rgmii_rxc), //RGMII����ʱ��
        .rgmii_rx_ctl           (rgmii_rx_ctl), //RGMII�������ݿ����ź�
        .rgmii_rxd              (rgmii_rxd), //RGMII��������    
        .gmii_rx_clk            (gmii_rx_clk), //GMII����ʱ��
        .gmii_rx_dv             (gmii_rx_dv), //GMII����������Ч�ź�
        .gmii_rxd               (gmii_rxd)  //GMII��������   
    );
    
    rgmii_tx  u_rgmii_tx(
        .gmii_tx_clk                 (gmii_tx_clk), //GMII����ʱ��    
        .gmii_tx_en                  (gmii_tx_en), //GMII���������Ч�ź�
        .gmii_txd                    (gmii_txd), //GMII�������        
        .rgmii_txc                   (rgmii_txc), //RGMII��������ʱ��    
        .rgmii_tx_ctl                (rgmii_tx_ctl), //RGMII���������Ч�ź�
        .rgmii_txd                   (rgmii_txd)   //RGMII�������   
    );
    
    
    
endmodule
