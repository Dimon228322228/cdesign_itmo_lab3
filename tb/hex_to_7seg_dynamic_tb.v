`timescale 1ns / 1ps

module hex_to_7seg_dynamic_tb;
    reg         clk;
    reg         reset;
    reg         start;
    reg  [15:0] value;
    wire        busy;
    wire [7:0]  SEG_DATA;
    wire [7:0]  SEG_SEL;

    hex_to_7seg_dynamic #(
        .REFRESH_DIV(200), 
        .PASSES(2)
    ) uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .value(value),
        .busy(busy),
        .SEG_DATA(SEG_DATA),
        .SEG_SEL(SEG_SEL)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task pulse_start;
        input [15:0] v;
        begin
            @(posedge clk);
            value = v;
            start = 1'b1;
            @(posedge clk);
            start = 1'b0;
            wait (busy == 1'b1);
            wait (busy == 1'b0);
            repeat (20) @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("hex_to_7seg_dynamic_tb.vcd");
        $dumpvars(0, hex_to_7seg_dynamic_tb);

        reset = 1'b1;
        start = 1'b0;
        value = 16'h0000;
        repeat (4) @(posedge clk);
        reset = 1'b0;
        repeat (2) @(posedge clk);

        pulse_start(16'h1234);
        pulse_start(16'hABCD);
        pulse_start(16'h00F0);
        pulse_start(16'h0002);

        $display("DONE: hex_to_7seg_dynamic_tb.vcd");
        $finish;
    end
endmodule
