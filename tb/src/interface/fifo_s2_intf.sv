`ifndef _GUARD_FIFO_INTF_
    `define _GUARD_FIFO_INTF_
   
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

    //----------------------------------------------------------------------------//
    // Clocking Blocks                                                            //
    //----------------------------------------------------------------------------//   

    //----------------------------------------------------------------------------//
    // Modports                                                                   //
    //----------------------------------------------------------------------------// 

    modport master
    (
        input                           push_req_n,
                                        pop_req_n,
                                        data_in,
        output                          push_empty,
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

endinterface : iffifo

`endif