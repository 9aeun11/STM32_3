`timescale 1ns/1ps
// STM32_3_과제10 · SPI 슬레이브 수신 (Mode 0, 8비트, MSB 먼저)
// - SCK·MOSI·CS를 시스템 클록으로 동기화(2단 + 에지 검출용 1단)
// - CS가 LOW인 동안 SCK 상승 에지마다 MOSI를 시프트 레지스터에 넣는다
// - 8비트를 받으면 data에 저장하고 valid를 1클록 낸다
// - CS가 HIGH가 되면 비트 카운터를 0으로 되돌려 다음 바이트를 새로 받는다
module spi_slave_rx (
    input  wire       clk,
    input  wire       rst_p,
    input  wire       spi_sck,
    input  wire       spi_mosi,
    input  wire       spi_cs_n,
    output reg  [7:0] data,
    output reg        valid
);
    (* ASYNC_REG = "TRUE" *) reg [1:0] sck_sync, mosi_sync, cs_sync;
    reg       sck_d;
    reg [6:0] shift;
    reg [2:0] bitcnt;

    wire sck  = sck_sync[1];
    wire mosi = mosi_sync[1];
    wire cs_n = cs_sync[1];
    wire sck_rise = sck & ~sck_d;

    always @(posedge clk) begin
        if (rst_p) begin
            sck_sync <= 2'b00; mosi_sync <= 2'b00; cs_sync <= 2'b11; sck_d <= 1'b0;
            shift <= 0; bitcnt <= 0; data <= 0; valid <= 1'b0;
        end else begin
            sck_sync  <= {sck_sync[0],  spi_sck};
            mosi_sync <= {mosi_sync[0], spi_mosi};
            cs_sync   <= {cs_sync[0],   spi_cs_n};
            sck_d     <= sck;
            valid     <= 1'b0;

            if (cs_n) begin
                bitcnt <= 0;                       // CS 해제: 다음 바이트 준비
            end else if (sck_rise) begin
                if (bitcnt == 3'd7) begin
                    data   <= {shift, mosi};       // 8번째 비트까지 받음
                    valid  <= 1'b1;
                    bitcnt <= 0;
                end else begin
                    shift  <= {shift[5:0], mosi};
                    bitcnt <= bitcnt + 1'b1;
                end
            end
        end
    end
endmodule
