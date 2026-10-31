# STM32_3 · fpga_spi_tx

자세한 연결·과제 설명은 상위 폴더의 README.md 참고.

| 파일 | 내용 |
|---|---|
| src/ | 설계 (uart.v는 LAB3 07_uart_echo의 송신 모듈 재사용) |
| sim/tb_spi_tx.v | 자동 검사 테스트벤치 |
| constraints/spi_tx.xdc | 핀 제약 (BDIO00~02 = F8/E8/A7) |
| tools/create_vivado_project.tcl | Vivado 프로젝트·비트스트림 생성 |
