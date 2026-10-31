`timescale 1ns/1ps
// STM32_3_과제10 TB: MCU 마스터 모델(Mode 0, MSB 먼저, 약 781 kHz)로 바이트를 보내고
// 1) SPI 수신값  2) CS 해제 후 다음 바이트  3) UART 출력 문자열 "RX=HH\r\n"을 검사한다.
module tb_spi_rx;
    localparam integer UART_BAUD = 1_000_000;          // 시뮬레이션 시간 단축용
    localparam integer BIT_NS    = 1_000_000_000 / UART_BAUD;
    localparam integer HALF_SCK  = 640;                 // 1.28 us 주기 ≈ 781 kHz

    reg clk = 0, rst_p = 1;
    reg sck = 0, mosi = 0, cs_n = 1;
    wire uart_txd;
    wire [7:0] led;
    integer errors = 0;

    always #10 clk = ~clk;                              // 50 MHz

    spi_rx_top #(.BAUD(UART_BAUD)) dut(
        .clk_50mhz(clk), .rst_p(rst_p),
        .spi_sck(sck), .spi_mosi(mosi), .spi_cs_n(cs_n),
        .uart_txd(uart_txd), .led(led));

    // Mode 0 마스터: 첫 비트를 먼저 내고, 상승 에지에서 상대가 읽고, 하강 에지 뒤 다음 비트
    task spi_send(input [7:0] b, input integer nbits);
        integer i;
        begin
            cs_n = 0; #(HALF_SCK);
            for (i = 7; i > 7 - nbits; i = i - 1) begin
                mosi = b[i]; #(HALF_SCK);
                sck = 1;     #(HALF_SCK);
                sck = 0;
            end
            #(HALF_SCK); cs_n = 1; #(HALF_SCK * 4);
        end
    endtask

    // 수신 valid 감시
    reg [7:0] got; reg got_flag = 0;
    always @(posedge clk) if (dut.rx_valid) begin got <= dut.rx_data; got_flag <= 1; end

    task expect_rx(input [7:0] b);
        begin
            #(2000);
            if (!got_flag) begin $display("FAIL: %02h 수신 안 됨", b); errors = errors + 1; end
            else if (got !== b) begin $display("FAIL: 기대 %02h, 수신 %02h", b, got); errors = errors + 1; end
            else $display("PASS: SPI RX=%02h, LED=%08b", got, led);
            got_flag = 0;
        end
    endtask

    // UART 수신 모델: 한 문자 읽기
    task uart_get(output [7:0] c);
        integer k;
        begin
            @(negedge uart_txd); #(BIT_NS + BIT_NS/2);
            for (k = 0; k < 8; k = k + 1) begin c[k] = uart_txd; #(BIT_NS); end
        end
    endtask

    reg [8*7-1:0] line;
    reg [7:0] ch;
    integer n;
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_spi_rx);
        #200 rst_p = 0; #200;

        // UART 문자열 검사 (0x55 전송과 동시에 수신)
        fork
            begin spi_send(8'h55, 8); end
            begin
                for (n = 0; n < 7; n = n + 1) begin uart_get(ch); line = {line[8*6-1:0], ch}; end
            end
        join
        if (line !== {"RX=55", 8'h0D, 8'h0A}) begin $display("FAIL: UART 출력 오류"); errors = errors + 1; end
        else $display("PASS: UART 출력 \"RX=55\\r\\n\"");
        expect_rx(8'h55);

        spi_send(8'hA5, 8); expect_rx(8'hA5);
        spi_send(8'h00, 8); expect_rx(8'h00);
        spi_send(8'hFF, 8); expect_rx(8'hFF);

        // 4비트만 보내고 CS 해제 → 수신되면 안 됨, 다음 바이트는 정상 수신
        spi_send(8'hF0, 4); #2000;
        if (got_flag) begin $display("FAIL: 불완전한 바이트가 수신됨"); errors = errors + 1; got_flag = 0; end
        else $display("PASS: CS 중간 해제 시 무시");
        spi_send(8'h3C, 8); expect_rx(8'h3C);

        #(BIT_NS * 80);   // 남은 UART 출력 마무리
        if (errors == 0) $display("ALL PASS"); else $display("ERRORS = %0d", errors);
        $finish;
    end
endmodule
