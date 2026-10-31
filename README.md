# STM32_3 · SPI로 MCU와 FPGA 연결 (과제 8~12)

GitHub `ece2_26_2_2`의 `c/stm32/docs/STM32_3.md` 순서대로 만든 프로젝트 4개.

| 폴더 | 종류 | 여는 방법 | 사용 과제 |
|---|---|---|---|
| `mcu_spi_master` | STM32 VS Code (기본 프로젝트 + 제공 마스터 코드) | `ece2_474.code-workspace` | 과제8, 과제9 송신, 과제10 |
| `mcu_spi_slave` | STM32 VS Code (기본 프로젝트 + 제공 슬레이브 코드) | `ece2_474.code-workspace` | 과제9 수신, 과제11 |
| `fpga_spi_rx` | FPGA VS Code + Vivado (SPI 슬레이브 수신 → UART) | `FPGA.code-workspace` | 과제10, 과제12 수신 |
| `fpga_spi_tx` | FPGA VS Code + Vivado (SPI 마스터 송신, 1초마다) | `FPGA.code-workspace` | 과제11, 과제12 송신 |

변경한 파일은 MCU `Core/Src/ece2_474_routine.c` 하나뿐이다(main.c·CubeMX 수정 없음).
MCU 송신값은 제공 코드대로 `0x55`. 0xA5·0x00·0xFF로 바꿔 볼 때는 `uint8_t tx = 0x55;`만 수정 → Build → **F5**.

## 핀 (FPGA XDC = Xilinx S7 Pin Map 기준)

| 신호 | MCU 마스터 | MCU 슬레이브 | FPGA (BreadBoard I/O) |
|---|---|---|---|
| SCK | PB3 | PB3 | **BDIO00 = F8** |
| MOSI | PA7 | PA7 | **BDIO01 = E8** |
| CS | PB6 | **PA4** (NSS) | **BDIO02 = A7** |
| GND | GND | GND | GND (EX1/EX2 커넥터 45~50번 핀 등) |

FPGA 공통: CLK 50 MHz = B6, 리셋 KEY01 = K4, UART TX → PC = F6 (USB-UART, 9600 8N1), LED_D1~D8 = 바이트 표시.
MISO는 연결하지 않는다.

## 과제별 연결

| 과제 | 연결 | 확인 |
|---|---|---|
| 8 | `mcu_spi_master`만 실행, 오실로스코프로 PB3·PA7·PB6 | CS LOW 중 SCK 상승 8번, 0x55=01010101, SCK ≈ 781 kHz |
| 9 | 마스터 PB3→PB3, PA7→PA7, **PB6→PA4**, GND | 수신 MCU VCP(9600)에 `RX=55`, 역할 교대 시 CS 선도 바꿈 |
| 10 | MCU 마스터 PB3→F8, PA7→E8, PB6→A7, GND / FPGA=`fpga_spi_rx` | FPGA USB-UART COM 포트에 `RX=55`, LED=01010101 |
| 11 | FPGA=`fpga_spi_tx` F8→PB3, E8→PA7, **A7→PA4**, GND / MCU=`mcu_spi_slave` | MCU VCP에 `RX=55` → `A5` → `00` → `FF` 반복, FPGA UART엔 `TX=..` |
| 12 | 송신 FPGA(`fpga_spi_tx`) F8/E8/A7 → 수신 FPGA(`fpga_spi_rx`) F8/E8/A7, GND | 수신 FPGA UART에 `RX=..`, 역할 교대 시 비트스트림 교체 |

실행 순서: **수신 측 먼저** 실행 → 송신 측 실행. 송신이 없을 때 MCU 슬레이브의 `RX timeout`은 정상.

## FPGA 사용법

1. `FPGA.code-workspace` 열기 → Terminal ▸ Run Task
   - `02 Simulate` : Icarus 시뮬레이션 (TB가 자동 검사, `ALL PASS` 확인)
   - `03 Open waveform` : 파형 보기
   - `04 Create Vivado project` : `vivado/spi_rx.xpr`(또는 `spi_tx.xpr`) 생성 + 합성·구현·비트스트림 → 폴더에 `spi_rx_top.bit` / `spi_tx_top.bit`
2. Vivado GUI로 할 때: Tcl Console에서
   `cd <fpga_spi_rx 폴더>` → `source tools/create_vivado_project.tcl` → Generate Bitstream → Hardware Manager로 다운로드
   (Vivado가 PATH에 없으면 04 작업 대신 이 방법 사용)

FPGA 송신 SCK = 500 kHz (1 MHz 이하), 1초마다 0x55 → 0xA5 → 0x00 → 0xFF 순서로 송신.

## 검증한 것

- `fpga_spi_rx` TB: 0x55/A5/00/FF/3C 수신, CS 중간 해제 시 무시, UART `RX=55\r\n` — ALL PASS
- `fpga_spi_tx` TB: 바이트 순서, SCK 상승 8번, SCK HIGH 동안 MOSI 불변, SCK 500 kHz, UART `TX=55\r\n` — ALL PASS
- 과제12 연결(tx_top → rx_top) 시뮬레이션: 오류 0
- MCU 두 프로젝트 arm-none-eabi-gcc로 빌드 성공(경고 없음)
- Vivado 2026.1에서 RX/TX 합성·배치·배선·비트스트림 생성 완료, 타이밍 제약 충족 (DRC에 CFGBVS/CONFIG_VOLTAGE 미지정 경고 1건씩; 오류 없음)
- 실제 보드 다운로드·배선 동작은 아직 확인하지 않음

