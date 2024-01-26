/*************************************************************************************************************
--    Система        : 
--    Разработчик    :
--    Автор          : Гусев Игорь
--
--    Назначение     : Класс монитора (monitor) интерфейса ecc
-—                     
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
`ifndef _GUARD_FIFO_S2_MONITOR_
    `define _GUARD_FIFO_S2_MONITOR_

    import parameter_pkg::*;
class Fifo_monitor extends uvm_monitor;
 
    // Virtual Interface
    virtual ifclk#(     .CLK_MHZ    (WR_CLK_MHZ))      wr_clk_gen;
    virtual ifclk#(     .CLK_MHZ    (RD_CLK_MHZ))      rd_clk_gen;
    virtual iffifo#(  .DATA_WIDTH (DATA_WIDTH)  )      fifo_if;
    
   
    // UVM Factory registration macros
    uvm_analysis_port #(Fifo_seq_item)  wr_data_stream;
    uvm_analysis_port #(Fifo_seq_item)  rd_data_stream;

    uvm_analysis_port #(Fifo_seq_item)  wr_addr_delayed;
    uvm_analysis_port #(Fifo_seq_item)  rd_addr_delayed;


    // item
    Fifo_seq_item    rx_seq;
    Fifo_seq_item    tx_seq;
    `uvm_component_utils(Fifo_monitor)
 
    //----------------------------------------------------------------------//
    // Create                                                               //
    //----------------------------------------------------------------------//
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new
  
    //----------------------------------------------------------------------//
    // Build Phase                                                          //
    //----------------------------------------------------------------------//
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual ifclk   #(  .CLK_MHZ    (WR_CLK_MHZ)))::get(this, "*", "wr_clk_gen", wr_clk_gen))
            `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".wr_clk_gen"});
        if(!uvm_config_db #(virtual ifclk   #(  .CLK_MHZ    (RD_CLK_MHZ)))::get(this, "*", "rd_clk_gen", rd_clk_gen))
            `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".rd_clk_gen"});
        if(!uvm_config_db #(virtual iffifo  #(  .DATA_WIDTH (DATA_WIDTH)))::get(this, "*", "fifo_if", fifo_if))
            `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".fifo_if"});
        // creating port
        // analysis port
        wr_data_stream      = new("wr_data_stream", this);
        rd_data_stream      = new("rd_data_stream", this);

        wr_addr_delayed     = new("wr_addr_delayed", this);
        rd_addr_delayed     = new("rd_addr_delayed", this);
        // item
        rx_seq    = Fifo_seq_item::type_id::create("rx_seq");
        tx_seq    = Fifo_seq_item::type_id::create("tx_seq");
    endfunction: build_phase
    //----------------------------------------------------------------------//
    // Run Phase                                                            //
    //----------------------------------------------------------------------//
    bit sens_wr;
    virtual task run_phase(uvm_phase phase);
        fork
            // ------------------> //// отслеживание сигналов rtl блока итоговый результат работы модуля
            forever begin
                if (RST_MODE == 0)  // асинхронный сброс сработает только по отрицательному фронту сигнала сброса
                    begin
                        @(negedge fifo_if.rst_n);
                        rx_seq.rst_n  = fifo_if.rst_n;
                        wr_data_stream.write(rx_seq);
                        //$display(" DETECTED RESET TRANSACTION %t", $time);
                    end
                else if (RST_MODE == 1)
                    begin
                        @(posedge fifo_if.clk_push);  // проверка каждый такт
                        if (~fifo_if.rst_n)
                            begin
                                rx_seq.rst_n  = fifo_if.rst_n;
                                wr_data_stream.write(rx_seq);
                                //$display(" DETECTED RESET TRANSACTION %t", $time);
                                wait(fifo_if.rst_n);
                            end
                        
                    end
            end
            forever begin
                @(wr_clk_gen.clk);
                //if (~fifo_if.push_req_n && fifo_if.rst_n)
                    begin
                        rx_seq.clk          = wr_clk_gen.clk;
                        // $display(" fifo_if.push_req_n = %d    fifo_if.rst_n = %d    sum = %d ", fifo_if.push_req_n, fifo_if.rst_n, ~fifo_if.push_req_n && fifo_if.rst_n);
                        rx_seq.rst_n        = fifo_if.rst_n;
                        rx_seq.push_req_n   = fifo_if.push_req_n;
                        rx_seq.pop_req_n    = fifo_if.pop_req_n;
                        rx_seq.data_in      = fifo_if.data_in;
                        rx_seq.push_empty   = fifo_if.push_empty;
                        rx_seq.push_ae      = fifo_if.push_ae;
                        rx_seq.push_hf      = fifo_if.push_hf;
                        rx_seq.push_af      = fifo_if.push_af;
                        rx_seq.push_full    = fifo_if.push_full;
                        rx_seq.push_error   = fifo_if.push_error;
                        // $display(" DETECTED WRITE TRANSACTION %t", $time);
                        // $display(" WR DATA = %h", fifo_if.data_in);
                        wr_data_stream.write(rx_seq);
                    end
            end
            forever begin
                if (RST_MODE == 0)
                    begin
                        @(negedge fifo_if.rst_n);
                        tx_seq.rst_n  = fifo_if.rst_n;
                        rd_data_stream.write(tx_seq);
                    end
                else if (RST_MODE == 1)
                    begin
                        @(posedge fifo_if.clk_pop);
                        if (~fifo_if.rst_n)
                            begin
                                tx_seq.rst_n  = fifo_if.rst_n;
                                rd_data_stream.write(tx_seq);
                                wait(fifo_if.rst_n);
                            end
                    end
            end
            forever begin
                @(rd_clk_gen.clk);
                //if (~fifo_if.pop_req_n && fifo_if.rst_n)
                    begin
                        tx_seq.clk          = rd_clk_gen.clk;
                        //$display("::  MONITOR  tx_seq.clk = %d     rd_clk_gen.clk = %d ", tx_seq.clk, rd_clk_gen.clk);
                        tx_seq.rst_n        = fifo_if.rst_n;
                        tx_seq.push_req_n   = fifo_if.push_req_n;
                        tx_seq.pop_req_n    = fifo_if.pop_req_n;
                        tx_seq.data_out     = fifo_if.data_out;
                        tx_seq.pop_empty    = fifo_if.pop_empty;
                        tx_seq.pop_ae       = fifo_if.pop_ae;
                        tx_seq.pop_hf       = fifo_if.pop_hf;
                        tx_seq.pop_af       = fifo_if.pop_af;
                        tx_seq.pop_full     = fifo_if.pop_full;
                        tx_seq.pop_error    = fifo_if.pop_error;
                        // $display(" DETECTED READ TRANSACTION %t", $time);
                        // $display(" RD DATA = %h", fifo_if.data_out);
                        rd_data_stream.write(tx_seq);
                    end
            end
            //////////////////////////////////////////////////////////////////////////////////// <------------------
        join_any
    endtask : run_phase
    
endclass : 	Fifo_monitor

`endif