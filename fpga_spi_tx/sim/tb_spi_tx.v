`timescale 1ns/1ps
// STM32_3_과제11 TB: 슬레이브 모델이 SCK 상승 에지에서 MOSI를 읽어
// 1) 0x55 → 0xA5 → 0x00 → 0xFF 순서  2) SCK 주기(≤1 MHz)·대기 LOW
// 3) MOSI가 SCK HIGH 동안 바뀌지 않는지  4) UART "TX=55\r\n" 출력을 검사한다.
module tb_spi_tx;
    localparam integer UART_BAUD = 1_000_000;          // 시뮬레이션 시간 단축용
    localparam integer BIT_NS    = 1_000_000_000 / UART_BAUD;

    reg clk = 0, rst_p = 1;
    wire sck, mosi, cs_n, uart_txd;
    wire [7:0] led;
    integer errors = 0;

    always #10 clk = ~clk;                              // 50 MHz

    // 1초 대신 1 ms마다 전송하도록 줄여서 시뮬레이션
    spi_tx_top #(.BAUD(UART_BAUD), .PERIOD_MS(1)) dut(
        .clk_50mhz(clk), .rst_p(rst_p),
        .spi_sck(sck), .spi_mosi(mosi), .spi_cs_n(cs_n),
        .uart_txd(uart_txd), .led(led));

    // ---- 슬레이브 모델 ----
    reg [7:0] sh; integer nb = 0; integer nbytes = 0;
    reg [7:0] expect_list [0:7];
    initial begin
        expect_list[0]=8'h55; expect_list[1]=8'hA5; expect_list[2]=8'h00; expect_list[3]=8'hFF;
        expect_list[4]=8'h55; expect_list[5]=8'hA5; expect_list[6]=8'h00; expect_list[7]=8'hFF;
    end
    always @(negedge cs_n) nb = 0;
    always @(posedge sck) begin
        if (cs_n) begin $display("FAIL: CS HIGH인데 SCK 상승"); errors = errors + 1; end
        sh = {sh[6:0], mosi}; nb = nb + 1;
    end
    always @(posedge cs_n) if ($time > 0 && !rst_p) begin
        if (nb != 8) begin $display("FAIL: 상승 에지 %0d번", nb); errors = errors + 1; end
        else if (sh !== expect_list[nbytes]) begin
            $display("FAIL: 기대 %02h, 수신 %02h", expect_list[nbytes], sh); errors = errors + 1;
        end else $display("PASS: SPI 바이트 %0d = %02h (LED=%08b)", nbytes, sh, led);
        nbytes = nbytes + 1;
    end
    // SCK HIGH 동안 MOSI가 바뀌면 오류
    always @(mosi) if (sck === 1'b1) begin $display("FAIL: SCK HIGH 동안 MOSI 변경"); errors = errors + 1; end
    // SCK 주기 측정
    realtime t_last = 0; real period_ns = 0;
    always @(posedge sck) begin
        if (t_last > 0 && ($realtime - t_last) < 5000) period_ns = $realtime - t_last;
        t_last = $realtime;
    end

    // ---- UART 수신 모델 ----
    task uart_get(output [7:0] c);
        integer k;
        begin
            @(negedge uart_txd); #(BIT_NS + BIT_NS/2);
            for (k = 0; k < 8; k = k + 1) begin c[k] = uart_txd; #(BIT_NS); end
        end
    endtask
    reg [8*7-1:0] line; reg [7:0] ch; integer n;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_spi_tx);
        #200 rst_p = 0;
        for (n = 0; n < 7; n = n + 1) begin uart_get(ch); line = {line[8*6-1:0], ch}; end
        if (line !== {"TX=55", 8'h0D, 8'h0A}) begin $display("FAIL: UART 출력 오류"); errors = errors + 1; end
        else $display("PASS: UART 출력 \"TX=55\\r\\n\"");

        wait (nbytes == 8);
        #1000;
        $display("SCK 주기 = %0.0f ns (%0.1f kHz)", period_ns, 1.0e6 / period_ns);
        if (period_ns < 1000.0) begin $display("FAIL: SCK가 1 MHz 초과"); errors = errors + 1; end
        if (errors == 0) $display("ALL PASS"); else $display("ERRORS = %0d", errors);
        $finish;
    end
endmodule
