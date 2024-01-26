/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Класс агента (agent) интерфейса  содержащий : sequencer, driver,
--                     monitor и analysis_port для управления и верификации интерфейса
-—                     
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
`ifndef _GUARD_FIFO_S2_AGENT_
    `define _GUARD_FIFO_S2_AGENT_

class Fifo_agent extends uvm_agent;
    //declaring agent components
    Fifo_driver         driver;
    Fifo_sequencer      sequencer;
    Fifo_monitor        monitor;
   
    uvm_analysis_port #(Fifo_seq_item)  wr_fifo_data;
    uvm_analysis_port #(Fifo_seq_item)  rd_fifo_data;

    // UVM Factory registration macros
    `uvm_component_utils(Fifo_agent)
 
    //-----------------------------------------------------------------------//
    // Create                                                                //
    //-----------------------------------------------------------------------//
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new
   
    //-----------------------------------------------------------------------//
    // Build Phase                                                           //
    //-----------------------------------------------------------------------//
    function void build_phase(uvm_phase phase); 
        super.build_phase(phase);
        wr_fifo_data     = new(.name("wr_fifo_data"),    .parent(this));
        rd_fifo_data     = new(.name("rd_fifo_data"),    .parent(this));
        
        driver          = Fifo_driver    ::type_id::create("driver", this);
        sequencer       = Fifo_sequencer ::type_id::create("sequencer", this);
        monitor         = Fifo_monitor   ::type_id::create("monitor", this);
   endfunction : build_phase
   
    //-----------------------------------------------------------------------//
    // Connect Phase                                                         //
    //-----------------------------------------------------------------------//   
    function void connect_phase(uvm_phase phase);
        driver.seq_item_port.   connect(sequencer.seq_item_export);

        monitor.wr_data_stream.    connect(wr_fifo_data);
        monitor.rd_data_stream.    connect(rd_fifo_data);
    endfunction : connect_phase
 
endclass : Fifo_agent

`endif
