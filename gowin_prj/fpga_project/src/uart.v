module uart (
        input      clk,
        input uart_rx,
        output reg uart_tx,
        output reg [5:0]led,
        input KEYS1, KEYS2
    );

    parameter BAUDRATE_CNT = 27_000_000/115200;
    localparam  HALF_BAUD_CNT = BAUDRATE_CNT/2;



    localparam  STATE_IDLE = 0;
    localparam  STATE_START = 1;
    localparam  STATE_WAIT_READ = 2;
    localparam  STATE_READ = 3;
    localparam  STATE_STOP = 4;

    reg [2:0] state=0, next=0;

    reg [$clog2(BAUDRATE_CNT+1)-1:0] baud_cnt=0;
    reg [2:0]bit_number=0;

    reg [7:0] recv_btye=0;

    reg byte_ok=0;

    always @(posedge clk ) begin
        case (state)
            STATE_IDLE: begin
                if (~uart_rx) begin
                    state<=STATE_START;
                    baud_cnt<=0;
                    byte_ok<=0;
                    bit_number<=0;
                end
            end
            STATE_START: begin
                baud_cnt<=baud_cnt+1'b1;
                if (baud_cnt==HALF_BAUD_CNT-1) begin
                    baud_cnt<=0;
                    state<=STATE_WAIT_READ;
                end
            end
            STATE_WAIT_READ: begin
                baud_cnt<=baud_cnt+1'b1;
                if (baud_cnt == BAUDRATE_CNT-1) begin
                    state<=STATE_READ;
                    baud_cnt<=0;
                end
            end

            STATE_READ: begin
                baud_cnt<=baud_cnt+1'b1;
                recv_btye<={uart_rx,recv_btye[7:1]};
                state<=STATE_WAIT_READ;
                bit_number<=bit_number+1'b1;
                if (bit_number==3'b111) begin
                    state<=STATE_STOP;
                end
            end

            STATE_STOP: begin
                baud_cnt<=baud_cnt+1'b1;
                if (baud_cnt==BAUDRATE_CNT-1) begin
                    state<=STATE_IDLE;
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


endmodule //uart
