`timescale 1ps/1ps
module tb_rtl_task2();

    // DUT input and output signals:
    logic clk, rst_n;
    logic [3:0] KEY;
    logic [9:0] SW, LEDR;
    logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

    // Debugging signals:
    logic err, totalerr, err_mem;
    logic [3:0] s, t; // s = number of states passed tests, t = number of transitions passed tests
    integer mismatch_count, i;
    logic [7:0] mem_value;

    // expected output
    logic [7:0] expected_S [0:255] = '{
        8'hb4, 8'h04, 8'h2b, 8'he5, 8'h49, 8'h0a, 8'h90, 8'h9a, 8'he4, 8'h17, 8'hf4, 8'h10, 8'h3a, 8'h36, 8'h13, 8'h77,
        8'h11, 8'hc4, 8'hbc, 8'h38, 8'h4f, 8'h6d, 8'h98, 8'h06, 8'h6e, 8'h3d, 8'h2c, 8'hae, 8'hcd, 8'h26, 8'h40, 8'ha2,
        8'hc2, 8'hda, 8'h67, 8'h68, 8'h5d, 8'h3e, 8'h02, 8'h73, 8'h03, 8'haa, 8'h94, 8'h69, 8'h6a, 8'h97, 8'h6f, 8'h33,
        8'h63, 8'h5b, 8'h8a, 8'h58, 8'hd9, 8'h61, 8'hf5, 8'h46, 8'h96, 8'h55, 8'h7d, 8'h53, 8'h5f, 8'hab, 8'h07, 8'h9c,
        8'ha7, 8'h72, 8'h31, 8'ha9, 8'hc6, 8'h3f, 8'hf9, 8'h91, 8'hf2, 8'hf6, 8'h7c, 8'hc7, 8'hb3, 8'h1d, 8'h20, 8'h88,
        8'ha0, 8'hba, 8'h0c, 8'h85, 8'he1, 8'hcf, 8'hcb, 8'h51, 8'hc0, 8'h2e, 8'hef, 8'h80, 8'h76, 8'hb2, 8'hd6, 8'h71,
        8'h24, 8'had, 8'h6b, 8'hdb, 8'hff, 8'hfe, 8'hed, 8'h84, 8'h4e, 8'h8c, 8'hbb, 8'hd3, 8'ha5, 8'h2f, 8'hbe, 8'hc8,
        8'h0e, 8'h8f, 8'hd1, 8'ha6, 8'h86, 8'he3, 8'h62, 8'hb0, 8'h87, 8'hec, 8'hb9, 8'h78, 8'h81, 8'he0, 8'h4d, 8'h5a,
        8'h7a, 8'h79, 8'h14, 8'h29, 8'h56, 8'he8, 8'h4a, 8'h8e, 8'h18, 8'hc5, 8'hca, 8'hb7, 8'h25, 8'hde, 8'h99, 8'hc3,
        8'h2a, 8'h65, 8'h30, 8'h1a, 8'hea, 8'hfb, 8'ha1, 8'h89, 8'h35, 8'ha4, 8'h09, 8'ha3, 8'hc1, 8'hd8, 8'h2d, 8'hb8,
        8'h60, 8'h47, 8'h39, 8'hbd, 8'h1f, 8'h05, 8'h5e, 8'h43, 8'hb1, 8'hdd, 8'he9, 8'h1c, 8'haf, 8'h9b, 8'hfa, 8'h01,
        8'hf7, 8'h08, 8'h75, 8'hb6, 8'h82, 8'hce, 8'h42, 8'he2, 8'hcc, 8'h9e, 8'heb, 8'h27, 8'h22, 8'hdf, 8'hbf, 8'hfc,
        8'h0d, 8'hd0, 8'h95, 8'h23, 8'hd2, 8'ha8, 8'h7e, 8'h74, 8'h4c, 8'hd7, 8'h12, 8'h7f, 8'hfd, 8'h83, 8'h1e, 8'h28,
        8'h64, 8'h54, 8'h3c, 8'h21, 8'hdc, 8'hf3, 8'h93, 8'h59, 8'h8b, 8'h7b, 8'h00, 8'h48, 8'he7, 8'h6c, 8'hd5, 8'hc9,
        8'h70, 8'h9f, 8'hac, 8'h41, 8'h0b, 8'hf0, 8'h19, 8'hb5, 8'h8d, 8'h16, 8'hd4, 8'hf1, 8'h92, 8'h9d, 8'h66, 8'h44,
        8'h4b, 8'h15, 8'h45, 8'hf8, 8'h0f, 8'h57, 8'h34, 8'h32, 8'h50, 8'h52, 8'hee, 8'h3b, 8'h5c, 8'h37, 8'he6, 8'h1b
    }; 
   
    // Instantiate DUT: 
    task2 DUT(.CLOCK_50(clk), .KEY(KEY), .SW(SW),
             .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2),
             .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5),
             .LEDR(LEDR));
   
       // Declare state constants: 
    localparam logic [2:0]
        IDLE = 3'b000,
        STARTI = 3'b001,
        INIT = 3'b010,
        //WAIT_I = 3'b011,
        STARTK = 3'b100,
        KSA = 3'b101,
        //WAIT_K = 3'b110,  
        DONE = 3'b111;

    // Checking current state:
    task checkstate;
    input [2:0] expected_state;
    begin
        assert(expected_state == DUT.present_state)
            else begin
                err = 1'b1;
                $display("Error: incorrect state - Expected: %b, Actual: %b", expected_state, DUT.present_state);
            end
    end
    endtask

    task checksig;  
    input expected_i_en, expected_k_en;
    begin
        assert(expected_i_en == DUT.i_en)
            else begin
                err = 1'b1;
                $display("Error: incorrect i_en signal - Expected: %d, Actual: %d", expected_i_en, DUT.i_en);
            end
        assert(expected_k_en == DUT.k_en)
            else begin
                err = 1'b1;
                $display("Error: incorrect k_en signal - Expected: %d, Actual: %d", expected_k_en, DUT.k_en);
            end
    end 
    endtask

    // Generate clock signal:
    initial clk = 1'b0;
    always  #5 clk = ~clk;

    always @(posedge DUT.i_rdy) begin
    $display("TIME %t: i_rdy went HIGH | init_state=%d wrdata=%d addr=%d", 
             $time, DUT.i.present_state, DUT.i.wrdata, DUT.i.addr);
    end

    always @(posedge DUT.k_rdy) begin
        $display("TIME %t: k_rdy went HIGH | ksa_state=%d count_i=%d", 
                $time, DUT.k.present_state, DUT.k.count_i);
    end
 /*
    always @(posedge clk) begin
        if (DUT.present_state == STARTK)
        $display("T=%0t STARTK: k_en=%b k_rdy=%b", $time, DUT.k_en, DUT.k_rdy);
        if (DUT.present_state == IDLE)
        $display("T=%0t IDLE: k_en=%b k_rdy=%b", $time, DUT.k_en, DUT.k_rdy);
         if (DUT.present_state == STARTI)
        $display("T=%0t STARTI: k_en=%b k_rdy=%b", $time, DUT.k_en, DUT.k_rdy);
         if (DUT.present_state == INIT)
        $display("T=%0t INIT: k_en=%b k_rdy=%b", $time, DUT.k_en, DUT.k_rdy);
         if (DUT.present_state == WAIT_I)
        $display("T=%0t WAIT_I: k_en=%b k_rdy=%b", $time, DUT.k_en, DUT.k_rdy);
         if (DUT.present_state == KSA)
        $display("T=%0t KSA: k_en=%b k_rdy=%b", $time, DUT.k_en, DUT.k_rdy);
         if (DUT.present_state == WAIT_K)
        $display("T=%0t WAIT_K: k_en=%b k_rdy=%b", $time, DUT.k_en, DUT.k_rdy);
        end 
*/
    
 
    // Start tests: 
    initial begin
        // Initialize debugging signals:
        err = 1'b0;
        err_mem = 1'b0;
        totalerr = 1'b0;
        mismatch_count = 0;
        i = 0;
        s = 4'b0;
        t = 4'b0;

        // Initialize inputs:
        SW[9:0] = 10'b1100111100; // set key
        KEY[3] = 1'b1; #5; // active-low reset

        // TEST 1: Check reset and IDLE State
        KEY[3] = 1'b0; #5; // assert reset
        @(posedge clk);
        checkstate(IDLE);
        checksig(1'b0, 1'b0); 
        if (~err) begin
            $display("TEST 1 PASSED");
            s = s + 4'd1;
            t = t + 4'd1;
        end else begin
            $display("TEST 1 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end
        // $display("K_rdy output: %d, I = %d, state = %d", DUT.k_rdy, DUT.k.count_i, DUT.k.present_state);

        // TEST 2: Check STARTI State and IDLE -> STARTI
        KEY[3] = 1'b1; // de-assert reset
        repeat(2) @(posedge clk);
        checkstate(STARTI);
        checksig(1'b1, 1'b0);
        if (~err) begin
            $display("TEST 2 PASSED");
            s = s + 4'd1;
            t = t + 4'd1;
        end else begin
            $display("TEST 2 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end
         //$display("K_rdy output: %d, I = %d, state = %d", DUT.k_rdy, DUT.k.count_i, DUT.k.present_state);

        // TEST 3: Check INIT State and STARTI -> INIT
        while (DUT.i_rdy != 1'b0) @(posedge clk);   
        @(posedge clk);
        checkstate(INIT);
        checksig(1'b0, 1'b0);
        if (~err) begin
            $display("TEST 3 PASSED");
            s = s + 4'd1;
            t = t + 4'd1;
        end else begin
            $display("TEST 3 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end
        //$display("K_rdy output: %d, I = %d, state = %d", DUT.k_rdy, DUT.k.count_i, DUT.k.present_state);

        // TEST 4: Check STARTK State and INIT -> STARTK

        while (DUT.i_rdy != 1'b1) @(posedge clk); 
        @(posedge clk);  
        checkstate(STARTK);
        checksig(1'b0, 1'b1);
        if (~err) begin
            $display("TEST 4 PASSED");
            s = s + 4'd1;
            t = t + 4'd1; 
        end else begin
            $display("TEST 4 FAILED");
            err = 1'b0;
            totalerr = 1'b1; 
        end
        //$display("K_rdy output: %d, I = %d, state = %d", DUT.k_rdy, DUT.k.count_i, DUT.k.present_state);

        //$display("K_rdy output: %d, I = %d, state = %d", DUT.k_rdy, DUT.k.count_i, DUT.k.present_state);
    
/*
        $display("=== Checking init memory (before KSA) ===");
        // Memory check: mem[i] should equal i (0..255)
        for (i = 0; i < 256; i = i + 1) begin
        if (DUT.s.altsyncram_component.m_default.altsyncram_inst.mem_data[i] !== i[7:0]) begin
        $display("ERROR: mem[%0d] = %h expected %h",
                 i,
                 DUT.s.altsyncram_component.m_default.altsyncram_inst.mem_data[i],
                 i[7:0]);
        err_mem = 1'b1;
        end
        end 
        if (~err_mem)
        $display("Memory check PASSED: all 256(0 to 255) addresses initialized correctly.");
        else
        $display("Memory check FAILED: one or more addresses incorrect.");*/

        // TEST 5: Check KSA State and START_K -> KSA
        @(posedge clk);
        checkstate(KSA);
        checksig(1'b0, 1'b0);
        if (~err) begin
            $display("TEST 5 PASSED");
            s = s + 4'd1; 
            t = t + 4'd1;
        end else begin
            $display("TEST 5 FAILED"); 
            err = 1'b0;
            totalerr = 1'b1;
        end
/*
         $display("K_rdy output: %d, I = %d, state = %d", DUT.k_rdy, DUT.k.count_i, DUT.k.present_state);
        @(posedge clk);
         $display("K_rdy output: %d, I = %d, state = %d", DUT.k_rdy, DUT.k.count_i, DUT.k.present_state);
        @(posedge clk);
         $display("K_rdy output: %d, I = %d, state = %d", DUT.k_rdy, DUT.k.count_i, DUT.k.present_state);
       */   

        // TEST 6: Check WAIT_K State and KSA -> DONE
        while (DUT.k_rdy != 1'b1) @(posedge clk);
        @(posedge clk);
        checkstate(DONE);
        checksig(1'b0, 1'b0);
        if (~err) begin
            $display("TEST 6 PASSED");
            s = s + 4'd1;
            t = t + 4'd1; 
        end else begin
            $display("TEST 6 FAILED");
            err = 1'b0;  
            totalerr = 1'b1;
        end 

        // Memory check - wait a few cycles for any pending operations
        repeat(20) @(posedge clk); 
        
        $display("\n=== Checking Memory Contents ===");
        
        for (i = 0; i < 256; i = i + 1) begin
            mem_value = DUT.s.altsyncram_component.m_default.altsyncram_inst.mem_data[i];

            if (mem_value !== expected_S[i]) begin
                $display("Mismatch at S[%3d]: Expected %02h, Got %02h", i, expected_S[i], mem_value);
                mismatch_count = mismatch_count + 1;
                err_mem = 1'b1;
            end 
        end

        if (mismatch_count == 0) begin
            $display("Memory check PASSED - All values match expected results");
        end else begin
            $display("Memory check FAILED - %d mismatches found", mismatch_count);
            totalerr = 1'b1;
        end

        if (~err_mem)
        $display("Memory check PASSED."); 
        else
        $display("Memory check FAILED.");

        if (~totalerr) $display("ALL TESTS PASSED: %d / 8 States Passed, %d / 8 Transitions Passed", s, t);
        else $display("TESTS FAILED: %d / 8 States Passed, %d / 8 Transitions Passed", s, t);
    end
        
endmodule: tb_rtl_task2