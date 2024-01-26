/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Класс драйвера (driver) интерфейса
-—                     
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
`ifndef _GUARD_FIFO_S2_DRIVER_
    `define _GUARD_FIFO_S2_DRIVER_

    import parameter_pkg::*;
    
class Fifo_driver extends uvm_driver#(Fifo_seq_item);
    
    virtual ifclk#(     .CLK_MHZ    (WR_CLK_MHZ))      wr_clk_gen;
    virtual ifclk#(     .CLK_MHZ    (RD_CLK_MHZ))      rd_clk_gen;
    virtual iffifo#(  .DATA_WIDTH (DATA_WIDTH)  )      fifo_if;

    // UVM Factory registration macros
    `uvm_component_utils( Fifo_driver )
    
    Fifo_seq_item    fifo_seq;

    //----------------------------------------------------------------------//
    // Create                                                               //
    //----------------------------------------------------------------------//
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction:new 
    //----------------------------------------------------------------------//
    // Build Phase                                                          //
    //----------------------------------------------------------------------//
    function void build_phase(uvm_phase phase); 
        super.build_phase(phase);
        // Configure Interface
        if(!uvm_config_db #(virtual ifclk   #(  .CLK_MHZ    (WR_CLK_MHZ)))::get(this, "*", "wr_clk_gen", wr_clk_gen))
            `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".wr_clk_gen"});
        if(!uvm_config_db #(virtual ifclk   #(  .CLK_MHZ    (RD_CLK_MHZ)))::get(this, "*", "rd_clk_gen", rd_clk_gen))
            `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".rd_clk_gen"});
        if(!uvm_config_db #(virtual iffifo  #(  .DATA_WIDTH (DATA_WIDTH)))::get(this, "*", "fifo_if", fifo_if))
            `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".fifo_if"});
        // item
        fifo_seq    = Fifo_seq_item::type_id::create("fifo_seq");
    endfunction : build_phase

    //----------------------------------------------------------------------//
    // Coonect Phase                                                        //
    //----------------------------------------------------------------------//

    function void connect_phase(uvm_phase phase);
    endfunction: connect_phase
    //----------------------------------------------------------------------//
    // Run Phase                                                            //
    //----------------------------------------------------------------------//
    //state_enum  dr_option;
    bit en_rd = 1'b0;
    bit en_wr = 1'b0;
    // int num_data_word;
    // bit [3:0] income_data = 4'b0110;
    // bit [3:0] data_o;
    // bit [3:0] sum;
    // bit [3:0] shift_data;
    task run_phase(uvm_phase phase);
        uvm_report_info(get_full_name(),"Driver run phase...", UVM_LOW);
        
        fork
            begin   // rst
                rst_all();
                // shift_data = income_data;
                // for (int i = 0; i <= 3; i ++)
                //     begin
                //         $display("//--------------------------------//");
                //         $display("BEFOR shift = %b", shift_data);
                //         sum [i] = ^shift_data[3 : 0];
                //         $display("sum[%d] = %b", i , sum[i]);
                //         $display("sum = %b", sum);
                //         shift_data = shift_data>>1;
                //         $display("AFTER shift = %b", shift_data);
                //         $display("//--------------------------------//");
                //     end
                // data_o = sum;
                // $display("DONE data = %b", data_o);
            end
            forever begin
                @(negedge wr_clk_gen.rst_n)
                rst_all();
            end
            forever begin
                wait(en_wr);
                if (fifo_if.rst_n)
                    begin
                        for (int i = 0; i < fifo_seq.num_wr_word; i++)
                            begin
                                @(fifo_if.clk_push);
                                if (fifo_if.push_full)
                                    begin
                                        fifo_if.push_req_n  = 1'b1;
                                        wait(~fifo_if.push_full);
                                    end
                                
                                @(negedge fifo_if.clk_push);
                                if (fifo_if.push_full)
                                    begin
                                        fifo_if.push_req_n  = 1'b1;
                                        wait(~fifo_if.push_full);
                                        @(negedge fifo_if.clk_push);
                                    end
                                fifo_if.push_req_n  = 1'b0;
                                fifo_if.data_in     = fifo_seq.data[i];
                                //$display(" DATA = %h, num_word = %d", fifo_seq.data[i], i);
                            end
                    end
                @(negedge fifo_if.clk_push);
                fifo_if.push_req_n  = 1'b1;
                // $display(" WRITE END ");
                en_wr = 1'b0;
            end
            forever begin
                wait(en_rd);
                if (fifo_if.rst_n)
                    begin
                        fifo_if.pop_req_n  = 1'b1;
                        wait(~fifo_if.pop_empty);
                        for (int i = 0; i < fifo_seq.num_wr_word; i++)
                            begin
                                @(negedge fifo_if.clk_pop);
                                fifo_if.pop_req_n  = 1'b0;
                                @(posedge fifo_if.clk_pop);
                            end
                    end
                fifo_if.pop_req_n  = 1'b1;
                // $display(" READ END ");
                en_rd = 1'b0;
            end
            forever begin
                seq_item_port.get_next_item(fifo_seq);

                case (fifo_seq.option)
                    RESET_S:  wr_clk_gen.rst_n = fifo_seq.rst_n;
                    WRITE_S:
                        begin
                            // $display(" WRITE TO MEM ");
                            // $display(" RST = %d ", fifo_if.rst_n);
                            if (fifo_if.rst_n)
                                begin
                                    for (int i = 0; i < fifo_seq.num_wr_word; i++)
                                        begin
                                            @(posedge fifo_if.clk_push);
                                            fifo_if.data_in     = fifo_seq.data[i];
                                            fifo_if.push_req_n  = 1'b0;
                                            //$display(" DATA = %h, num_word = %d", fifo_seq.data[i], i);
                                        end
                                end
                            @(posedge fifo_if.clk_push);
                            fifo_if.push_req_n  = 1'b1;
                        end
                    READ_S:
                        begin
                            // $display(" READ FROM MEM ");
                            //$display(" READ FROM MEM data = %h, checkin = %h, addr = %h", ecc_rd_if.datain, ecc_rd_if.chkin, fifo_seq.addr);
                            if (fifo_if.rst_n)
                                begin
                                    for (int i = 0; i < fifo_seq.num_rd_word; i++)
                                        begin
                                            @(posedge fifo_if.clk_pop);
                                            fifo_if.pop_req_n  = 1'b0;
                                        end
                                end
                            @(posedge fifo_if.clk_pop);
                            fifo_if.pop_req_n  = 1'b1;
                        end
                    WR_RD_S:
                        begin
                            // $display(" STATE START ");
                            en_rd = 1'b1;
                            en_wr = 1'b1;
                            wait({en_rd,en_wr} == 2'b00);
                            // $display(" STATE END ");
                        end
                    default:;
                endcase
                seq_item_port.item_done();          // завершить последовательность 
            end
        join_any
    endtask : run_phase
   
    //------------------------------------------------------------------------//
    // Driver Task                                                            //
    //------------------------------------------------------------------------//
    virtual task rst_all();
        begin
            fifo_if.push_req_n      = '1;
            fifo_if.pop_req_n       = '1;
            fifo_if.data_in         = '0;
        end
    endtask : rst_all

    // virtual function void save_pckt();
    // endfunction : save_pckt

endclass : Fifo_driver

`endif

