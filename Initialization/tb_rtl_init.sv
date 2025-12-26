`timescale 1ps/1ps
module tb_rtl_init();
    // DUT input and output signals:
    logic clk, rst_n, en, rdy, wren;
    logic [7:0] addr, wrdata; 
 
    // Debugging signals:
    logic err, totalerr;
    logic [2:0] s, t; // s = number of states passed tests, t = number of transitions passed tests
    logic [7:0] test_addr, test_wrdata; // for debugging loop

    // Instantiate DUT: 
    init DUT(.clk(clk), .rst_n(rst_n), .en(en), .rdy(rdy), .addr(addr), .wrdata(wrdata), .wren(wren));
    
    // Declare state constants (updated for 2-state FSM):
    localparam logic
        IDLE = 2'b0,
        WRITE = 2'b1;

    // Checking current state:
    task checkstate;
    input expected_state;
    begin
        assert(expected_state == DUT.present_state)
            else begin
                err = 1'b1;
                $display("Error: incorrect state - Expected: %b, Actual: %b", expected_state, DUT.present_state);
            end
    end
    endtask

    // Checking output signals - address and data:
    task checkoutputs;
    input [7:0] expected_addr, expected_wrdata;
    begin
        assert(expected_addr == addr)
            else begin
                err = 1'b1;
                $display("Error: incorrect address - Expected: %d, Actual: %d", expected_addr, addr);
            end

        assert(expected_wrdata == wrdata)
            else begin
                err = 1'b1;
                $display("Error: incorrect wrdata - Expected: %d, Actual: %d", expected_wrdata, wrdata);
            end

        // check if wrdata == addr (should be equal)
        assert (wrdata == addr)
            else begin
                err = 1'b1;
                $display("Error: addr and wrdata mismatch - addr: %d, wrdata: %d", addr, wrdata);
            end
    end
    endtask 

    // Checking output signals - rdy and wren
    task checksig;
    input expected_rdy, expected_wren;
    begin
        assert(expected_rdy == rdy)
            else begin
                err = 1'b1;
                $display("Error: incorrect rdy - Expected: %d, Actual: %d", expected_rdy, rdy);
            end
        
        assert(expected_wren == wren)
            else begin
                err = 1'b1;
                $display("Error: incorrect wren - Expected: %d, Actual: %d", expected_wren, wren);
            end
    end
    endtask

    // Generate clock signal:
    initial clk = 1'b0;
    always  #5 clk = ~clk;

    // Start tests:
    initial begin
        // Initialize debugging signals:
        err = 1'b0;
        totalerr = 1'b0;
        s = 3'b0;
        t = 3'b0;

        // Initialize inputs:
        rst_n = 1'b1; // active-low
        en = 1'b0; #5;
 
        // TEST 1: Check Reset and IDLE State
        rst_n = 1'b0; #5; // assert reset
        @(posedge clk);
        checkstate(IDLE);
        checksig(1'b1, 1'b0);
        checkoutputs(8'd0, 8'd0);
        if (~err) begin
            $display("TEST 1 PASSED");
            s = s + 3'd1;
            t = t + 3'd1;
        end else begin
            $display("TEST 1 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // TEST 2: Check IDLE -> WRITE transition and first write (i=0)
        rst_n = 1'b1; #5; // de-assert reset
        en = 1'b1; #5; // assert en
        @(posedge clk); // Transition to WRITE, i gets reset to 0
        @(posedge clk); // Now in WRITE state with i=0
        checkstate(WRITE);
        checksig(1'b0, 1'b1);
        checkoutputs(8'd0, 8'd0);
        if (~err) begin
            $display("TEST 2 PASSED - First write at addr=0");
            s = s + 3'd1;
            t = t + 3'd1;
        end else begin
            $display("TEST 2 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        en = 1'b0; #5; // de-assert en

        // TEST 3: Check second write (i=1)
        @(posedge clk);
        checkstate(WRITE);
        checksig(1'b0, 1'b1);
        checkoutputs(8'd1, 8'd1);
        if (~err) begin
            $display("TEST 3 PASSED - Second write at addr=1");
            s = s + 3'd1;
        end else begin
            $display("TEST 3 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // TEST 4: Loop through remaining writes (i=2 to i=254)
        test_addr = 8'd2;
        test_wrdata = 8'd2;

        repeat(253) begin
            @(posedge clk);
            checkstate(WRITE);
            checksig(1'b0, 1'b1);
            checkoutputs(test_addr, test_wrdata);
            if (err) begin
                $display("Write at addr=%d FAILED", test_addr);
                totalerr = 1'b1;
                err = 1'b0;
            end
            test_addr = test_addr + 8'd1;
            test_wrdata = test_wrdata + 8'd1;
        end
        if (~err) $display("TEST 4 PASSED - All writes from 2 to 254 correct");

        // TEST 5: Check final write at i=255
        @(posedge clk);
        checkstate(WRITE);
        checksig(1'b0, 1'b1);
        checkoutputs(8'd255, 8'd255);
        if (~err) begin
            $display("TEST 5 PASSED - Final write at addr=255");
        end else begin
            $display("TEST 5 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // TEST 6: Check WRITE -> IDLE transition
        @(posedge clk);
        checkstate(IDLE);
        checksig(1'b1, 1'b0);
        checkoutputs(8'd0, 8'd0);
        if (~err) begin
            $display("TEST 6 PASSED - Returned to IDLE");
            t = t + 3'd1;
        end else begin
            $display("TEST 6 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end 

        @(posedge clk); #5;
        checkstate(IDLE);

        if (~totalerr) $display("ALL TESTS PASSED: %d / 2 States Tested, %d / 3 Key Transitions Tested", s, t);
        else $display("TESTS FAILED: Check individual test results above");

    end

endmodule: tb_rtl_init