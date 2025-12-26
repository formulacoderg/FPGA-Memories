`timescale 1ps/1ps

module tb_rtl_doublecrack();

    // DUT signals
    logic clk, rst_n, en, rdy, key_valid;  // Added 'rdy' declaration
    logic [23:0] key;
    logic [7:0] ct_addr, ct_rddata;

    // Memories - MISSING!
    logic [7:0] CT_mem [0:255];

    //debug signals
    logic err, totalerr;
    logic [15:0] s_count, t_count;

    integer iteration;
    
    localparam logic [3:0] 
        IDLE = 4'd0,
        STARTC = 4'd1,
        CRACK = 4'd2,
        RDLEN1 = 4'd3,
        RDLEN2 = 4'd4,
        RDP = 4'd5,
        WRP = 4'd6,
        INCR = 4'd7,
        LOOP = 4'd8;

    //DUT instantiation
    doublecrack DUT(.clk(clk), .rst_n(rst_n), .en(en), .rdy(rdy), 
                    .key(key), .key_valid(key_valid), 
                    .ct_addr(ct_addr), .ct_rddata(ct_rddata));


   
    assign ct_rddata = CT_mem[ct_addr];

    // CHECK TASKS
    
    task checkstate;
        input [3:0] expected_state;  
        begin
            if (expected_state !== DUT.present_state) begin
                err = 1'b1;
                $display("Error: incorrect state - Expected: %d, Actual: %d", expected_state, DUT.present_state);
            end
        end
    endtask

    task check_1bit_signals;
        input expected_en_1, expected_en_2, expected_pt_wren;
        begin
            if (DUT.en_1 !== expected_en_1) begin
                err = 1'b1;
                $display("Error: incorrect en_1 - Expected: %d, Actual: %d",expected_en_1, DUT.en_1);
            end
            if (DUT.en_2 !== expected_en_2) begin
                err = 1'b1;
                $display("Error: incorrect en_2 - Expected: %d, Actual: %d", expected_en_2,DUT.en_2);
            end
            if (DUT.pt_wren !== expected_pt_wren) begin
                err = 1'b1;
                $display("Error: incorrect pt_wren - Expected: %d, Actual: %d", expected_pt_wren, DUT.pt_wren);
            end
        end
    endtask

    task checkoutputsignals;
        input [7:0] expected_addr, expected_dc_addr1, expected_dc_addr2, expected_pt_wrdata;
        begin
            if (expected_addr !== DUT.addr) begin
                err = 1'b1;
                $display("Error: incorrect addr - Expected: %d, Actual: %d", expected_addr, DUT.addr);
            end
            if (expected_dc_addr1 !== DUT.dc_addr1) begin
                err = 1'b1;
                $display("Error: incorrect dc_addr1 - Expected: %d, Actual: %d", expected_dc_addr1, DUT.dc_addr1);
            end
            if (expected_dc_addr2 !== DUT.dc_addr2) begin
                err = 1'b1;
                $display("Error: incorrect dc_addr2 - Expected: %d, Actual: %d", expected_dc_addr2, DUT.dc_addr2);
            end
            if (expected_pt_wrdata !== DUT.pt_wrdata) begin
                err = 1'b1;
                $display("Error: incorrect pt_wrdata - Expected: %d, Actual: %d", expected_pt_wrdata, DUT.pt_wrdata);
            end
        end
    endtask

    // Clock generation
    initial clk = 1'b0;
    always #10 clk = ~clk;

    // MAIN TEST
    initial begin
        err = 1'b0;
        totalerr = 1'b0;
        s_count = 16'd0;
        t_count = 16'd0;

        // Initialize CT memory
        for (int n = 0; n < 256; n = n + 1) begin
            CT_mem[n] = 8'h00;
        end
        $readmemh("test2.memh", CT_mem);

        // Initialize inputs
        rst_n = 1'b1;
        en = 1'b0;

        // TEST 1: Reset and IDLE
        rst_n = 1'b0; #5;
        @(posedge clk); #5;
        checkstate(IDLE);

        check_1bit_signals(1'b0, 1'b0, 1'b0);  // Check your expected values!
        checkoutputsignals(8'd0, 8'd0, 8'd0, 8'd0);

        if (~err) begin
            $display("TEST 1 PASSED: Reset to IDLE");
            s_count = s_count + 16'd1;
            t_count = t_count + 16'd1;
        end else begin 
            $display("TEST 1 FAILED"); 
            totalerr = 1'b1; 
            err = 1'b0; 
        end

        rst_n = 1'b1; #5;

        // TEST 1: Start in IDLE
        @(posedge clk); #5;
        checkstate(IDLE);

        check_1bit_signals(1'b0, 1'b0, 1'b0);  // Check your expected values!
        checkoutputsignals(8'd0, 8'd0, 8'd0, 8'd0);

        if (~err) begin
            $display("TEST 2 PASSED: Stay in IDLE");
            s_count = s_count + 16'd1;
            t_count = t_count + 16'd1;
        end else begin 
            $display("TEST 2 FAILED"); 
            totalerr = 1'b1; 
            err = 1'b0; 
        end


        // TEST 3: STARTC
        en = 1'b1; #5; //enable set high
        @(posedge clk); #5;
        checkstate(STARTC);

        check_1bit_signals(1'b1, 1'b1, 1'b0);  // Check your expected values!
        checkoutputsignals(8'd0, 8'd0, 8'd0, 8'd0);

        if (~err) begin
            $display("TEST 3 PASSED - STARTC");
            s_count = s_count + 16'd1;
            t_count = t_count + 16'd1;
        end else begin 
            $display("TEST 3 FAILED - STARTC"); 
            totalerr = 1'b1; 
            err = 1'b0; 
        end

        // TEST 4: Wait for CRACK to start
        $display("Waiting for crack modules to start...");
        wait(~(DUT.rdy_1 && DUT.rdy_2));  // Wait until at least one is not ready
        @(posedge clk); #5;

        checkstate(CRACK);
        check_1bit_signals(1'b0, 1'b0, 1'b0);  // en signals should be low in CRACK
        checkoutputsignals(8'd0, 8'd0, 8'd0, 8'd0);

        if (~err) begin
            $display("TEST 4 PASSED - CRACK");
            s_count = s_count + 16'd1;
            t_count = t_count + 16'd1;
        end else begin 
            $display("TEST 4 FAILED - CRACK"); 
            totalerr = 1'b1; 
            err = 1'b0; 
        end

        // TEST 5 AND 6 -RDLEN's: Wait for one crack module to finish
        $display("Waiting for a crack module to finish...");
        wait(DUT.rdy_1 || DUT.rdy_2);  // Wait until at least one is ready
        @(posedge clk); #5;

        checkstate(RDLEN1);

        check_1bit_signals(1'b0, 1'b0, 1'b0);  // en signals should be low in CRACK
        checkoutputsignals(8'd0, 8'd0, 8'd0, 8'd0);

        if (~err) begin
            $display("TEST 5 PASSED - RDLEN1");
            s_count = s_count + 16'd1;
            t_count = t_count + 16'd1;
        end else begin 
            $display("TEST 5 FAILED - RDLEN2"); 
            totalerr = 1'b1; 
            err = 1'b0; 
        end

        @(posedge clk); #5;
        checkstate(RDLEN2);

        check_1bit_signals(1'b0, 1'b0, 1'b0);  // en signals should be low in CRACK
        checkoutputsignals(8'd0, 8'd0, 8'd0, 8'd0);

        if (~err) begin
            $display("TEST 6 PASSED - CRACK");
            s_count = s_count + 16'd1;
            t_count = t_count + 16'd1;
        end else begin 
            $display("TEST 6 FAILED - CRACK"); 
            totalerr = 1'b1; 
            err = 1'b0; 
        end

// TEST 7: RDP - Read plaintext from winning crack module
        @(posedge clk); #5;
        checkstate(RDP);

        check_1bit_signals(1'b0, 1'b0, 1'b0);  // All control signals should be low

        // Check common outputs
        if (DUT.addr !== DUT.incr_addr) begin
            err = 1'b1;
            $display("Error: incorrect addr - Expected: %d (incr_addr), Actual: %d", 
                    DUT.incr_addr, DUT.addr);
        end
        if (DUT.pt_wrdata !== 8'd0) begin
            err = 1'b1;
            $display("Error: incorrect pt_wrdata - Expected: 0, Actual: %d", DUT.pt_wrdata);
        end

        // Check dc_addr outputs based on which crack module won
        if (DUT.key_valid_1) begin
            // Crack module 1 found the key
            if (DUT.dc_addr1 !== DUT.incr_addr) begin
                err = 1'b1;
                $display("Error: incorrect dc_addr1 - Expected: %d (incr_addr), Actual: %d", 
                        DUT.incr_addr, DUT.dc_addr1);
            end
            if (DUT.dc_addr2 !== 8'd0) begin
                err = 1'b1;
                $display("Error: incorrect dc_addr2 - Expected: 0, Actual: %d", DUT.dc_addr2);
            end
            $display("Crack module 1 won with key: %h", DUT.key_1);
        end else if (DUT.key_valid_2) begin
            // Crack module 2 found the key
            if (DUT.dc_addr1 !== 8'd0) begin
                err = 1'b1;
                $display("Error: incorrect dc_addr1 - Expected: 0, Actual: %d", DUT.dc_addr1);
            end
            if (DUT.dc_addr2 !== DUT.incr_addr) begin
                err = 1'b1;
                $display("Error: incorrect dc_addr2 - Expected: %d (incr_addr), Actual: %d", 
                        DUT.incr_addr, DUT.dc_addr2);
            end
            $display("Crack module 2 won with key: %h", DUT.key_2);
        end else begin
            // No key found yet (shouldn't happen in RDP)
            err = 1'b1;
            $display("Error: Neither crack module has key_valid set!");
        end

        if (~err) begin
            $display("TEST 7 PASSED - RDP");
            s_count = s_count + 16'd1;
            t_count = t_count + 16'd1;
        end else begin 
            $display("TEST 7 FAILED - RDP"); 
            totalerr = 1'b1; 
            err = 1'b0; 
        end

        // TEST 8: WRP - Write plaintext to memory
        @(posedge clk); #5;
        checkstate(WRP);

        check_1bit_signals(1'b0, 1'b0, 1'b1);  // en_1=0, en_2=0, pt_wren=1 (assuming one won)

        // Check common outputs (always the same)
        if (DUT.addr !== DUT.incr_addr) begin
            err = 1'b1;
            $display("Error: incorrect addr - Expected: %d, Actual: %d", 
                    DUT.incr_addr, DUT.addr);
        end
        if (DUT.dc_addr1 !== 8'd0) begin
            err = 1'b1;
            $display("Error: incorrect dc_addr1 - Expected: 0, Actual: %d", DUT.dc_addr1);
        end
        if (DUT.dc_addr2 !== 8'd0) begin
            err = 1'b1;
            $display("Error: incorrect dc_addr2 - Expected: 0, Actual: %d", DUT.dc_addr2);
        end

        // Check conditional outputs based on which crack module won
        if (DUT.key_valid_1) begin
            // Crack module 1 won - verify pt_wrdata comes from dc_rddata1
            if (DUT.pt_wren !== 1'b1) begin
                err = 1'b1;
                $display("Error: pt_wren should be 1");
            end
            if (DUT.pt_wrdata !== DUT.dc_rddata1) begin
                err = 1'b1;
                $display("Error: pt_wrdata=%d, expected dc_rddata1=%d", 
                        DUT.pt_wrdata, DUT.dc_rddata1);
            end
        end else if (DUT.key_valid_2) begin
            // Crack module 2 won - verify pt_wrdata comes from dc_rddata2
            if (DUT.pt_wren !== 1'b1) begin
                err = 1'b1;
                $display("Error: pt_wren should be 1");
            end
            if (DUT.pt_wrdata !== DUT.dc_rddata2) begin
                err = 1'b1;
                $display("Error: pt_wrdata=%d, expected dc_rddata2=%d", 
                        DUT.pt_wrdata, DUT.dc_rddata2);
            end
        end else begin
            // Neither won (shouldn't happen in normal operation)
            if (DUT.pt_wren !== 1'b0) begin
                err = 1'b1;
                $display("Error: pt_wren should be 0 when no key_valid");
            end
            if (DUT.pt_wrdata !== 8'd0) begin
                err = 1'b1;
                $display("Error: pt_wrdata should be 0 when no key_valid");
            end
        end

        if (~err) begin
            $display("TEST 8 PASSED - WRP");
            s_count = s_count + 16'd1;
            t_count = t_count + 16'd1;
        end else begin 
            $display("TEST 8 FAILED - WRP"); 
            totalerr = 1'b1; 
            err = 1'b0; 
        end


    // TEST 9-10: Loop through all iterations
    iteration = 1;

    $display("\nStarting loop iterations (mlen = %d)...", DUT.mlen);

    while (DUT.incr_addr <= DUT.mlen) begin
        if (iteration % 10 == 0 || iteration == 1) begin
            $display("  Processing iteration %0d (incr_addr = %0d)...", iteration, DUT.incr_addr);
        end
        
        // INCR state
        @(posedge clk); #5;
        checkstate(INCR);
        check_1bit_signals(1'b0, 1'b0, 1'b0);
        checkoutputsignals(8'd0, 8'd0, 8'd0, 8'd0);
    
    if (err) begin 
        $display("ERROR at iteration %0d INCR state", iteration);
        totalerr = 1'b1; 
        err = 1'b0; 
    end else if (iteration == 1) begin
        $display("TEST 9 PASSED: INCR");
        s_count = s_count + 16'd1;
        t_count = t_count + 16'd1;
    end

    // LOOP state
    @(posedge clk); #5;
    checkstate(LOOP);
    check_1bit_signals(1'b0, 1'b0, 1'b0);
    checkoutputsignals(8'd0, 8'd0, 8'd0, 8'd0);
    
    if (err) begin 
        $display("ERROR at iteration %0d LOOP state", iteration);
        totalerr = 1'b1; 
        err = 1'b0; 
    end else if (iteration == 1) begin
        $display("TEST 10 PASSED: LOOP");
        s_count = s_count + 16'd1;
        t_count = t_count + 16'd1;
    end

    // Check if we're looping back or exiting
    if (DUT.incr_addr <= DUT.mlen) begin
        // Should loop back to RDP
        @(posedge clk); #5;
        checkstate(RDP);
        check_1bit_signals(1'b0, 1'b0, 1'b0);
        
        // Verify correct crack module is being read
        if (DUT.key_valid_1) begin
            if (DUT.dc_addr1 !== DUT.incr_addr || DUT.dc_addr2 !== 8'd0) begin
                $display("ERROR at iteration %0d RDP: dc_addr1=%d (expected %d), dc_addr2=%d (expected 0)",
                         iteration, DUT.dc_addr1, DUT.incr_addr, DUT.dc_addr2);
                totalerr = 1'b1;
            end
        end else if (DUT.key_valid_2) begin
            if (DUT.dc_addr1 !== 8'd0 || DUT.dc_addr2 !== DUT.incr_addr) begin
                $display("ERROR at iteration %0d RDP: dc_addr1=%d (expected 0), dc_addr2=%d (expected %d)",
                         iteration, DUT.dc_addr1, DUT.dc_addr2, DUT.incr_addr);
                totalerr = 1'b1;
            end
        end
        
        // WRP state
        @(posedge clk); #5;
        checkstate(WRP);
        check_1bit_signals(1'b0, 1'b0, 1'b1);
        
        // Verify correct data is being written
        if (DUT.key_valid_1) begin
            if (DUT.pt_wrdata !== DUT.dc_rddata1) begin
                $display("ERROR at iteration %0d WRP: pt_wrdata=%d, expected dc_rddata1=%d",
                         iteration, DUT.pt_wrdata, DUT.dc_rddata1);
                totalerr = 1'b1;
            end
        end else if (DUT.key_valid_2) begin
            if (DUT.pt_wrdata !== DUT.dc_rddata2) begin
                $display("ERROR at iteration %0d WRP: pt_wrdata=%d, expected dc_rddata2=%d",
                         iteration, DUT.pt_wrdata, DUT.dc_rddata2);
                totalerr = 1'b1;
            end
        end
    end
    
            iteration = iteration + 1;
            
            // Timeout protection
            if (iteration > 300) begin
                $display("ERROR: Timeout in loop after %0d iterations!", iteration);
                totalerr = 1'b1;
                break;
            end
        end

        $display("Completed all %0d iterations successfully", iteration - 1);

        // SET EN TO 0 BEFORE WAITING FOR IDLE
        en = 1'b0; #5;

        // Wait for return to IDLE
        wait(DUT.present_state == IDLE);
        @(posedge clk); #5;

        // TEST 11: Return to IDLE after completion
        checkstate(IDLE);
        check_1bit_signals(1'b0, 1'b0, 1'b0);
        checkoutputsignals(8'd0, 8'd0, 8'd0, 8'd0);

        if (~err) begin
            $display("TEST 11 PASSED: Returned to IDLE after completion");
            s_count = s_count + 16'd1;
            t_count = t_count + 16'd1;
        end else begin 
            $display("TEST 11 FAILED"); 
            totalerr = 1'b1; 
            err = 1'b0; 
        end

        // Verify key_valid is set
        if (key_valid !== 1'b1) begin
            $display("ERROR: key_valid should be 1 in IDLE after success");
            totalerr = 1'b1;
        end else begin
            $display("Key found: %h", key);
        end


        // Summary
        $display("\n--- SUMMARY ---");

        $display("States tested: %0d", s_count);
        $display("Transitions tested: %0d", t_count);

        if (~totalerr) 
            $display("\nALL TESTS PASSED ");
        else 
            $display("\nTESTS FAILED ");
            
       
    end

endmodule: tb_rtl_doublecrack