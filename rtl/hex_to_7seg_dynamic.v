`timescale 1ns / 1ps

// Динамическая индикация 7-сегментного табло Saylinx (active-low).
// Интерфейс: start / busy / value → SEG_DATA, SEG_SEL.
module hex_to_7seg_dynamic #(
    parameter integer DIGITS      = 4,
    // при CLK=100 МГц ≈ 1 мс на одну цифру
    parameter integer REFRESH_DIV = 100_000,
    // сколько полных проходов FE→…→F7, пока busy=1
    // время ≈ PASSES * DIGITS * REFRESH_DIV / Fclk
    // при 100 МГц: 2500*4*100000/1e8 ≈ 10 с
    // при 50 МГц на плате: поставьте PASSES=1250 ≈ 10 с
    parameter integer PASSES      = 2500
) (
    input  wire        clk,
    input  wire        reset,
    input  wire        start,
    input  wire [15:0] value,
    output             busy,
    output reg  [7:0]  SEG_DATA,
    output reg  [7:0]  SEG_SEL
);

    localparam IDLE = 1'b0;
    localparam SCAN = 1'b1;

    reg        state;
    reg [15:0] hold;
    reg [1:0]  digit_idx;
    reg [16:0] div_cnt;
    reg [15:0] pass_cnt;

    assign busy = (state != IDLE);

    // Saylinx: SEG_DATA = {a,b,c,d,e,f,g,DP}, 0 = сегмент ГОРИТ (active-low)
    function [7:0] seg_encode;
        input [3:0] d;
        begin
            case (d)
                //                abcdefgh
                4'h0: seg_encode = 8'b00000011; // 03
                4'h1: seg_encode = 8'b10011111; // 9F
                4'h2: seg_encode = 8'b00100101; // 25
                4'h3: seg_encode = 8'b00001101; // 0D
                4'h4: seg_encode = 8'b10011001; // 99
                4'h5: seg_encode = 8'b01001001; // 49
                4'h6: seg_encode = 8'b01000001; // 41
                4'h7: seg_encode = 8'b00011111; // 1F
                4'h8: seg_encode = 8'b00000001; // 01
                4'h9: seg_encode = 8'b00001001; // 09
                4'hA: seg_encode = 8'b00010001; // 11
                4'hB: seg_encode = 8'b11000001; // C1
                4'hC: seg_encode = 8'b01100011; // 63
                4'hD: seg_encode = 8'b10000101; // 85
                4'hE: seg_encode = 8'b01100001; // 61
                default: seg_encode = 8'b01110001; // 71 = F
            endcase
        end
    endfunction

    function [3:0] nibble_of;
        input [15:0] v;
        input [1:0]  idx;
        begin
            case (idx)
                2'd0:    nibble_of = v[3:0];
                2'd1:    nibble_of = v[7:4];
                2'd2:    nibble_of = v[11:8];
                default: nibble_of = v[15:12];
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (reset) begin
            state     <= IDLE;
            hold      <= 16'd0;
            digit_idx <= 2'd0;
            div_cnt   <= 17'd0;
            pass_cnt  <= 16'd0;
            SEG_DATA  <= 8'hFF;
            SEG_SEL   <= 8'hFF;
        end else begin
            case (state)
                IDLE: begin
                    SEG_DATA <= 8'hFF;
                    SEG_SEL  <= 8'hFF;
                    if (start) begin
                        hold      <= value;
                        digit_idx <= 2'd0;
                        div_cnt   <= 17'd0;
                        pass_cnt  <= 16'd0;
                        state     <= SCAN;
                    end
                end

                SCAN: begin
                    SEG_DATA <= seg_encode(nibble_of(hold, digit_idx));
                    SEG_SEL  <= ~(8'd1 << digit_idx);

                    if (div_cnt == REFRESH_DIV - 1) begin
                        div_cnt <= 17'd0;
                        if (digit_idx == DIGITS - 1) begin
                            digit_idx <= 2'd0;
                            if (pass_cnt == PASSES - 1)
                                state <= IDLE;
                            else
                                pass_cnt <= pass_cnt + 1'b1;
                        end else
                            digit_idx <= digit_idx + 1'b1;
                    end else
                        div_cnt <= div_cnt + 1'b1;
                end
            endcase
        end
    end

endmodule
