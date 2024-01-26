    
    always @(clk0, clk1)
        begin
            if (assert_en)
                begin
                    push_empty_chk:        assert (model_fifo_if.push_empty          == fifo_if.push_empty);
                    push_ae_chk:           assert (model_fifo_if.push_ae             == fifo_if.push_ae);
                    push_hf_chk:           assert (model_fifo_if.push_hf             == fifo_if.push_hf);
                    push_af_chk:           assert (model_fifo_if.push_af             == fifo_if.push_af);
                    push_full_chk:         assert (model_fifo_if.push_full           == fifo_if.push_full);
                    push_error_chk:        assert (model_fifo_if.push_error          == fifo_if.push_error);
                    pop_empty_chk:         assert (model_fifo_if.pop_empty           == fifo_if.pop_empty);
                    pop_ae_chk:            assert (model_fifo_if.pop_ae              == fifo_if.pop_ae);
                    pop_hf_chk:            assert (model_fifo_if.pop_hf              == fifo_if.pop_hf);
                    pop_af_chk:            assert (model_fifo_if.pop_af              == fifo_if.pop_af);
                    pop_full_chk:          assert (model_fifo_if.pop_full            == fifo_if.pop_full);
                    pop_error_chk:         assert (model_fifo_if.pop_error           == fifo_if.pop_error);
                    data_out_chk:          assert (model_fifo_if.data_out            == fifo_if.data_out);
                end
        end

    task read_fifo();
        input integer num_word;
        begin
            // $display(" READ FROM MEM %d", num_word);
            if (fifo_if.rst_n)
                begin
                    for (int i = 0; i < num_word; i++)
                        begin
                            @(posedge fifo_if.clk_pop);
                            fifo_if.pop_req_n  = 1'b0;
                        end
                end
            @(posedge fifo_if.clk_pop);
            fifo_if.pop_req_n  = 1'b1;
        end
    endtask

    task write_fifo ();
        input integer num_word;
        input bit [DATA_WIDTH - 1 : 0]    data [STREAM_DEPTH];
        begin
            // $display(" WRITE TO MEM ");
            // $display(" RST = %d ", fifo_if.rst_n);
            if (fifo_if.rst_n)
                begin
                    for (int i = 0; i < num_word; i++)
                        begin
                            @(posedge fifo_if.clk_push);
                            fifo_if.data_in     = data[i];
                            fifo_if.push_req_n  = 1'b0;
                            //$display(" DATA = %h, num_word = %d", fifo_seq.data[i], i);
                        end
                end
            @(posedge fifo_if.clk_push);
            fifo_if.push_req_n  = 1'b1;
        end
    endtask : write_fifo

    task rand_rst();
        begin
            rst_n = 1'b0;
            #($urandom_range(10,40));
            rst_n = 1'b1;
        end
    endtask

    task rand_data();
        begin
            num_word = $urandom_range(1,15);
            for(int i = 0; i < RAM_DEPTH*4; i++)
                begin
                    data[i] = $urandom;
                end
        end
    endtask

    function void rst_all();
        begin
            fifo_if.push_req_n      = '1;
            fifo_if.pop_req_n       = '1;
            fifo_if.data_in         = '0;
        end
    endfunction : rst_all
    
    function void rst_dwn();
        begin
            rst_n      = '0;
        end
    endfunction : rst_dwn
    
    function void rst_up();
        begin
            rst_n      = '1;
        end
    endfunction : rst_up

    task random_move();
        begin
            rand_data();
            randcase
                3: read_fifo(num_word);
                3: write_fifo (num_word, data);
                1: rand_rst();
                0: rst_all();
                0: rst_dwn();
                0: rst_up();
            endcase
        end
    endtask

    task run_test();
        integer rand_num;
        begin
            rand_num = $urandom_range(20,50);
            rst_all();
            rand_rst();
            for (int i = 0; i < rand_num; i++)
                begin
                    random_move();
                end
        end
    endtask : run_test