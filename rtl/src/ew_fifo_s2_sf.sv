/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : fifo Top
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/

module ew_fifo_s2_sf(
    clk_push,
    clk_pop,
    rst_n,
    push_req_n,
    pop_req_n,
    data_in,
    push_empty,
    push_ae,
    push_hf,
    push_af,
    push_full,
    push_error,
    pop_empty,
    pop_ae,
    pop_hf,
    pop_af,
    pop_full,
    pop_error,
    data_out
    );

    //----------------------------------------------------------------------//
    // external parameters                                                  //
    //----------------------------------------------------------------------//
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
    parameter integer TST_MODE      = 0;        //
    //----------------------------------------------------------------------//
    // internal parameters                                                  //
    //----------------------------------------------------------------------//
    localparam integer ADDR_WIDTH   = $clog2(RAM_DEPTH);
    //----------------------------------------------------------------------//
    // external signals                                                     //
    //----------------------------------------------------------------------//
    input                           clk_push;
    input                           clk_pop;
    input                           rst_n;
    input                           push_req_n;
    input                           pop_req_n;
    input   [DATA_WIDTH - 1 : 0]    data_in;
    output                          push_empty;
    output                          push_ae;
    output                          push_hf;
    output                          push_af;
    output                          push_full;
    output                          push_error;
    output                          pop_empty;
    output                          pop_ae;
    output                          pop_hf;
    output                          pop_af;
    output                          pop_full;
    output                          pop_error;
    output  [DATA_WIDTH - 1 : 0]    data_out;

    //----------------------------------------------------------------------//
    // registers                                                            //
    //----------------------------------------------------------------------//

    //----------------------------------------------------------------------//
    // wires                                                                //
    //----------------------------------------------------------------------//
    wire    [ADDR_WIDTH - 1 : 0]    wr_addr;
    wire    [ADDR_WIDTH - 1 : 0]    rd_addr;
    wire                            we_n;
    //----------------------------------------------------------------------//
    // assigns                                                              //
    //----------------------------------------------------------------------//
    //----------------------------------------------------------------------//
    // Component instantiations                                             //
    //----------------------------------------------------------------------//
    ew_fifoctl_s2_sf
    #(
        .RAM_DEPTH      (RAM_DEPTH),        // буфер количества слов
        .WR_AE_LVL      (WR_AE_LVL),        // almost empty num word    for write operation
        .WR_AF_LVL      (WR_AF_LVL),        // almost full num word     for write operation
        .RD_AE_LVL      (RD_AE_LVL),        // almost empty num word    for read operation
        .RD_AF_LVL      (RD_AF_LVL),        // almost full num word    for read operation
        .ERR_MODE       (ERR_MODE),        // вариант поведения сигнала ошибки если 0 при возникновении ошибки висит до ресета, если 1 активен только в момент ошибки
        .WR_SYNC        (WR_SYNC),        // количество тактов на синхронизацию предпочтительно 2 для высоких частот 3 для write
        .RD_SYNC        (RD_SYNC),        // количество тактов на синхронизацию предпочтительно 2 для высоких частот 3 для read
        .RST_MODE       (RST_MODE),        // вариант работы сброса 0 асинхронный сброс, 1 синхронный сброс
        .TST_MODE       (TST_MODE)
    )
    sync_inst
    (
        .clk_push           (clk_push),
        .clk_pop            (clk_pop),
        .rst_n              (rst_n),
        .push_req_n         (push_req_n),
        .pop_req_n          (pop_req_n),
        .wr_addr            (wr_addr),
        .we_n               (we_n),
        .push_empty         (push_empty),
        .push_ae            (push_ae),
        .push_hf            (push_hf),
        .push_af            (push_af),
        .push_full          (push_full),
        .push_error         (push_error),
        .pop_empty          (pop_empty),
        .pop_ae             (pop_ae),
        .pop_hf             (pop_hf),
        .pop_af             (pop_af),
        .pop_full           (pop_full),
        .pop_error          (pop_error),
        .rd_addr            (rd_addr),
        .push_word_count    (),
        .pop_word_count     (),
        .test               (1'b0)
    );

    ew_ram_r_w_s_dff
    #(
        .DATA_WIDTH     (DATA_WIDTH),
        .RAM_DEPTH      (RAM_DEPTH),
        .RST_MODE       (RST_MODE)
    )
    ram_inst
    (
        .clk            (clk_push),
        .rst_n          (rst_n),
        .cs_n           (1'b0),
        .wr_n           (we_n),
        .rd_addr        (rd_addr),
        .wr_addr        (wr_addr),
        .data_in        (data_in), 
        .data_out       (data_out)
    );
    //----------------------------------------------------------------------//
    // logic                                                                //
    //----------------------------------------------------------------------//
endmodule