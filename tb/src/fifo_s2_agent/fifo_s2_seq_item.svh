/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Класс базовой транзакции (item) записи интерфейса Ecc
--
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
`ifndef _GUARD_FIFO_S2_ITEM_
    `define _GUARD_FIFO_S2_ITEM_
   import parameter_pkg::*;
class Fifo_seq_item extends uvm_sequence_item;

    rand state_enum             option;

    bit                         clk;

    bit                         rst_n;
    bit                         push_req_n;
    bit                         pop_req_n;
    bit [DATA_WIDTH - 1 : 0]    data_in;
    bit [DATA_WIDTH - 1 : 0]    data_out;

    bit                         push_empty;
    bit                         push_ae;
    bit                         push_hf;
    bit                         push_af;
    bit                         push_full;
    bit                         push_error;
    bit                         pop_empty;
    bit                         pop_ae;
    bit                         pop_hf;
    bit                         pop_af;
    bit                         pop_full;
    bit                         pop_error;

    bit [DATA_WIDTH - 1 : 0]    data [STREAM_DEPTH];
    integer num_wr_word;
    integer num_rd_word;
    // UVM automation macros
    `uvm_object_utils_begin(Fifo_seq_item)
    //`uvm_field_int  (data     , UVM_ALL_ON)      
    `uvm_object_utils_end
         
    //----------------------------------------------------------------------------//
    // Constraints                                                                //
    //----------------------------------------------------------------------------//

    //----------------------------------------------------------------------------//
    // Methods                                                                    //
    //----------------------------------------------------------------------------//   
    //Constructor
    function new(string name = "Fifo_seq_item");
        super.new(name);
    endfunction : new

endclass : Fifo_seq_item

`endif
