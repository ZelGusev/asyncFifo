   /*************************************************************************************************************
--    Система        : 
--    Разработчик    :
--    Автор          : Гусев Игорь
--
--    Назначение     : Класс формирования тестовых последовательностей (sequence) 
-—                     
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
`ifndef _GUARD_FIFO_S2_SEQ_
    `define _GUARD_FIFO_S2_SEQ_
   
    import parameter_pkg::*;
    //----------------------------------------------------------------------------//
    // Генератор последовательности для тестов                                    //
    //----------------------------------------------------------------------------//
class Fifo_sequence extends uvm_sequence #(Fifo_seq_item);
     
    // UVM automation macros
    `uvm_object_utils(Fifo_sequence)

    Fifo_seq_item req = new();

    // Constructor
    function new(string name = "Fifo_sequence");
        super.new(name);
    endfunction


    //  Body `uvm_do(item) - чисто рандом без псевдо в моем случае было бы `uvm_do(Fifo_seq_item) 
    virtual task body();
        //req = Fifo_seq_item::type_id::create("req");
        start_item(req);
        finish_item(req);
    endtask : body

    function Fifo_sequence set_rst(bit rst);
        this.req.rst_n      = rst;
        this.req.option     = RESET_S;
        return this;
    endfunction: set_rst

    function Fifo_sequence wr_data(integer num_wr_word, bit [DATA_WIDTH - 1 : 0] data [STREAM_DEPTH]);
        this.req.data           = data;
        this.req.num_wr_word    = num_wr_word;
        this.req.option         = WRITE_S;
        return this;
    endfunction: wr_data

    function Fifo_sequence rd_data(int num_rd_word);
        this.req.num_rd_word    = num_rd_word;
        this.req.option         = READ_S;
        return this;
    endfunction: rd_data

    function Fifo_sequence wr_rd_data(integer num_wr_word, bit [DATA_WIDTH - 1 : 0] data [STREAM_DEPTH]);
        this.req.data           = data;
        this.req.num_wr_word    = num_wr_word;
        this.req.option         = WR_RD_S;
        return this;
    endfunction: wr_rd_data
   
endclass : Fifo_sequence

`endif