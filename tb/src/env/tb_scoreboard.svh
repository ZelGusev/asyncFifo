/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Класс верхнего уровня тестового окружения (Scoreboard).
-—                     Содержит объявление и соединение используемых верификационных компонентов.
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/

`ifndef _GUARD_SCOREBOARD_
    `define _GUARD_SCOREBOARD_

    import parameter_pkg::*;
    import fifo_s2_pkg::*;

class Fifo_scoreboard extends uvm_scoreboard;

    // UVM Factory registration macros
    `uvm_component_utils(Fifo_scoreboard)
    // Declaring TLM analysis port
    uvm_analysis_export #(Fifo_seq_item)     sb_fifo_wr_export;
    uvm_analysis_export #(Fifo_seq_item)     sb_fifo_rd_export;
    
    // fifo
    uvm_tlm_analysis_fifo #(Fifo_seq_item)   fifo_wr_fifo;
    uvm_tlm_analysis_fifo #(Fifo_seq_item)   fifo_rd_fifo;
    
    // item
    Fifo_seq_item        rx_tr;
    Fifo_seq_item        tx_tr;

    //----------------------------------------------------------------------//
    // Create                                                               //
    //----------------------------------------------------------------------//
    function new (string name, uvm_component parent);
        super.new(name, parent);
        rx_tr      = new("rx_tr");
        tx_tr      = new("tx_tr");
    endfunction:new 

    //----------------------------------------------------------------------//
    // Build Phase                                                          //
    //----------------------------------------------------------------------//
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        //creating port
        sb_fifo_wr_export    = new("sb_fifo_wr_export", this);
        sb_fifo_rd_export    = new("sb_fifo_rd_export", this);
        //FIFO
        fifo_wr_fifo         = new("fifo_wr_fifo",     this);
        fifo_rd_fifo         = new("fifo_rd_fifo",     this);
    endfunction: build_phase

    //----------------------------------------------------------------------//
    // Coonect Phase                                                        //
    //----------------------------------------------------------------------//
    function void connect_phase(uvm_phase phase);
    sb_fifo_wr_export.connect      (fifo_wr_fifo.analysis_export);
    sb_fifo_rd_export.connect      (fifo_rd_fifo.analysis_export);
	endfunction: connect_phase

    //----------------------------------------------------------------------//
    // Run Phase                                                            //
    //----------------------------------------------------------------------//
    localparam WR_PER       = 1_000_000_000/(WR_CLK_MHZ * 1_000_000);  // перевод в ns период одного колебания
    localparam RD_PER       = 1_000_000_000/(RD_CLK_MHZ * 1_000_000);  // перевод в ns период одного колебания
    localparam WR_DEL       = (WR_SYNC == 0)? 1 : WR_PER*WR_SYNC;
    localparam RD_DEL       = (RD_SYNC == 0)? 1 : RD_PER*RD_SYNC;
    localparam C_RD_SYNC = (RD_SYNC == 0)? 2 : RD_SYNC + 1;
    localparam C_WR_SYNC = (WR_SYNC == 0)? 2 : WR_SYNC + 1;

    logic   [DATA_WIDTH - 1 : 0]    mem [RAM_DEPTH];
    bit     [DATA_WIDTH - 1 : 0]    mem_out;
    integer wr_addr_shift   [C_RD_SYNC];
    integer rd_addr_shift   [C_WR_SYNC];
    integer                     addr_wr = 0;
    integer                     addr_rd = 0;

    integer                     addr_wr_d = 0;
    integer                     addr_rd_d = 0;

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
    // utility
    bit                         pop_err_flag;
    integer timestamp;
    typedef int ar_da [1024];
    ar_da ar_nodes [string];
    integer sum     = 0;
    integer p_em    = 0;
    integer p_ae    = 0;
    integer p_hf    = 0;
    integer p_af    = 0;
    integer p_fl    = 0;
    integer p_er    = 0;
    integer pp_em   = 0;
    integer pp_ae   = 0;
    integer pp_hf   = 0;
    integer pp_af   = 0;
    integer pp_fl   = 0;
    integer pp_er   = 0;
    task run_phase(uvm_phase phase);
        fork
            begin
                //uvm_report_info("INFO", $sformatf("ADDR_WIDTH: %0d", ADDR_WIDTH), UVM_LOW);
                addr_wr = 0;
                addr_rd = 0;
                push_empty  = 1'b1;
                push_ae     = 1'b1;
                push_hf     = 1'b0;
                push_af     = 1'b0;
                push_full   = 1'b0;
                push_error  = 1'b0;
                pop_empty   = 1'b1;
                pop_ae      = 1'b1;
                pop_hf      = 1'b0;
                pop_af      = 1'b0;
                pop_full    = 1'b0;
                pop_error   = 1'b0;
                pop_err_flag= 1'b0;
                foreach(wr_addr_shift[i])
                    wr_addr_shift[i] = 0;
                foreach(rd_addr_shift[i])
                    rd_addr_shift[i] = 0;
                if (RST_MODE[1] == 0)
                    foreach(mem[i])
                        mem[i] = {DATA_WIDTH{1'b0}};
            end
            forever begin
                fifo_wr_fifo.get(rx_tr);
                if (~rx_tr.rst_n)
                    begin
                        addr_wr     = 0;
                        addr_wr_d   = 0;
                        push_error  = 1'b0;
                        push_empty  = 1'b1;
                        push_ae     = 1'b1;
                        push_hf     = 1'b0;
                        push_af     = 1'b0;
                        push_full   = 1'b0;
                        foreach(rd_addr_shift[i])
                            rd_addr_shift[i] = 0;
                        if (RST_MODE[1] == 0)
                            foreach(mem[i])
                                mem[i] = {DATA_WIDTH{1'b0}};
                        wr_move();
                    end
                else
                    begin
                        // $display("Ommm Ommm Cookies!!! %t", $time);
                        // $display("//------------------------------------------//");
                        // $display("::    addr_wr     = %1h   vs %1h  =  addr_rd_d       %t", addr_wr,   addr_rd_d               , $time);
                        // $display("//------------------------------------------//");
                        if (rx_tr.clk)
                            begin
                                // $display("//-------------------------Storm is comming!!! ALARM!!!---------------------------// %t", $time);
                                // $display(" :: Write Active Action push_req_n = %d", rx_tr.pop_req_n);
                                // $display(" ::   push_empty   = %d  vs  %d tets push_empty ",    rx_tr.push_empty,       push_error);
                                // $display(" ::   push_ae      = %d  vs  %d tets push_ae ",       rx_tr.push_ae,          push_empty);
                                // $display(" ::   push_hf      = %d  vs  %d tets push_hf ",       rx_tr.push_hf,          push_ae);
                                // $display(" ::   push_af      = %d  vs  %d tets push_af ",       rx_tr.push_af,          push_hf);
                                // $display(" ::   push_full    = %d  vs  %d tets push_full ",     rx_tr.push_full,        push_af);
                                // $display(" ::   push_error   = %d  vs  %d tets push_error ",    rx_tr.push_error,       push_full);
                                // $display("//--------------------------------------------------------------------------------//");
                                shift_rd();
                                wr_check();
                                if (~rx_tr.push_req_n)
                                    wr_add();
                                wr_move();
                            end
                        else
                            begin
                                wr_check();
                            end
                    end
            end
            forever begin
                fifo_rd_fifo.get(tx_tr);
                if (~tx_tr.rst_n)
                    begin
                        addr_rd     = 0;
                        addr_rd_d   = 0;
                        pop_error   = 1'b0;
                        pop_err_flag= 1'b0;
                        pop_empty   = 1'b1;
                        pop_ae      = 1'b1;
                        pop_hf      = 1'b0;
                        pop_af      = 1'b0;
                        pop_full    = 1'b0;
                        foreach(wr_addr_shift[i])
                            wr_addr_shift[i] = 0;
                        if (RST_MODE[1] == 0)
                            foreach(mem[i])
                                mem[i] = {DATA_WIDTH{1'b0}};
                        rd_move();
                        //$display(" IM IN RESET STATE!!!! %t",$time);
                    end
                else
                    begin
                        
                        // $display(" Bring It Back!!!!    %t", $time);
                        // $display("//------------------------------------------//");
                        // $display("::    addr_rd      = %1h   vs %1h       %t", addr_rd,     addr_wr_d                 , $time);
                        // $display("//------------------------------------------//");
                        // $display("::%d before   pop_empty = %d    addr_rd = %3d    addr_wr_d = %3d          %t", tx_tr.clk, pop_empty, addr_rd, addr_wr_d, $time);
                        if (tx_tr.clk)
                            begin
                                rd_check();
                                if (~tx_tr.pop_req_n)
                                    rd_add();
                                pop_error = pop_err_flag;
                                shift_wr();
                                rd_move();
                            end
                        else
                            begin
                                rd_check();
                            end
                        // $display("::%d after   pop_empty = %3d    addr_rd = %3d    addr_wr_d = %3d          %t", tx_tr.clk, pop_empty, addr_rd, addr_wr_d, $time);
                    end
            end
            /////////////////////////////////////////////////////////////////////////////////////<------------
        join
    endtask : run_phase

    virtual function void rd_add();
        begin
            mem_out = mem[addr_rd[ADDR_WIDTH - 1 : 0]];
            if (mem_out != tx_tr.data_out)
                begin
                    sum = sum + 1;
                    $display("::    DataFromMem = %h   vs %h   Error       %t ns", mem_out,  tx_tr.data_out      , $time);
                end
            if (addr_wr_d > addr_rd)
                begin
                    addr_rd = addr_rd + 1;
                    if (ERR_MODE == 1)
                        begin
                            pop_error   = 1'b0;
                            pop_err_flag= 1'b0;
                        end
                end
            else
                begin
                    pop_err_flag   = 1'b1;
                    //pop_error   = 1'b1;
                end
        end
    endfunction : rd_add

    virtual function void rd_check();
        begin
            if (pop_empty != tx_tr.pop_empty)
                begin
                    sum = sum + 1;
                    $display("::    pop_empty   = %h   vs %h   Error       %t ns", pop_empty,  tx_tr.pop_empty      , $time);
                end
            if (pop_ae != tx_tr.pop_ae)
                begin
                    sum = sum + 1;
                    $display("::    pop_ae      = %h   vs %h   Error       %t ns", pop_ae,     tx_tr.pop_ae         , $time);
                end
            if (pop_hf != tx_tr.pop_hf)
                begin
                    sum = sum + 1;
                    $display("::    pop_hf      = %h   vs %h   Error       %t ns", pop_hf,     tx_tr.pop_hf         , $time);
                end
            if (pop_af != tx_tr.pop_af)
                begin
                    sum = sum + 1;
                    $display("::    pop_af      = %h   vs %h   Error       %t ns", pop_af,     tx_tr.pop_af         , $time);
                end
            if (pop_full != tx_tr.pop_full)
                begin
                    sum = sum + 1;
                    $display("::    pop_full     = %h   vs %h   Error       %t ns", pop_full,   tx_tr.pop_full       , $time);
                end
            if (pop_error != tx_tr.pop_error)
                begin
                    sum = sum + 1;
                    $display("::    pop_error   = %h   vs %h   Error       %t ns", pop_error,  tx_tr.pop_error      , $time);
                end
        end
    endfunction : rd_check

    virtual function void wr_add();
        begin
            if ( (addr_wr - addr_rd_d) < RAM_DEPTH )
                begin
                    mem[addr_wr[ADDR_WIDTH - 1 : 0]] = rx_tr.data_in;
                    addr_wr = addr_wr + 1;
                    if (ERR_MODE == 1)
                        push_error  = 1'b0;
                end
            else
                begin
                    addr_wr     = addr_wr;
                    push_error  = 1'b1;
                end
        end
    endfunction : wr_add

    virtual function void wr_check();
        begin
            if (push_empty != rx_tr.push_empty)
                begin
                    sum = sum + 1;
                    $display("::    push_empty  = %h   vs %h   Error       %t ns", push_empty,  rx_tr.push_empty      , $time);
                end
            if (push_ae != rx_tr.push_ae)
                begin
                    sum = sum + 1;
                    $display("::    push_ae     = %h   vs %h   Error       %t ns", push_ae,     rx_tr.push_ae         , $time);
                end
            if (push_hf != rx_tr.push_hf)
                begin
                    sum = sum + 1;
                    $display("::    push_hf     = %h   vs %h   Error       %t ns", push_hf,     rx_tr.push_hf         , $time);
                end
            if (push_af != rx_tr.push_af)
                begin
                    sum = sum + 1;
                    $display("::    push_af     = %h   vs %h   Error       %t ns", push_af,     rx_tr.push_af         , $time);
                end
            if (push_full != rx_tr.push_full)
                begin
                    sum = sum + 1;
                    $display("::    push_full   = %h   vs %h   Error       %t ns", push_full,   rx_tr.push_full       , $time);
                end
            if (push_error != rx_tr.push_error)
                begin
                    sum = sum + 1;
                    $display("::    push_error  = %h   vs %h   Error       %t ns", push_error,  rx_tr.push_error      , $time);
                end
        end
    endfunction : wr_check

    virtual function void wr_move();
        begin
            // убрал логику с переполнением счетчика, теперь сброс счетчика происходит только по ресету, который встроен в систему тестов
            //if (((addr_wr >= addr_rd_d)&&((addr_wr - addr_rd_d) == RAM_DEPTH)) || ((addr_wr < addr_rd_d)&&((RAM_DEPTH + addr_wr - addr_rd_d)) == RAM_DEPTH ))
            if ((addr_wr - addr_rd_d) == RAM_DEPTH)
                push_full = 1'b1;
            else
                push_full = 1'b0;

            if (((addr_wr >= addr_rd_d)&&((addr_wr - addr_rd_d) <= WR_AE_LVL)) || ((addr_wr < addr_rd_d)&&((RAM_DEPTH + addr_wr - addr_rd_d) <= WR_AE_LVL )))
                push_ae = 1'b1;
            else
                push_ae = 1'b0;

            if (((addr_wr >= addr_rd_d)&&((addr_wr - addr_rd_d) >= RAM_DEPTH/2)) || ((addr_wr < addr_rd_d)&&((RAM_DEPTH + addr_wr - addr_rd_d) >= RAM_DEPTH/2 )))
                push_hf = 1'b1;
            else
                push_hf = 1'b0;

            if (((addr_wr >= addr_rd_d)&&((addr_wr - addr_rd_d) >= RAM_DEPTH - WR_AF_LVL)) || ((addr_wr < addr_rd_d)&&(RAM_DEPTH + addr_wr - addr_rd_d) >= RAM_DEPTH - WR_AF_LVL ))
                push_af = 1'b1;
            else
                push_af = 1'b0;

            if (addr_wr == addr_rd_d)
                push_empty  = 1'b1;
            else
                push_empty  = 1'b0;
        end
    endfunction

    virtual function void rd_move();
        begin
            //if (((addr_wr_d >= addr_rd)&&((addr_wr_d - addr_rd) == RAM_DEPTH)) || ((addr_wr_d < addr_rd)&&( (RAM_DEPTH + addr_wr_d - addr_rd) == RAM_DEPTH )))
            //$display("::::    addr_rd  = %d   addr_wr_d =  %d         %t ns", addr_rd,  addr_wr_d      , $time);
            if ((addr_wr_d - addr_rd) == RAM_DEPTH)
                pop_full = 1'b1;
            else
                pop_full = 1'b0;

            if (((addr_wr_d >= addr_rd)&&((addr_wr_d - addr_rd) <= RD_AE_LVL)) || ((addr_wr_d < addr_rd)&&( (RAM_DEPTH + addr_wr_d - addr_rd) <= RD_AE_LVL )))
                pop_ae = 1'b1;
            else
                pop_ae = 1'b0;

            if (((addr_wr_d >= addr_rd)&&((addr_wr_d - addr_rd) >= RAM_DEPTH/2)) || ((addr_wr_d < addr_rd)&&( (RAM_DEPTH + addr_wr_d - addr_rd) >= RAM_DEPTH/2 )))
                pop_hf = 1'b1;
            else
                pop_hf = 1'b0;

            if (((addr_wr_d >= addr_rd)&&((addr_wr_d - addr_rd) >= RAM_DEPTH - RD_AF_LVL)) || ((addr_wr_d < addr_rd)&&( (RAM_DEPTH + addr_wr_d - addr_rd) >= RAM_DEPTH - RD_AF_LVL )))
                pop_af = 1'b1;
            else
                pop_af = 1'b0;

            if (addr_wr_d == addr_rd)
                pop_empty  = 1'b1;
            else
                pop_empty  = 1'b0;
        end
    endfunction
    
    virtual function void shift_rd();
        begin
            // $display("//--------------- Welcome To Ring -------------------// %t", $time);
            // $display(":: New Fighter addr_rd = %d", addr_rd);
            // $display(":: All Fighters rd_addr_shift = %p", rd_addr_shift);
            // $display("//--------------- NOW ROUND -------------------------//");
            for(int i = 0; i < C_WR_SYNC - 1    ; i++)
                begin
                    rd_addr_shift[i] = rd_addr_shift[i+1];
                end
            rd_addr_shift[C_WR_SYNC - 1] = addr_rd;
            addr_rd_d   = rd_addr_shift[0];
        end
    endfunction : shift_rd

    virtual function void shift_wr();
        begin
            // $display("//--------------- Welcome To Ring -------------------// %t", $time);
            // $display(":: New Fighter addr_wr = %d", addr_wr);
            // $display(":: All Fighters rd_addr_shift = %p", wr_addr_shift);
            // $display("//--------------- NOW ROUND -------------------------//");
            for(int i = 0; i < C_RD_SYNC - 1; i++)
                begin
                    wr_addr_shift[i] = wr_addr_shift[i+1];
                end
            wr_addr_shift[C_RD_SYNC - 1] = addr_wr;
            addr_wr_d   = wr_addr_shift[0];
            // $display(":: All Fighters rd_addr_shift = %p", wr_addr_shift);
        end
    endfunction : shift_wr



endclass : Fifo_scoreboard

`endif