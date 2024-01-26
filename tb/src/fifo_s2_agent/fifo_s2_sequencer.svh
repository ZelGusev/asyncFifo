/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Класс передающий тестовые последовательности от формирователя в драйвер (sequencer)
--                     
-—                     
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
`ifndef _GUARD_FIFO_S2_SQER_
    `define _GUARD_FIFO_S2_SQER_

class Fifo_sequencer extends uvm_sequencer #(Fifo_seq_item);
    // UVM automation macros
    `uvm_component_utils(Fifo_sequencer)
    // Constructor
    function new(string name = "Fifo_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase
   
endclass : Fifo_sequencer

`endif