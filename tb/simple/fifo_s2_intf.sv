interface iffifo #(
    parameter integer DATA_WIDTH        = 32
    )
    (input bit clk_push, input bit clk_pop, input bit rst_n);
    //----------------------------------------------------------------------------//
    // Declare Interface Signals                                                  //
    //----------------------------------------------------------------------------//

    logic                           push_req_n;
    logic                           pop_req_n;
    logic   [DATA_WIDTH - 1 : 0]    data_in;
    logic                           push_empty;
    logic                           push_ae;
    logic                           push_hf;
    logic                           push_af;
    logic                           push_full;
    logic                           push_error;
    logic                           pop_empty;
    logic                           pop_ae;
    logic                           pop_hf;
    logic                           pop_af;
    logic                           pop_full;
    logic                           pop_error;
    logic   [DATA_WIDTH - 1 : 0]    data_out;



endinterface : iffifo