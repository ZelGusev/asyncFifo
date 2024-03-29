/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : sync for fifo
--                      Требует использование кодов Грея так предполагает изменение 1 бита на шине
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/

module ew_sync(
    clk,
    rst_n,
    init_n,
    test,
    data_i,
    data_o
    );

    //----------------------------------------------------------------------//
    // external parameters                                                  //
    //----------------------------------------------------------------------//
    parameter integer DATA_WIDTH    = 4;        // ширина шинны данных
    parameter integer SYNC          = 2;        // количество тактов на синхронизацию предпочтительно 2 для высоких частот 3 для read
    parameter integer RST_MODE      = 0;        // вариант работы сброса 0 асинхронный сброс, 1 синхронный сброс
    //----------------------------------------------------------------------//
    // internal parameters                                                  //
    //----------------------------------------------------------------------//
    localparam C_SYNC = (SYNC == 0)? 2 : (SYNC == 1)? 2 : SYNC;
    //----------------------------------------------------------------------//
    // external signals                                                     //
    //----------------------------------------------------------------------//
    input                           clk;
    input                           rst_n;
    input                           init_n;
    input                           test;
    input [DATA_WIDTH - 1 : 0]      data_i;
    output  [DATA_WIDTH - 1 : 0]    data_o;
    //----------------------------------------------------------------------//
    // registers                                                            //
    //----------------------------------------------------------------------//
    reg [C_SYNC*DATA_WIDTH - 1 : 0] shift_data;
    //----------------------------------------------------------------------//
    // wire                                                                 //
    //----------------------------------------------------------------------//
    //----------------------------------------------------------------------//
    // assigns                                                              //
    //----------------------------------------------------------------------//
    assign data_o   = shift_data[C_SYNC*DATA_WIDTH - 1 : (C_SYNC - 1)*DATA_WIDTH];
    //----------------------------------------------------------------------//
    // Component instantiations                                             //
    //----------------------------------------------------------------------//
    //----------------------------------------------------------------------//
    // logic                                                                //
    //----------------------------------------------------------------------//
    always @(posedge clk or negedge rst_n)
        begin
            if (~rst_n)
                begin
                    shift_data  <= {C_SYNC*DATA_WIDTH{1'b0}};
                end
            else
                begin
                    shift_data  <= {shift_data[(C_SYNC - 1)*DATA_WIDTH - 1 : 0], data_i};
                end
        end
    always @(negedge clk)
        begin
            if (SYNC == 1)
                shift_data  <= {shift_data[(C_SYNC - 1)*DATA_WIDTH - 1 : 0], data_i};
        end
endmodule
