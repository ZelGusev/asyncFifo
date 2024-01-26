/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Класс верхнего уровня тестового окружения (Environment).
-—                     Содержит объявление и соединение используемых верификационных компонентов.
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
`ifndef _GUARD_TB_ENV_
    `define _GUARD_TB_ENV_

    import fifo_s2_pkg::*;
    `include "tb_scoreboard.svh"

class Fifo_env extends uvm_env; 

    Fifo_agent          m_agent;
    Fifo_scoreboard     m_scoreboard;

    // UVM Factory registration macros
   
    `uvm_component_utils(Fifo_env)
   
    //----------------------------------------------------------------------//
    // Create                                                               //
    //----------------------------------------------------------------------//
    function new(string name, uvm_component parent); 
        super.new(name, parent); 
    endfunction : new
   
    //----------------------------------------------------------------------//
    // Build Phase                                                          //
    //----------------------------------------------------------------------//
    function void build_phase(uvm_phase phase); 
        uvm_report_info(get_full_name(),"Build...", UVM_LOW); 

        m_agent = Fifo_agent::type_id::create("m_agent",this);

        uvm_config_db #(int) ::set(this, "m_agent", "is_active", UVM_ACTIVE);
        m_scoreboard = Fifo_scoreboard ::type_id::create("m_scoreboard",this);
        
        uvm_report_info(get_full_name(),"Build completed", UVM_LOW); 
    endfunction : build_phase

    //----------------------------------------------------------------------//
    // Connect Phase                                                        //
    //----------------------------------------------------------------------//
    function void connect_phase(uvm_phase phase); 
        uvm_report_info(get_full_name(),"Connect...", UVM_LOW);
        // Connect agent monitor port to analysis export of Scoreboard
        m_agent.wr_fifo_data.connect(m_scoreboard.sb_fifo_wr_export);
        m_agent.rd_fifo_data.connect(m_scoreboard.sb_fifo_rd_export);
        uvm_report_info(get_full_name(),"Connect completed", UVM_LOW);
    endfunction : connect_phase

endclass : Fifo_env

`endif
