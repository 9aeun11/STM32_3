`timescale 1ns/1ps
// 한 바이트를 "<P>X=HH\r\n" 형식의 문자열로 UART에 출력한다.
// PREFIX: "R"이면 RX=.., "T"이면 TX=..
// 출력 중에 새 값이 들어오면 마지막 값 하나를 보관했다가 이어서 출력한다.
module uart_hex_print #(
    parameter integer DIV = 5208,
    parameter [7:0] PREFIX = "R"
) (
    input  wire       clk,
    input  wire       rst_p,
    input  wire       valid,
    input  wire [7:0] data,
    output wire       tx
);
    reg  [7:0] cur, pend;
    reg        has_pend;
    reg  [2:0] idx;       // 0~6: 출력할 문자 위치
    reg        busy;
    reg        tx_valid;
    reg  [7:0] tx_data;
    wire       tx_ready;

    uart_tx #(.DIV(DIV)) u_tx(
        .clk(clk), .rst_p(rst_p), .valid(tx_valid), .data(tx_data),
        .ready(tx_ready), .tx(tx));

    function [7:0] hex;
        input [3:0] n;
        hex = (n < 4'd10) ? ("0" + n) : ("A" + n - 4'd10);
    endfunction

    function [7:0] char_at;
        input [2:0] i;
        input [7:0] v;
        case (i)
            3'd0: char_at = PREFIX;
            3'd1: char_at = "X";
            3'd2: char_at = "=";
            3'd3: char_at = hex(v[7:4]);
            3'd4: char_at = hex(v[3:0]);
            3'd5: char_at = 8'h0D;
            default: char_at = 8'h0A;
        endcase
    endfunction

    always @(posedge clk) begin
        if (rst_p) begin
            cur <= 0; pend <= 0; has_pend <= 0; idx <= 0; busy <= 0;
            tx_valid <= 0; tx_data <= 0;
        end else begin
            tx_valid <= 0;
            if (valid) begin
                if (!busy) begin cur <= data; busy <= 1; idx <= 0; end
                else begin pend <= data; has_pend <= 1; end
            end
            // tx_valid를 낸 다음 클록에는 ready가 아직 1이므로 한 클록 쉬고 확인한다.
            if (busy && tx_ready && !tx_valid) begin
                tx_data  <= char_at(idx, cur);
                tx_valid <= 1;
                if (idx == 3'd6) begin
                    idx <= 0;
                    if (valid) begin cur <= data; has_pend <= 0; end
                    else if (has_pend) begin cur <= pend; has_pend <= 0; end
                    else busy <= 0;
                end else idx <= idx + 1'b1;
            end
        end
    end
endmodule
