`timescale 1ns/1ps
// STM32_3_과제10 (MCU → FPGA) / 과제12 수신 측 (FPGA → FPGA)
// SPI로 받은 바이트를 LED에 표시하고 FPGA UART(USB-UART, 9600 8N1)로 "RX=HH" 출력
module spi_rx_top #(
    parameter integer CLK_HZ = 50_000_000,
    parameter integer BAUD   = 9_600
) (
    input  wire       clk_50mhz,
    input  wire       rst_p,       // KEY01, 누르면 리셋
    input  wire       spi_sck,     // ← 송신 측 SCK  (MCU PB3)
    input  wire       spi_mosi,    // ← 송신 측 MOSI (MCU PA7)
    input  wire       spi_cs_n,    // ← 송신 측 CS   (MCU PB6)
    output wire       uart_txd,    // → PC (USB-UART)
    output reg  [7:0] led
);
    localparam integer DIV = (CLK_HZ + BAUD/2) / BAUD;
    wire [7:0] rx_data;
    wire       rx_valid;

    spi_slave_rx u_spi(
        .clk(clk_50mhz), .rst_p(rst_p),
        .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_cs_n(spi_cs_n),
        .data(rx_data), .valid(rx_valid));

    uart_hex_print #(.DIV(DIV), .PREFIX("R")) u_print(
        .clk(clk_50mhz), .rst_p(rst_p), .valid(rx_valid), .data(rx_data), .tx(uart_txd));

    always @(posedge clk_50mhz) begin
        if (rst_p) led <= 8'h00;
        else if (rx_valid) led <= rx_data;
    end
endmodule
