/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Test Top 
--                     
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
`ifndef _GUARD_TB_TOP_
    `define _GUARD_TB_TOP_
    `ifndef UVM_TESTNAME
        `define UVM_TESTNAME "Test_base"
    `endif
    `include "uvm_macros.svh"
module top_tb;
    import uvm_pkg::*;
    import tb_test_pkg::*;
    import parameter_pkg::*;

    // ------------- Interface -----------------//
    ifclk       #(  .CLK_MHZ (WR_CLK_MHZ)   )       wr_clk_gen   ();
    ifclk       #(  .CLK_MHZ (RD_CLK_MHZ)   )       rd_clk_gen   ();
    iffifo       #(  .DATA_WIDTH (DATA_WIDTH)   )   fifo_if      (.clk_push (wr_clk_gen.clk), .clk_pop(rd_clk_gen.clk), .rst_n(wr_clk_gen.rst_n));

    // -------- Component instantiations -------//
    ew_fifo_s2_sf
    #(
        .DATA_WIDTH (DATA_WIDTH),       // ширина шинны данных
        .RAM_DEPTH  (RAM_DEPTH),        // буфер количества слов
        .WR_AE_LVL  (WR_AE_LVL),        // almost empty num word    for write operation
        .WR_AF_LVL  (WR_AF_LVL),        // almost full num word     for write operation
        .RD_AE_LVL  (RD_AE_LVL),        // almost empty num word    for read operation
        .RD_AF_LVL  (RD_AF_LVL),        // almost full num word    for read operation
        .ERR_MODE   (ERR_MODE),         // вариант поведения сигнала ошибки если 0 при возникновении ошибки висит до ресета, если 1 активен только в момент ошибки
        .WR_SYNC    (WR_SYNC),          // количество тактов на синхронизацию предпочтительно 2 для высоких частот 3 для write
        .RD_SYNC    (RD_SYNC),          // количество тактов на синхронизацию предпочтительно 2 для высоких частот 3 для read
        .RST_MODE   (RST_MODE)          // вариант работы сброса 0 асинхронный сброс, 1 синхронный сброс 
    )
    ew_fifo_s2_sf_inst
    (
        .clk_push       (wr_clk_gen.clk),
        .clk_pop        (rd_clk_gen.clk),
        .rst_n          (wr_clk_gen.rst_n),
        .push_req_n     (fifo_if.push_req_n),
        .pop_req_n      (fifo_if.pop_req_n),
        .data_in        (fifo_if.data_in),
        .push_empty     (fifo_if.push_empty),
        .push_ae        (fifo_if.push_ae),
        .push_hf        (fifo_if.push_hf),
        .push_af        (fifo_if.push_af),
        .push_full      (fifo_if.push_full),
        .push_error     (fifo_if.push_error),
        .pop_empty      (fifo_if.pop_empty),
        .pop_ae         (fifo_if.pop_ae),
        .pop_hf         (fifo_if.pop_hf),
        .pop_af         (fifo_if.pop_af),
        .pop_full       (fifo_if.pop_full),
        .pop_error      (fifo_if.pop_error),
        .data_out       (fifo_if.data_out)
    );

    DW_fifo_s2_sf
    #(
        .width          (DATA_WIDTH),
        .depth          (RAM_DEPTH),
        .push_ae_lvl    (WR_AE_LVL),
        .push_af_lvl    (WR_AF_LVL),
        .pop_ae_lvl     (RD_AE_LVL),
        .pop_af_lvl     (RD_AF_LVL),
        .err_mode       (ERR_MODE),
        .push_sync      (WR_SYNC),
        .pop_sync       (RD_SYNC),
        .rst_mode       (RST_MODE)
    )
    DW_fifo_s2_sf_inst
    (
        .clk_push           (wr_clk_gen.clk)
        ,.clk_pop           (rd_clk_gen.clk)
        ,.rst_n             (wr_clk_gen.rst_n)
        ,.push_req_n        (fifo_if.push_req_n)
        ,.pop_req_n         (fifo_if.pop_req_n)
        ,.data_in           (fifo_if.data_in)
        ,.push_empty        ()
        ,.push_ae           ()
        ,.push_hf           ()
        ,.push_af           ()
        ,.push_full         ()
        ,.push_error        ()
        ,.pop_empty         ()
        ,.pop_ae            ()
        ,.pop_hf            ()
        ,.pop_af            ()
        ,.pop_full          ()
        ,.pop_error         ()
        ,.data_out          ()
    );

    initial begin
    end

    // always begin
    // end
    //---------------------------------------------------------------------------//
    // Main test process                                                         //
    //---------------------------------------------------------------------------//
    bit stop_at_the_end = 0; 
    initial begin : main
        uvm_root    root;
    //-------------------------------------------------------------------//
    // DUT initialization                                                //
    //-------------------------------------------------------------------//
        root = uvm_root::get();
        uvm_config_db #(virtual ifclk   #(  .CLK_MHZ (WR_CLK_MHZ)  )   )   ::set( root, "*", "wr_clk_gen",     wr_clk_gen     );
        uvm_config_db #(virtual ifclk   #(  .CLK_MHZ (RD_CLK_MHZ)  )   )   ::set( root, "*", "rd_clk_gen",     rd_clk_gen     );
        uvm_config_db #(virtual iffifo  #(  .DATA_WIDTH (DATA_WIDTH)   )    )   ::set( root, "*", "fifo_if",     fifo_if     );
    //-------------------------------------------------------------------//
    // Retrieve runtime configuration                                    //
    //-------------------------------------------------------------------//
        if ($value$plusargs ("stop_at_the_end=%b", stop_at_the_end)) begin
           `uvm_info("DISP", $psprintf("stop_at_the_end=%b IS SPECIFIED", stop_at_the_end), UVM_LOW)
        end
    //-------------------------------------------------------------------//
    // Configure testbench                                               //
    //-------------------------------------------------------------------//
        // set proper time scale
        uvm_config_db #(real) ::set(root, "*", "time_scale", 1ns);
        // disable $finish
        root.finish_on_completion = 0;
    //-------------------------------------------------------------------//
    // Run test                                                          //
    //-------------------------------------------------------------------//
        //tb::create_log();
        run_test(`UVM_TESTNAME);
        $finish;
    end : main
    
endmodule

`endif