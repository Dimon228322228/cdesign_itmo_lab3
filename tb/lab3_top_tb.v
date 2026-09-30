`timescale 1ns / 1ps

module lab3_top_tb;
    reg         CLK;
    reg         RST_N;
    reg         KEY2_N;
    reg  [16:0] GPIO_1_input_pullup;
    wire [3:0]  LED;
    wire [7:0]  SEG_DATA;
    wire [7:0]  SEG_SEL;

    lab3_top uut (
        .CLK(CLK),
        .RST_N(RST_N),
        .KEY2_N(KEY2_N),
        .GPIO_1_input_pullup(GPIO_1_input_pullup),
        .LED(LED),
        .SEG_DATA(SEG_DATA),
        .SEG_SEL(SEG_SEL)
    );

    defparam uut.u_disp.REFRESH_DIV = 200;
    defparam uut.u_disp.PASSES      = 2;
    defparam uut.u_key2.CNT_MAX     = 2;

    initial CLK = 0;
    always #5 CLK = ~CLK; 

    task press_key2;
        begin
            KEY2_N = 1'b0;
            repeat (10) @(posedge CLK);
            KEY2_N = 1'b1;
            repeat (10) @(posedge CLK);
        end
    endtask

    initial begin
        $dumpfile("lab3_top_tb.vcd");
        $dumpvars(0, lab3_top_tb);

        RST_N = 1'b0;
        KEY2_N = 1'b1;
        GPIO_1_input_pullup = {1'b0, 8'd8, 8'd3}; // y=2
        repeat (20) @(posedge CLK);
        RST_N = 1'b1;
        wait (LED[0] == 1'b1);
        repeat (10) @(posedge CLK);

        press_key2();
        wait (LED[0] == 1'b0);
        wait (LED[0] == 1'b1);
        $display("cycle1 done, back IDLE");

        GPIO_1_input_pullup = {1'b0, 8'd27, 8'd7}; // y=3
        press_key2();
        wait (LED[0] == 1'b0);
        wait (LED[0] == 1'b1);
        $display("cycle2 done");

        $display("DONE: lab3_top_tb.vcd");
        $finish;
    end

    initial begin
        #5_000_000;
        $display("FAIL: timeout");
        $finish;
    end
endmodule
