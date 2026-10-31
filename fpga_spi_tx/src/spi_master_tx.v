`timescale 1ns/1ps
// STM32_3_과제11 · SPI 마스터 송신 (Mode 0, 8비트, MSB 먼저)
// - start가 들어오면 CS를 LOW로 내리고 최상위 비트를 MOSI에 먼저 준비
// - HALF_DIV 클록마다 SCK를 반전: 상승 에지(상대가 읽음) → 하강 에지(다음 비트로 변경)
// - 8번째 하강 에지 후 반 주기 기다렸다가 CS를 HIGH로 올리고 done을 1클록 낸다
// - SCK 주파수 = CLK / (2 * HALF_DIV).  50 MHz / (2*50) = 500 kHz (1 MHz 이하)
module spi_master_tx #(
    parameter integer HALF_DIV = 50
) (
    input  wire       clk,
    input  wire       rst_p,
    input  wire       start,
    input  wire [7:0] data,
    output reg        spi_sck,
    output reg        spi_mosi,
    output reg        spi_cs_n,
    output wire       busy,
    output reg        done
);
    localparam [1:0] IDLE = 2'd0, SETUP = 2'd1, SHIFT = 2'd2, HOLD = 2'd3;
    reg [1:0]  state;
    reg [15:0] timer;
    reg [7:0]  shift;
    reg [2:0]  bitcnt;

    assign busy = (state != IDLE);

    always @(posedge clk) begin
        if (rst_p) begin
            state <= IDLE; timer <= 0; shift <= 0; bitcnt <= 0;
            spi_sck <= 1'b0; spi_mosi <= 1'b0; spi_cs_n <= 1'b1; done <= 1'b0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    spi_sck <= 1'b0; spi_cs_n <= 1'b1;
                    if (start) begin
                        shift    <= data;
                        spi_mosi <= data[7];          // 첫 상승 에지 전에 MSB 준비
                        spi_cs_n <= 1'b0;
                        bitcnt   <= 0;
                        timer    <= HALF_DIV - 1;
                        state    <= SETUP;
                    end
                end
                SETUP: begin                          // CS LOW 후 반 주기 대기
                    if (timer != 0) timer <= timer - 1'b1;
                    else begin timer <= HALF_DIV - 1; spi_sck <= 1'b1; state <= SHIFT; end
                end
                SHIFT: begin
                    if (timer != 0) timer <= timer - 1'b1;
                    else begin
                        timer <= HALF_DIV - 1;
                        if (spi_sck) begin            // 하강 에지: 다음 비트 준비
                            spi_sck <= 1'b0;
                            if (bitcnt == 3'd7) state <= HOLD;
                            else begin
                                shift    <= {shift[6:0], 1'b0};
                                spi_mosi <= shift[6];
                                bitcnt   <= bitcnt + 1'b1;
                            end
                        end else begin                // 상승 에지: 상대가 MOSI를 읽음
                            spi_sck <= 1'b1;
                        end
                    end
                end
                HOLD: begin                           // 마지막 하강 에지 후 반 주기 뒤 CS 해제
                    if (timer != 0) timer <= timer - 1'b1;
                    else begin spi_cs_n <= 1'b1; spi_mosi <= 1'b0; done <= 1'b1; state <= IDLE; end
                end
            endcase
        end
    end
endmodule
