`timescale  1ns/1ns
module testbench();


    reg clk;
    reg uart_rx;

    always #1 clk=~clk;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, testbench);
        #6000 $finish;
    end

    initial begin
        clk=1;
        uart_rx=1;

        #40 uart_rx=0;
        #16 uart_rx=1;
        #16 uart_rx=0;
        #16 uart_rx=1;
        #16 uart_rx=0;
        #16 uart_rx=1;
        #16 uart_rx=0;
        #16 uart_rx=1;
        #16 uart_rx=0;
        #16 uart_rx=1;
    end

    //Instance
    wire 	uart_tx;
    wire [5:0]	led;

    uart #(
             .BAUDRATE_CNT 		( 8 		))
         u_uart(
             //ports
             .clk     		( clk     		),
             .uart_rx 		( uart_rx 		),
             .uart_tx 		(  		),
             .led     		( led     		),
             .KEYS1   		(    		),
             .KEYS2   		(    		)
         );



    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, testbench);
        #50000 $finish;
    end

endmodule  //TOP
