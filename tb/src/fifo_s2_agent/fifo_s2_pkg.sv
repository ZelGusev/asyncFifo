/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Этот пакет (package) содержит все компоненты относящиеся к агенту ecc
--                     Везде где используется данный интерфейс надо импортировать этот пакет.
-—                     
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
`ifndef _GUARD_FIFO_S2_PKG_
   `define _GUARD_FIFO_S2_PKG_
    `timescale 1ns/1ns
package fifo_s2_pkg;
    `include "uvm_macros.svh"    
    import uvm_pkg::*;

    `include "fifo_s2_seq_item.svh"
    `include "fifo_s2_sequence.svh"
    `include "fifo_s2_sequencer.svh"

    `include "fifo_s2_driver.svh"
    `include "fifo_s2_monitor.svh" 
    `include "fifo_s2_agent.svh"
   
endpackage : fifo_s2_pkg

`endif