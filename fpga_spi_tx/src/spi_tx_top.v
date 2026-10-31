`timescale 1ns/1ps
// STM32_3_과제11 (FPGA → MCU) / 과제12 송신 측 (FPGA → FPGA)
// 1초마다 한 바이트를 SPI로 보낸다. 보내는 값은 0x55 → 0xA5 → 0x00 → 0xFF 순서로 반복.
// 보낸 값은 LED에 표시하고 FPGA UART(USB-UART, 9600 8N1)로 "TX=HH"를 출력한다.
module spi_tx_top #(
    parameter integer CLK_HZ    = 50_000_000,
    parameter integer BAUD      = 9_600,
    parameter integer SCK_HZ    = 500_000,
    parameter integer PERIOD_MS = 1000
) (
    input  wire       clk_50mhz,
    input  wire       rst_p,       // KEY01, 누르면 리셋
    output wire       spi_sck,     // → 수신 측 SCK  (MCU PB3)
    output wire       spi_mosi,    // → 수신 측 MOSI (MCU PA7)
    output wire       spi_cs_n,    // → 수신 측 CS   (MCU PA4 · NSS)
    output wire       uart_txd,    // → PC (USB-UART)
    output reg  [7:0] led
);
    localparam integer DIV      = (CLK_HZ + BAUD/2) / BAUD;
    localparam integer HALF_DIV = CLK_HZ / (2 * SCK_HZ);
    localparam integer TICKS    = CLK_HZ / 1000 * PERIOD_MS;

    reg [31:0] tick;
    reg [1:0]  sel;
    reg        start;
    reg [7:0]  tx_byte;
    wire       busy, done;

    always @(*) begin
        case (sel)
            2'd0: tx_byte = 8'h55;
            2'd1: tx_byte = 8'hA5;
            2'd2: tx_byte = 8'h00;
            default: tx_byte = 8'hFF;
        endcase
    end

    always @(posedge clk_50mhz) begin
        if (rst_p) begin
            tick <= 0; sel <= 0; start <= 0; led <= 0;
        end else begin
            start <= 1'b0;
            if (tick == TICKS - 1) begin
                tick <= 0;
                if (!busy) begin start <= 1'b1; led <= tx_byte; end
            end else tick <= tick + 1;
            if (done) sel <= sel + 1'b1;
        end
    end

    spi_master_tx #(.HALF_DIV(HALF_DIV)) u_spi(
        .clk(clk_50mhz), .rst_p(rst_p), .start(start), .data(tx_byte),
        .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_cs_n(spi_cs_n),
        .busy(busy), .done(done));

    uart_hex_print #(.DIV(DIV), .PREFIX("T")) u_print(
        .clk(clk_50mhz), .rst_p(rst_p), .valid(start), .data(tx_byte), .tx(uart_txd));
endmodule
