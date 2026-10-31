# STM32G474 기본 프로젝트

[STM32 목차](../README.md) · [제공 예제](../examples/README.md)

기존 `ece2_474`의 Core·Drivers·초기화·표준 입출력·설정 파일을 보존한 기본 프로젝트다. 시작 시 `Hello, World!`를 출력하고 `polling_routine()`을 반복 호출한다.

- [main.c](Core/Src/main.c)
- [실습 함수·인터럽트 연결](Core/Src/ece2_474_routine.c)
- [표준 입출력 연결](Core/Src/ece2_474_stdio.c)
- [IOC 설정](ece2_474.ioc)
