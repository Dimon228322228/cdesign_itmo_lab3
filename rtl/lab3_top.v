`timescale 1ns / 1ps

module lab3_top (
    input  wire        CLK,
    input  wire        RST_N,
    input  wire        KEY2_N,
    input  wire [16:0] GPIO_1_input_pullup,
    output wire [3:0]  LED,
    output wire [7:0]  SEG_DATA,
    output wire [7:0]  SEG_SEL
);

    localparam IDLE      = 3'd0;
    localparam START     = 3'd1;
    localparam WORK      = 3'd2;
    localparam START_SEG = 3'd3;
    localparam WAIT_SEG  = 3'd4;

    wire clk = CLK;
    wire reset = ~RST_N;

    wire [7:0] a_in = GPIO_1_input_pullup[7:0];
    wire [7:0] b_in = GPIO_1_input_pullup[15:8];

    wire key2_press;
    btn_sync u_key2 (
        .clk(clk),
        .reset(reset),
        .btn_n(KEY2_N),
        .press(key2_press)
    );

    reg [2:0] state;
    reg       func_start;
    reg       seg_start;
    reg       func_armed;
    reg       seg_armed;
    reg [15:0] result;

    wire       busy_func;
    wire [4:0] y_func;

    func_calc u_func (
        .clk(clk),
        .reset(reset),
        .start(func_start),
        .a(a_in),
        .b(b_in),
        .busy(busy_func),
        .y(y_func)
    );

    wire       busy_seg;
    hex_to_7seg_dynamic #(
        .REFRESH_DIV(100_000), // 1 мс/цифру при 100 МГц
        .PASSES(8)
    ) u_disp (
        .clk(clk),
        .reset(reset),
        .start(seg_start),
        .value(result),
        .busy(busy_seg),
        .SEG_DATA(SEG_DATA),
        .SEG_SEL(SEG_SEL)
    );

    assign LED[0] = (state == IDLE);
    assign LED[1] = busy_func;
    assign LED[2] = busy_seg;
    assign LED[3] = 1'b0;

    always @(posedge clk) begin
        if (reset) begin
            state      <= IDLE;
            func_start <= 1'b0;
            seg_start  <= 1'b0;
            func_armed <= 1'b0;
            seg_armed  <= 1'b0;
            result     <= 16'd0;
        end else begin
            func_start <= 1'b0;
            seg_start  <= 1'b0;

            case (state)
                IDLE: begin
                    func_armed <= 1'b0;
                    seg_armed  <= 1'b0;
                    if (key2_press) begin
                        func_start <= 1'b1;
                        state      <= START;
                    end
                end

                START: begin
                    state <= WORK;
                end

                WORK: begin
                    if (busy_func)
                        func_armed <= 1'b1;
                    if (func_armed && !busy_func) begin
                        result <= {11'd0, y_func};
                        seg_start <= 1'b1;
                        state     <= START_SEG;
                    end
                end

                START_SEG: begin
                    state <= WAIT_SEG;
                end

                WAIT_SEG: begin
                    if (busy_seg)
                        seg_armed <= 1'b1;
                    if (seg_armed && !busy_seg)
                        state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
