module uart (
        input      clk,
        input uart_rx,
        output uart_tx,
        output reg [5:0]led,
        input KEYS1, KEYS2
    );

    parameter BAUDRATE_CNT = 27_000_000/115200;
    localparam  HALF_BAUD_CNT = BAUDRATE_CNT/2;

    //****************************************************
    //                     CLK counter
    //****************************************************

    localparam CLK_FREQ = 27_000_000;
    reg [$clog2(CLK_FREQ+1)-1:0] clk_counter=0;

    always @(posedge clk ) begin
        if (clk_counter==CLK_FREQ) begin
            clk_counter<=0;
        end
        else
            clk_counter<=clk_counter+1'b1;
    end




    localparam  RX_STATE_IDLE = 0;
    localparam  RX_STATE_START = 1;
    localparam  RX_STATE_WAIT_READ = 2;
    localparam  RX_STATE_READ = 3;
    localparam  RX_STATE_STOP = 4;

    reg [2:0] state=0;

    reg [$clog2(BAUDRATE_CNT+1)-1:0] baud_cnt=0;
    reg [2:0]bit_number=0;

    reg [7:0] recv_btye=0;

    reg byte_ok=0;

    always @(posedge clk ) begin
        case (state)
            RX_STATE_IDLE: begin
                if (~uart_rx) begin
                    state<=RX_STATE_START;
                    baud_cnt<=0;
                    byte_ok<=0;
                    bit_number<=0;
                end
            end
            RX_STATE_START: begin
                baud_cnt<=baud_cnt+1'b1;
                if (baud_cnt==HALF_BAUD_CNT-1) begin
                    baud_cnt<=0;
                    state<=RX_STATE_WAIT_READ;
                end
            end
            RX_STATE_WAIT_READ: begin
                baud_cnt<=baud_cnt+1'b1;
                if (baud_cnt == BAUDRATE_CNT-1) begin
                    state<=RX_STATE_READ;
                    baud_cnt<=0;
                end
            end

            RX_STATE_READ: begin
                baud_cnt<=baud_cnt+1'b1;
                recv_btye<={uart_rx,recv_btye[7:1]};
                state<=RX_STATE_WAIT_READ;
                bit_number<=bit_number+1'b1;
                if (bit_number==3'b111) begin
                    state<=RX_STATE_STOP;
                end
            end

            RX_STATE_STOP: begin
                baud_cnt<=baud_cnt+1'b1;
                if (baud_cnt==BAUDRATE_CNT-1) begin
                    state<=RX_STATE_IDLE;
                    baud_cnt<=0;
                end
                if (~uart_rx) begin
                    byte_ok<=1'b1;
                end
            end

        endcase
    end

    always @(posedge clk ) begin
        if (byte_ok) begin
            led<=~recv_btye[5:0];
        end
        else begin
            led<=6'b111111;
        end
    end

    //****************************************************
    //                     TX
    //****************************************************

    reg tx_reg=1;
    assign  uart_tx = tx_reg;

    localparam TX_MEM_LEN = 16;
    reg [7:0] tx_memory[TX_MEM_LEN-1:0];

    initial begin
        tx_memory[0]="H";
        tx_memory[1]="e";
        tx_memory[2]="l";
        tx_memory[3]="l";
        tx_memory[4]="o";
        tx_memory[5]=",";
        tx_memory[6]="x";
        tx_memory[7]="i";
        tx_memory[8]="a";
        tx_memory[9]="o";
        tx_memory[10]="t";
        tx_memory[11]="i";
        tx_memory[12]="a";
        tx_memory[13]="n";
        tx_memory[14]="!";
        tx_memory[15]="\n";
    end

    reg [$clog2(TX_MEM_LEN+1)-1:0] tx_mem_order=0;

    localparam TX_STATE_IDLE = 0;
    localparam TX_STATE_START = 1;
    localparam TX_STATE_SEND_BIT = 2;
    localparam TX_STATE_STOP = 3;
    localparam TX_STATE_DEBOUNCE =4;

    reg [7:0] tx_byte;
    reg [2:0] tx_bit_cnt;
    reg [$clog2(BAUDRATE_CNT+1)-1:0] tx_baud_cnt=0;
    reg [2:0] tx_state=0;

    always @(posedge clk ) begin
        case (tx_state)
            TX_STATE_IDLE: begin
                if (~KEYS1) begin       //如果按键按下后，触发一次发送
                    tx_bit_cnt<=0;
                    tx_baud_cnt<=0;
                    tx_mem_order<=1;
                    tx_byte<=tx_memory[0];
                    tx_state<=TX_STATE_START;
                end
            end
            TX_STATE_START: begin
                tx_reg<=1'b0;
                tx_baud_cnt<=tx_baud_cnt+1'b1;

                if (tx_baud_cnt==BAUDRATE_CNT-1) begin
                    tx_state<=TX_STATE_SEND_BIT;
                    tx_baud_cnt<=0;
                end
            end
            TX_STATE_SEND_BIT: begin
                tx_reg<=tx_byte[tx_bit_cnt];        //先发送低位
                tx_baud_cnt<=tx_baud_cnt+1'b1;

                if (tx_baud_cnt==BAUDRATE_CNT-1) begin
                    tx_baud_cnt<=0;
                    tx_bit_cnt<=tx_bit_cnt+1'b1;

                    if (tx_bit_cnt==3'b111) begin       //发送完7位了
                        tx_state<=TX_STATE_STOP;
                        tx_bit_cnt<=0;
                    end
                end
            end
            TX_STATE_STOP: begin
                tx_reg<=1'b1;
                tx_baud_cnt<=tx_baud_cnt+1'b1;

                if (tx_baud_cnt==BAUDRATE_CNT-1) begin
                    tx_baud_cnt<=0;

                    if (tx_mem_order<TX_MEM_LEN) begin      //如果没发完就继续发
                        tx_mem_order<=tx_mem_order+1'b1;
                        tx_byte<=tx_memory[tx_mem_order];
                        tx_state<=TX_STATE_START;
                        tx_bit_cnt<=0;
                    end
                    else begin
                        tx_state<=TX_STATE_DEBOUNCE;
                    end
                end
            end
            TX_STATE_DEBOUNCE: begin            //按键消抖
                if (clk_counter==CLK_FREQ) begin
                    tx_state<=TX_STATE_IDLE;
                end
            end
        endcase
    end


endmodule //uart
