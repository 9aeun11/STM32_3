# STM32_3 과제10·12(수신) · Combo II-DLD Xilinx S7 (xc7s75fgga484-1)
# 출처: Xilinx S7 Pin Map (MAIN CLOCK 50 MHz, KEY01, USB to Serial, LED, BreadBoard I/O)

## 50 MHz 클록 / 리셋(KEY01, 누르면 1)
set_property PACKAGE_PIN B6 [get_ports clk_50mhz]
set_property PACKAGE_PIN K4 [get_ports rst_p]
create_clock -name clk_50mhz -period 20.000 [get_ports clk_50mhz]

## FPGA UART → PC (USB_TXD0, 보드 USB-UART, 9600 8N1)
set_property PACKAGE_PIN F6 [get_ports uart_txd]

## SPI 입력 · BreadBoard I/O 커넥터 (점퍼선 연결)
##   BDIO00 (F8) = SCK  ← MCU PB3  / 송신 FPGA BDIO00
##   BDIO01 (E8) = MOSI ← MCU PA7  / 송신 FPGA BDIO01
##   BDIO02 (A7) = CS   ← MCU PB6  / 송신 FPGA BDIO02
##   GND는 반드시 공통 연결
set_property PACKAGE_PIN F8 [get_ports spi_sck]
set_property PACKAGE_PIN E8 [get_ports spi_mosi]
set_property PACKAGE_PIN A7 [get_ports spi_cs_n]
set_property PULLDOWN true [get_ports spi_sck]
set_property PULLUP   true [get_ports spi_cs_n]

## LED: 수신값 표시 (led[7]=LED_D1 … led[0]=LED_D8)
set_property PACKAGE_PIN N5 [get_ports {led[0]}]
set_property PACKAGE_PIN M1 [get_ports {led[1]}]
set_property PACKAGE_PIN M3 [get_ports {led[2]}]
set_property PACKAGE_PIN M7 [get_ports {led[3]}]
set_property PACKAGE_PIN N7 [get_ports {led[4]}]
set_property PACKAGE_PIN M2 [get_ports {led[5]}]
set_property PACKAGE_PIN M4 [get_ports {led[6]}]
set_property PACKAGE_PIN L4 [get_ports {led[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports *]

## 비동기 입력·느린 출력은 타이밍 분석에서 제외
set_false_path -from [get_ports {rst_p spi_sck spi_mosi spi_cs_n}]
set_false_path -to   [get_ports {uart_txd led[*]}]
