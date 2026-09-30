`timescale 1ns / 1ps

module btn_sync #(
    parameter integer CNT_MAX = 20
) (
    input  wire clk,
    input  wire reset,
    input  wire btn_n,
    output reg  press
);

    reg [1:0]  sync;
    reg [15:0] cnt;
    reg        stable;

    always @(posedge clk) begin
        if (reset) begin
            sync   <= 2'b11;
            cnt    <= 0;
            stable <= 1'b1;
            press  <= 1'b0;
        end else begin
            press <= 1'b0;
            sync  <= {sync[0], btn_n};
            if (sync != {2{stable}}) begin
                if (cnt == CNT_MAX) begin
                    stable <= sync[1];
                    cnt    <= 0;
                    if (sync[1] == 1'b0)
                        press <= 1'b1;
                end else
                    cnt <= cnt + 1;
            end else
                cnt <= 0;
        end
    end

endmodule
