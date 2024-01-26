/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : sync for fifo  dw_fifoctl_s2_sf
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/

module sync_mux(
    clk_0,
    clk_1,
    rst_n,
    en,
    data_i,
    data_o
    );

    //----------------------------------------------------------------------//
    // external parameters                                                  //
    //----------------------------------------------------------------------//
    parameter integer DATA_WIDTH    = 32;        // ширина шинны данных
    parameter integer SYNC          = 2;        // количество тактов на синхронизацию предпочтительно 2 для высоких частот 3 для read
    parameter integer RST_MODE      = 0;        // вариант работы сброса 0 асинхронный сброс, 1 синхронный сброс
    //----------------------------------------------------------------------//
    // internal parameters                                                  //
    //----------------------------------------------------------------------//
    localparam C_SYNC = (SYNC == 0)? 2 : SYNC + 1;
    localparam N_SYNC = (SYNC == 0)? 1 : SYNC;
    //----------------------------------------------------------------------//
    // external signals                                                     //
    //----------------------------------------------------------------------//
    input                           clk_0;
    input                           clk_1;
    input                           rst_n;
    input                           en;
    input [DATA_WIDTH - 1 : 0]      data_i;
    output  [DATA_WIDTH - 1 : 0]    data_o;
    //----------------------------------------------------------------------//
    // registers                                                            //
    //----------------------------------------------------------------------//
    reg [DATA_WIDTH - 1 : 0]        data_reg;
    reg [DATA_WIDTH - 1 : 0]        mux_reg;
    reg [C_SYNC - 1 : 0]            en_shift;
    reg                             en_reg;
    //----------------------------------------------------------------------//
    // wire                                                                 //
    //----------------------------------------------------------------------//
    wire [DATA_WIDTH - 1 : 0]       mux_data;
    //----------------------------------------------------------------------//
    // assigns                                                              //
    //----------------------------------------------------------------------//
    // assign mux_data = (en_shift[N_SYNC - 1])? data_reg : mux_reg;
    assign mux_data = (en_shift[N_SYNC - 1])? mux_reg : data_reg;
    assign data_o   = mux_reg;
    //----------------------------------------------------------------------//
    // Component instantiations                                             //
    //----------------------------------------------------------------------//
    //----------------------------------------------------------------------//
    // logic                                                                //
    //----------------------------------------------------------------------//
    always @(posedge clk_0 or negedge rst_n)
        begin
            if (~rst_n)
                begin
                    data_reg    <= {DATA_WIDTH{1'b0}};
                    en_reg      <= 1'b0;
                end
            else
                begin
                    data_reg    <= data_i;
                    en_reg      <= en;
                end
        end
    always @(posedge clk_1 or negedge rst_n)
        begin
            if (~rst_n)
                begin
                    mux_reg     <= {DATA_WIDTH{1'b0}};
                    en_shift    <= {C_SYNC{1'b0}};
                end
            else
                begin
                    mux_reg     <= mux_data;
                    en_shift    <= {en_shift[C_SYNC - 2 : 0], clk_0};
                end
        end
endmodule