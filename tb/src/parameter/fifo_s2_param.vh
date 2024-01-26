/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Игорь Гусев
--
--    Назначение     : Параметры интерфейса
-—                     
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/

`ifndef _GUARD_ECC_PARAM_
    `define _GUARD_ECC_PARAM_

    //-- Основные параметры конфигурации модуля -----------------------------------------------------
    localparam BYTE_WIDTH       = 8;        // ширина байте
    localparam WR_CLK_MHZ       = 100;
    localparam RD_CLK_MHZ       = 30;

    parameter integer DATA_WIDTH    = 32;        // ширина шинны данных
    parameter integer RAM_DEPTH     = 8;        // буфер количества слов
    parameter integer WR_AE_LVL     = 2;        // almost empty num word    for write operation
    parameter integer WR_AF_LVL     = 2;        // almost full num word     for write operation
    parameter integer RD_AE_LVL     = 2;        // almost empty num word    for read operation
    parameter integer RD_AF_LVL     = 2;        // almost full num word    for read operation
    parameter integer ERR_MODE      = 0;        // вариант поведения сигнала ошибки если 0 при возникновении ошибки висит до ресета, если 1 активен только в момент ошибки
    parameter integer WR_SYNC       = 2;        // количество тактов на синхронизацию предпочтительно 2 для высоких частот 3 для write
    parameter integer RD_SYNC       = 2;        // количество тактов на синхронизацию предпочтительно 2 для высоких частот 3 для read
    parameter integer RST_MODE      = 0;        // вариант работы сброса 0 асинхронный сброс, 1 синхронный сброс 
    // utility
    localparam TIMEOUT              = 5;
    localparam integer ADDR_WIDTH   = $clog2(RAM_DEPTH);
    localparam STREAM_DEPTH         = RAM_DEPTH*4;
    
    typedef enum {NULL, WRITE_S, READ_S, WR_RD_S, RESET_S} state_enum;

`endif
  