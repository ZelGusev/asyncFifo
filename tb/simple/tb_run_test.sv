    task random_move();
            rand_data();
            randcase
                3: read_fifo(num_word);
                3: write_fifo (num_word, data);
                1: rand_rst();
                0: rst_all();
                0: rst_dwn();
                0: rst_up();
            endcase
    endtask


    task run_test();
        rst_all();
        rand_rst();
        for (int i = 0; i < $urandom_range(20,50); i++)
            random_move();
    endtask : run_test