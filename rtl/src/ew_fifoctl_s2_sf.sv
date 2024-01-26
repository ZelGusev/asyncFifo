/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : sync for fifo  dw_fifoctl_s2_sf
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/

module ew_fifoctl_s2_sf(
    clk_push,
    clk_pop,
    rst_n,
    push_req_n,
    pop_req_n,
    wr_addr,
    we_n,
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
    rd_addr,
    push_word_count,
    pop_word_count,
    test
    );

    //----------------------------------------------------------------------//
    // external parameters                                                  //
    //----------------------------------------------------------------------//
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
    localparam integer ADDR_WIDTH   =   $clog2(RAM_DEPTH);
    localparam integer C_RAM_DEPTH  =   (RAM_DEPTH > 16384) ? 32768 :
                                        (RAM_DEPTH > 8192)  ? 16384 :
                                        (RAM_DEPTH > 4096)  ? 8192  :
                                        (RAM_DEPTH > 2048)  ? 4096  :
                                        (RAM_DEPTH > 1024)  ? 2048  :
                                        (RAM_DEPTH > 512)   ? 1024  :
                                        (RAM_DEPTH > 256)   ? 512   :
                                        (RAM_DEPTH > 128)   ? 256   :
                                        (RAM_DEPTH > 64)    ? 128   :
                                        (RAM_DEPTH > 32)    ? 64    :
                                        (RAM_DEPTH > 16)    ? 32    :
                                        (RAM_DEPTH > 8)     ? 16    :
                                        (RAM_DEPTH > 4)     ? 8     :
                                        (RAM_DEPTH > 2)     ? 4     : 2;
    localparam CNT_WIDTH = ADDR_WIDTH + 1;
    //----------------------------------------------------------------------//
    // external signals                                                     //
    //----------------------------------------------------------------------//
    input                           clk_push;
    input                           clk_pop;
    input                           rst_n;
    input                           push_req_n;
    input                           pop_req_n;
    output [ADDR_WIDTH - 1 : 0]     wr_addr;
    output                          we_n;
    output reg                      push_empty;
    output reg                      push_ae;
    output reg                      push_hf;
    output reg                      push_af;
    output reg                      push_full;
    output reg                      push_error;
    output reg                      pop_empty;
    output reg                      pop_ae;
    output reg                      pop_hf;
    output reg                      pop_af;
    output reg                      pop_full;
    output reg                      pop_error;
    output [ADDR_WIDTH - 1 : 0]     rd_addr;
    output reg [ADDR_WIDTH : 0]     push_word_count;
    output reg [ADDR_WIDTH : 0]     pop_word_count;
    input                           test;
    //----------------------------------------------------------------------//
    // registers                                                            //
    //----------------------------------------------------------------------//
    function [ADDR_WIDTH : 0] bin2gray;  // соединение информационных данных с проверочными (0)
        input bit [ADDR_WIDTH : 0] data;
        begin
            bin2gray = data ^ (data >> 1);
        end
    endfunction

    function [ADDR_WIDTH : 0] gray2bin;  // соединение информационных данных с проверочными (0)
        input   bit [ADDR_WIDTH : 0] data;
        bit [ADDR_WIDTH : 0] shift;
        bit [ADDR_WIDTH : 0] sum;
        begin
            shift = data;
            for (int i = 0; i < ADDR_WIDTH + 1; i ++)
                begin
                    sum [i] = ^shift[ADDR_WIDTH : 0];
                    gray2bin [i] = ^shift[ADDR_WIDTH : 0];
                    shift = shift>>1;
                end
            gray2bin = sum;
        end
    endfunction
    //----------------------------------------------------------------------//
    // registers                                                            //
    //----------------------------------------------------------------------//
    reg [ADDR_WIDTH : 0]    next_cnt_wr;
    reg [ADDR_WIDTH : 0]    next_cnt_rd;
    reg [ADDR_WIDTH : 0]    wr_addr_reg;
    reg [ADDR_WIDTH : 0]    rd_addr_reg;
    reg [ADDR_WIDTH : 0]    sync_cnt_bin_rd_r;
    reg [ADDR_WIDTH : 0]    sync_cnt_bin_wr_r;
    //----------------------------------------------------------------------//
    // wire                                                                 //
    //----------------------------------------------------------------------//
    wire                            wr_en;
    wire                            rd_en;
    wire    [ADDR_WIDTH : 0]        cnt_wr;
    wire    [ADDR_WIDTH : 0]        cnt_rd;
    wire    [ADDR_WIDTH : 0]        sync_cnt_wr;
    wire    [ADDR_WIDTH : 0]        sync_cnt_rd;
    wire    [ADDR_WIDTH : 0]        sync_cnt_bin_wr;
    wire    [ADDR_WIDTH : 0]        sync_cnt_bin_rd;
    wire    [ADDR_WIDTH : 0]        sync_cnt_bin_rd_w;
    wire    [ADDR_WIDTH : 0]        sync_cnt_bin_wr_w;
    //----------------------------------------------------------------------//
    // assigns                                                              //
    //----------------------------------------------------------------------//
    // разница между счетчиками количественное изменение
    assign sync_cnt_bin_rd_w = sync_cnt_bin_rd - sync_cnt_bin_rd_r;
    assign sync_cnt_bin_wr_w = sync_cnt_bin_wr - sync_cnt_bin_wr_r;
    // на выход
    assign we_n             = ~wr_en;
    // счетчик для интерфейса записи
    assign wr_en            = (~push_full & ~push_req_n);
    assign cnt_wr           = wr_addr_reg + wr_en;
    // счетчик для интерфейса чтения
    assign rd_en            = (~pop_empty & ~pop_req_n);
    assign cnt_rd           = rd_addr_reg + rd_en;
    // для интерфейса синхронизации
    assign sync_cnt_bin_wr  = gray2bin(sync_cnt_wr);
    assign sync_cnt_bin_rd  = gray2bin(sync_cnt_rd);
    // на выход к памяти
    assign wr_addr = wr_addr_reg [ADDR_WIDTH - 1 : 0];
    assign rd_addr = rd_addr_reg [ADDR_WIDTH - 1 : 0];
    //----------------------------------------------------------------------//
    // Component instantiations                                             //
    //----------------------------------------------------------------------//
    ew_sync
    #(
        .DATA_WIDTH     (CNT_WIDTH),     // ширина шинны данных
        .SYNC           (WR_SYNC),          // количество тактов на синхронизацию предпочтительно 2 для высоких частот 3
        .RST_MODE       (RST_MODE)          // вариант работы сброса 0 асинхронный сброс, 1 синхронный сброс
    )
    ew_sync_wr
    (
        .clk        (clk_push),
        .rst_n      (rst_n),
        .init_n     (1'b1),
        .test       (test),
        .data_i     (next_cnt_rd),
        .data_o     (sync_cnt_rd)
    );

    ew_sync
    #(
        .DATA_WIDTH     (CNT_WIDTH),     // ширина шинны данных
        .SYNC           (RD_SYNC),          // количество тактов на синхронизацию предпочтительно 2 для высоких частот 3
        .RST_MODE       (RST_MODE)          // вариант работы сброса 0 асинхронный сброс, 1 синхронный сброс
    )
    ew_sync_rd
    (
        .clk        (clk_pop),
        .rst_n      (rst_n),
        .init_n     (1'b1),
        .test       (1'b0),
        .data_i     (next_cnt_wr),
        .data_o     (sync_cnt_wr)
    );
    //----------------------------------------------------------------------//
    // logic                                                                //
    //----------------------------------------------------------------------//
    generate
        if (RST_MODE == 0)
            begin
                always @(posedge clk_push or negedge rst_n)
                    begin
                        if (~rst_n) // наивысший приоритет сброс
                            begin
                                push_error          <= 1'b0;
                                push_empty          <= 1'b1;
                                push_full           <= 1'b0;
                                push_ae             <= 1'b1;
                                push_hf             <= 1'b0;
                                push_af             <= 1'b0;
                                next_cnt_wr         <= {ADDR_WIDTH{1'b0}};
                                wr_addr_reg         <= {ADDR_WIDTH{1'b0}};
                                push_word_count     <= {ADDR_WIDTH{1'b0}};
                                sync_cnt_bin_rd_r   <= {ADDR_WIDTH{1'b0}};
                            end
                        else
                            begin
                                sync_cnt_bin_rd_r   <= sync_cnt_bin_rd;
                                wr_addr_reg         <= cnt_wr [ADDR_WIDTH : 0];
                                push_empty          <= (cnt_wr == sync_cnt_bin_rd);
                                push_full           <= ((push_word_count - sync_cnt_bin_rd_w + wr_en) == RAM_DEPTH );
                                push_ae             <= ((push_word_count - sync_cnt_bin_rd_w + wr_en) <= WR_AE_LVL);
                                push_hf             <= ((push_word_count - sync_cnt_bin_rd_w + wr_en) >= RAM_DEPTH/2);
                                push_af             <= ((push_word_count - sync_cnt_bin_rd_w + wr_en) >= RAM_DEPTH - WR_AF_LVL);
                                next_cnt_wr         <= bin2gray(cnt_wr);
                                if (~push_req_n)    // условие записи в память
                                    begin
                                        
                                        if (~push_full)
                                            begin
                                                if (ERR_MODE == 1)
                                                    push_error  <= 1'b0;    
                                            end
                                        else
                                            push_error  <= 1'b1;
                                    end
                                if (wr_en)
                                    push_word_count <= push_word_count + wr_en - sync_cnt_bin_rd_w[ADDR_WIDTH - 1 : 0];
                                else
                                    push_word_count <= push_word_count - sync_cnt_bin_rd_w[ADDR_WIDTH - 1 : 0];
                            end
                    end
                always @(posedge clk_pop or negedge rst_n)
                    begin
                        if (~rst_n) // наивысший приоритет сброс
                            begin
                                pop_error           <= 1'b0;
                                pop_empty           <= 1'b1;
                                pop_full            <= 1'b0;
                                pop_ae              <= 1'b1;
                                pop_hf              <= 1'b0;
                                pop_af              <= 1'b0;
                                next_cnt_rd         <= {ADDR_WIDTH{1'b0}};
                                rd_addr_reg         <= {ADDR_WIDTH{1'b0}};
                                pop_word_count      <= {ADDR_WIDTH{1'b0}};
                                sync_cnt_bin_wr_r   <= {ADDR_WIDTH{1'b0}};
                            end
                        else
                            begin
                                sync_cnt_bin_wr_r   <= sync_cnt_bin_wr;
                                rd_addr_reg         <= cnt_rd [ADDR_WIDTH : 0];
                                pop_empty           <= (sync_cnt_bin_wr == cnt_rd);
                                pop_full            <= ((pop_word_count + sync_cnt_bin_wr_w - rd_en) >= RAM_DEPTH );
                                pop_ae              <= ((pop_word_count + sync_cnt_bin_wr_w - rd_en) <= RD_AE_LVL);
                                pop_hf              <= ((pop_word_count + sync_cnt_bin_wr_w - rd_en) >= RAM_DEPTH/2);
                                pop_af              <= ((pop_word_count + sync_cnt_bin_wr_w - rd_en) >= RAM_DEPTH - RD_AF_LVL);
                                next_cnt_rd         <= bin2gray(cnt_rd);
                                if (~pop_req_n)
                                    begin
                                        if (~pop_empty)
                                            begin
                                                if (ERR_MODE == 1)
                                                    pop_error  <= 1'b0;
                                            end
                                        else
                                            pop_error  <= 1'b1;
                                    end
                                if (rd_en)
                                    pop_word_count <= pop_word_count - rd_en + sync_cnt_bin_wr_w[ADDR_WIDTH - 1 : 0];
                                else
                                    pop_word_count <= pop_word_count + sync_cnt_bin_wr_w[ADDR_WIDTH - 1 : 0];
                            end
                    end
            end
        else
            begin
                always @(posedge clk_push)
                    begin
                        if (~rst_n) // наивысший приоритет сброс
                            begin
                                push_error          <= 1'b0;
                                push_empty          <= 1'b1;
                                push_full           <= 1'b0;
                                push_ae             <= 1'b1;
                                push_hf             <= 1'b0;
                                push_af             <= 1'b0;
                                next_cnt_wr         <= {ADDR_WIDTH{1'b0}};
                                wr_addr_reg         <= {ADDR_WIDTH{1'b0}};
                                push_word_count     <= {ADDR_WIDTH{1'b0}};
                                sync_cnt_bin_rd_r   <= {ADDR_WIDTH{1'b0}};
                            end
                        else
                            begin
                                sync_cnt_bin_rd_r   <= sync_cnt_bin_rd;
                                wr_addr_reg         <= cnt_wr [ADDR_WIDTH : 0];
                                push_empty          <= (cnt_wr == sync_cnt_bin_rd);
                                push_full           <= ((push_word_count - sync_cnt_bin_rd_w + wr_en) == RAM_DEPTH );
                                push_ae             <= ((push_word_count - sync_cnt_bin_rd_w + wr_en) <= WR_AE_LVL);
                                push_hf             <= ((push_word_count - sync_cnt_bin_rd_w + wr_en) >= RAM_DEPTH/2);
                                push_af             <= ((push_word_count - sync_cnt_bin_rd_w + wr_en) >= RAM_DEPTH - WR_AF_LVL);
                                next_cnt_wr         <= bin2gray(cnt_wr);
                                if (~push_req_n)    // условие записи в память
                                    begin
                                        
                                        if (~push_full)
                                            begin
                                                if (ERR_MODE == 1)
                                                    push_error  <= 1'b0;    
                                            end
                                        else
                                            push_error  <= 1'b1;
                                    end
                                if (wr_en)
                                    push_word_count <= push_word_count + wr_en - sync_cnt_bin_rd_w[ADDR_WIDTH - 1 : 0];
                                else
                                    push_word_count <= push_word_count - sync_cnt_bin_rd_w[ADDR_WIDTH - 1 : 0];
                            end
                    end
                always @(posedge clk_pop)
                    begin
                        if (~rst_n) // наивысший приоритет сброс
                            begin
                                pop_error           <= 1'b0;
                                pop_empty           <= 1'b1;
                                pop_full            <= 1'b0;
                                pop_ae              <= 1'b1;
                                pop_hf              <= 1'b0;
                                pop_af              <= 1'b0;
                                next_cnt_rd         <= {ADDR_WIDTH{1'b0}};
                                rd_addr_reg         <= {ADDR_WIDTH{1'b0}};
                                pop_word_count      <= {ADDR_WIDTH{1'b0}};
                                sync_cnt_bin_wr_r   <= {ADDR_WIDTH{1'b0}};
                            end
                        else
                            begin
                                sync_cnt_bin_wr_r   <= sync_cnt_bin_wr;
                                rd_addr_reg         <= cnt_rd [ADDR_WIDTH : 0];
                                pop_empty           <= (sync_cnt_bin_wr == cnt_rd);
                                pop_full            <= ((pop_word_count + sync_cnt_bin_wr_w - rd_en) >= RAM_DEPTH );
                                pop_ae              <= ((pop_word_count + sync_cnt_bin_wr_w - rd_en) <= RD_AE_LVL);
                                pop_hf              <= ((pop_word_count + sync_cnt_bin_wr_w - rd_en) >= RAM_DEPTH/2);
                                pop_af              <= ((pop_word_count + sync_cnt_bin_wr_w - rd_en) >= RAM_DEPTH - RD_AF_LVL);
                                next_cnt_rd         <= bin2gray(cnt_rd);
                                if (~pop_req_n)
                                    begin
                                        if (~pop_empty)
                                            begin
                                                if (ERR_MODE == 1)
                                                    pop_error  <= 1'b0;
                                            end
                                        else
                                            pop_error  <= 1'b1;
                                    end
                                if (rd_en)
                                    pop_word_count <= pop_word_count - rd_en + sync_cnt_bin_wr_w[ADDR_WIDTH - 1 : 0];
                                else
                                    pop_word_count <= pop_word_count + sync_cnt_bin_wr_w[ADDR_WIDTH - 1 : 0];
                            end
                    end
            end
    endgenerate
endmodule
