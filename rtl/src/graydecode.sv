/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : decode Grey
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/

module graydecode(
    data_i,
    data_o
    );
    //----------------------------------------------------------------------//
    // external parameters                                                  //
    //----------------------------------------------------------------------//
    parameter integer DATA_WIDTH    = 4;        // ширина шинны данных
    //----------------------------------------------------------------------//
    // internal parameters                                                  //
    //----------------------------------------------------------------------//
    //----------------------------------------------------------------------//
    // external signals                                                     //
    //----------------------------------------------------------------------//
    input  [DATA_WIDTH - 1 : 0]     data_i;
    output  [DATA_WIDTH - 1 : 0]    data_o;
    //----------------------------------------------------------------------//
    // registers                                                            //
    //----------------------------------------------------------------------//
    //----------------------------------------------------------------------//
    // wire                                                                 //
    //----------------------------------------------------------------------//
    //----------------------------------------------------------------------//
    // assigns                                                              //
    //----------------------------------------------------------------------//
    function [DATA_WIDTH - 1 : 0] decode;  // соединение информационных данных с проверочными (0)
        input   bit [DATA_WIDTH - 1 : 0]    data;
        bit [DATA_WIDTH - 1 : 0]    shift;
        bit [DATA_WIDTH - 1 : 0]    sum;
        begin
            shift = data;
            for (int i = 0; i < DATA_WIDTH; i ++)
                begin
                    sum [i] = ^shift[DATA_WIDTH - 1 : 0];
                    shift = shift>>1;
                end
            decode = sum;
        end
    endfunction
    assign data_o = decode(data_i);
    //----------------------------------------------------------------------//
    // Component instantiations                                             //
    //----------------------------------------------------------------------//
    //----------------------------------------------------------------------//
    // logic                                                                //
    //----------------------------------------------------------------------//
endmodule
