/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Test Top 
--                     
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
module top_tb;
    // ------------- Parameter -----------------//

    localparam integer PERIOD_CLK0  = 10;
    localparam integer PERIOD_CLK1  = 12;
    localparam integer DATA_WIDTH   = 32;        // ширина шинны данных
    localparam integer RAM_DEPTH    = 8;        // буфер количества слов
    localparam integer WR_AE_LVL    = 2;        // almost empty num word    for write operation
    localparam integer WR_AF_LVL    = 2;        // almost full num word     for write operation
    localparam integer RD_AE_LVL    = 2;        // almost empty num word    for read operation
    localparam integer RD_AF_LVL    = 2;        // almost full num word    for read operation
    localparam integer ERR_MODE     = 0;        // вариант поведения сигнала ошибки если 0 при возникновении ошибки висит до ресета, если 1 активен только в момент ошибки
    localparam integer WR_SYNC      = 2;        // количество тактов на синхронизацию предпочтительно 2 для высоких частот 3 для write
    localparam integer RD_SYNC      = 2;        // количество тактов на синхронизацию предпочтительно 2 для высоких частот 3 для read
    localparam integer RST_MODE     = 0;        // вариант работы сброса 0 асинхронный сброс, 1 синхронный сброс 
    // utility
    localparam TIMEOUT              = 5;
    localparam integer ADDR_WIDTH   = $clog2(RAM_DEPTH);
    localparam STREAM_DEPTH         = RAM_DEPTH*4;
    
    // ------------- Signals -----------------//
    logic clk0, clk1;
    logic rst_n;

    bit assert_en;
    
    integer num_word;

    string name;

    bit [DATA_WIDTH - 1 : 0]    data [STREAM_DEPTH];
    
    bit [31:0] rand_delay0;
    bit [31:0] rand_delay1;

    // ------------- Interface -----------------//
    iffifo       #(  .DATA_WIDTH (DATA_WIDTH)   )   fifo_if         (.clk_push (clk0), .clk_pop(clk1), .rst_n(rst_n));
    iffifo       #(  .DATA_WIDTH (DATA_WIDTH)   )   model_fifo_if   (.clk_push (clk0), .clk_pop(clk1), .rst_n(rst_n));

    // -------- Component instantiations -------//
    ew_fifo_s2_sf
    #(
        .DATA_WIDTH (DATA_WIDTH),       // ширина шинны данных
        .RAM_DEPTH  (RAM_DEPTH),        // буфер количества слов
        .WR_AE_LVL  (WR_AE_LVL),        // almost empty num word    for write operation
        .WR_AF_LVL  (WR_AF_LVL),        // almost full num word     for write operation
        .RD_AE_LVL  (RD_AE_LVL),        // almost empty num word    for read operation
        .RD_AF_LVL  (RD_AF_LVL),        // almost full num word    for read operation
        .ERR_MODE   (ERR_MODE),         // вариант поведения сигнала ошибки если 0 при возникновении ошибки висит до ресета, если 1 активен только в момент ошибки
        .WR_SYNC    (WR_SYNC),          // количество тактов на синхронизацию предпочтительно 2 для высоких частот 3 для write
        .RD_SYNC    (RD_SYNC),          // количество тактов на синхронизацию предпочтительно 2 для высоких частот 3 для read
        .RST_MODE   (RST_MODE)          // вариант работы сброса 0 асинхронный сброс, 1 синхронный сброс 
    )
    ew_fifo_s2_sf_inst
    (
        .clk_push       (fifo_if.clk_push),
        .clk_pop        (fifo_if.clk_pop),
        .rst_n          (rst_n),
        .push_req_n     (fifo_if.push_req_n),
        .pop_req_n      (fifo_if.pop_req_n),
        .data_in        (fifo_if.data_in),
        .push_empty     (fifo_if.push_empty),
        .push_ae        (fifo_if.push_ae),
        .push_hf        (fifo_if.push_hf),
        .push_af        (fifo_if.push_af),
        .push_full      (fifo_if.push_full),
        .push_error     (fifo_if.push_error),
        .pop_empty      (fifo_if.pop_empty),
        .pop_ae         (fifo_if.pop_ae),
        .pop_hf         (fifo_if.pop_hf),
        .pop_af         (fifo_if.pop_af),
        .pop_full       (fifo_if.pop_full),
        .pop_error      (fifo_if.pop_error),
        .data_out       (fifo_if.data_out)
    );

    DW_fifo_s2_sf
    #(
        .width          (DATA_WIDTH),
        .depth          (RAM_DEPTH),
        .push_ae_lvl    (WR_AE_LVL),
        .push_af_lvl    (WR_AF_LVL),
        .pop_ae_lvl     (RD_AE_LVL),
        .pop_af_lvl     (RD_AF_LVL),
        .err_mode       (ERR_MODE),
        .push_sync      (WR_SYNC),
        .pop_sync       (RD_SYNC),
        .rst_mode       (RST_MODE)
    )
    DW_fifo_s2_sf_inst
    (
        .clk_push           (model_fifo_if.clk_push)
        ,.clk_pop           (model_fifo_if.clk_pop)
        ,.rst_n             (rst_n)
        ,.push_req_n        (fifo_if.push_req_n)
        ,.pop_req_n         (fifo_if.pop_req_n)
        ,.data_in           (fifo_if.data_in)
        ,.push_empty        (model_fifo_if.push_empty)
        ,.push_ae           (model_fifo_if.push_ae)
        ,.push_hf           (model_fifo_if.push_hf)
        ,.push_af           (model_fifo_if.push_af)
        ,.push_full         (model_fifo_if.push_full)
        ,.push_error        (model_fifo_if.push_error)
        ,.pop_empty         (model_fifo_if.pop_empty)
        ,.pop_ae            (model_fifo_if.pop_ae)
        ,.pop_hf            (model_fifo_if.pop_hf)
        ,.pop_af            (model_fifo_if.pop_af)
        ,.pop_full          (model_fifo_if.pop_full)
        ,.pop_error         (model_fifo_if.pop_error)
        ,.data_out          (model_fifo_if.data_out)
    );

    // initial block
    initial begin
        assert_en   = 1'b0;
        clk0        = 1'b0;
        clk1        = 1'b0;
        rst_n       = 1'b0;
        rand_delay0 = $urandom_range(10,80);
        rand_delay1 = $urandom_range(12,200);
        fork
            forever begin
            //    clk0 = #(PERIOD_CLK/2) ~clk0;
                clk0 = #(rand_delay0/2) ~clk0;
            end
            forever begin
            //    clk1 = #(PERIOD_CLK/2) ~clk1;
                clk1 = #(rand_delay1/2) ~clk1;
            end
        join_any
    end
    //-------------------------------------------------------------------//
    // Includes                                                          //
    //-------------------------------------------------------------------//
    `include "tb_tasks.sv"
    //-------------------------------------------------------------------//
    // Run test                                                          //
    //-------------------------------------------------------------------//
    initial begin
        assert_en = 1'b1;
        run_test();
        $finish;
    end
    
endmodule