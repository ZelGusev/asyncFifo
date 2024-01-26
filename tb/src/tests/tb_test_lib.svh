/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Библиотека тестов для тестового окружения 
-—                     
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/

`ifndef _GUARD_TB_LIB_
    `define _GUARD_TB_LIB_

    import tb_env_pkg::*;
    import parameter_pkg::*;
    //------------------------------------------------------------------------------------------------//
    // TEST BASE                                                                                      //
    //------------------------------------------------------------------------------------------------//
class Test_base extends uvm_test; 

    string   info_msg_id    = "INFO";
    string   warning_msg_id = "WARNING";
    string   error_msg_id   = "ERROR";
    string   fatal_msg_id   = "FATAL ERROR";

    Fifo_env    env;

    parameter integer C_NUM_TX = 100;
    // UVM Factory registration macros
    `uvm_component_utils(Test_base) 

    fifo_s2_pkg::Fifo_sequence        fifo_seq;
    //----------------------------------------------------------------------//
    // Create                                                               //
    //----------------------------------------------------------------------//
    function new(string name, uvm_component parent = null); 
        super.new(name, parent); 
    endfunction 
   
    //----------------------------------------------------------------------//
    // Build Phase                                                          //
    //----------------------------------------------------------------------//
    function void build_phase(uvm_phase phase); 
        super.build_phase(phase);
        // Create the tb
        env = Fifo_env::type_id::create("env", this);
    endfunction 
   
    //----------------------------------------------------------------------//
    // End of Elaboration Phase                                             //
    //----------------------------------------------------------------------//
    function void end_of_elaboration_phase(uvm_phase phase);
    endfunction : end_of_elaboration_phase
    //-----------------------------------------------------------------------//
    // Run Test                                                              //
    //-----------------------------------------------------------------------//
    integer num_tx = C_NUM_TX;
    integer arg;
    bit [DATA_WIDTH - 1 : 0]    data [STREAM_DEPTH];
    integer num_wr_word;
    integer num_rd_word;
    string name;
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        fifo_seq    = fifo_s2_pkg::Fifo_sequence::type_id::create("fifo_seq", this);
        // // Начальные значения сигналов
        fork : timeout_block
            begin
                repeat (1) begin
                    //#G_T_CYCLE;
                    if ($value$plusargs ("NUM_RACE=%0d", arg))
                        begin
                            $display("Set Number of Transaction = %d", arg);
                            num_tx = arg;
                        end
                    else
                        begin
                            $display("Set Default Amount Of Transaction = %d", C_NUM_TX);
                            num_tx = C_NUM_TX;
                        end
                    $display("//---------- start sequence --------------// ");
                    #100;
                    fifo_seq.set_rst(1'b1).start(env.m_agent.sequencer);
                    #100;
                    rand_data();
                    fifo_seq.wr_rd_data(num_wr_word, data).start(env.m_agent.sequencer);
                    #100;
                    for(int i = 0; i < num_tx; i++)
                        begin
                            gen_test();
                        end
                    #1000;
                    // repeat (num_tx) fifo_seq.gen_pckt(NONE).start(env.m_agent.sequencer);
                    $display("//---------- stop sequence ---------------// ");
                    //#1ms;
                end
            end
        join_any
        // disable timeout_block;
        phase.drop_objection(this);    
    endtask : run_phase
    //----------------------------------------------------------------------//
    // Extract Phase                                                        //
    //----------------------------------------------------------------------//
    function void extract_phase(uvm_phase phase);
    $display("");
        if (env.m_scoreboard.sum != 0)
            begin
                $display ("----------------------------------------------------------------------------------------------");
                $display ("------------------------------- T E S T   F A I L E D ----------------------------------------");
                $display ("----------------------------------------------------------------------------------------------");
            end
        else
            begin
                $display ("----------------------------------------------------------------------------------------------");
                $display ("------------------------------ T E S T   S U C C E S S E D -----------------------------------");
                $display ("----------------------------------------------------------------------------------------------");
            end
        if (env.m_scoreboard.sum != 0)
            `uvm_fatal(get_type_name(), $sformatf("TEST FAILED"));
    endfunction : extract_phase
    //----------------------------------------------------------------------//
    // check Phase                                                        //
    //----------------------------------------------------------------------//
    function void check_phase(uvm_phase phase);
    endfunction : check_phase
    //----------------------------------------------------------------------//
    // report Phase                                                        //
    //----------------------------------------------------------------------//
    function void report_phase(uvm_phase phase);
    endfunction : report_phase

    virtual task gen_test();
        integer delay;
        integer num_wr_word;
        integer num_rd_word;
        begin
            randcase
                1: 
                    begin
                        //$display(" ---------------- Inition Reset Sequence ---------------- ");
                        delay = $urandom_range(1,50);
                        #delay;
                        fifo_seq.set_rst(1'b0).start(env.m_agent.sequencer);
                        delay = $urandom_range(100,200);
                        #delay;
                        fifo_seq.set_rst(1'b1).start(env.m_agent.sequencer);
                        delay = $urandom_range(1,50);
                        #delay;
                    end
                2:
                    begin
                        //$display(" ---------------- Inition Write Sequence ---------------- ");
                        rand_data();
                        num_wr_word = $urandom_range(1,RAM_DEPTH*2);
                        fifo_seq.wr_data(num_wr_word, data).start(env.m_agent.sequencer);
                        delay = $urandom_range(1,50);
                        #delay;
                    end
                2:
                    begin
                        //$display(" ---------------- Inition Read Sequence ---------------- ");
                        num_rd_word = $urandom_range(1,RAM_DEPTH*2);
                        fifo_seq.rd_data(num_rd_word).start(env.m_agent.sequencer);
                        delay = $urandom_range(1,50);
                        #delay;
                    end
            endcase

        end
    endtask


    virtual task rand_data();
        begin
            num_wr_word = $urandom_range(1,15);
            for(int i = 0; i < RAM_DEPTH*4; i++)
                begin
                    data[i] = $urandom;
                    //data[i] = i + 1;
                end
        end
    endtask
endclass : Test_base

`endif // _GUARD_TB_LIB_