`timescale 1ps/1ps
module tb_syn_init();
    // DUT input and output signals:
    logic clk, rst_n, en, rdy, wren;
    logic [7:0] addr, wrdata; 
 
    // Debugging signals:
    logic err, totalerr;
    logic [2:0] t; // t = number of transitions passed tests

    // Instantiate DUT: 
    init DUT(.clk(clk), .rst_n(rst_n), .en(en), .rdy(rdy), .addr(addr), .wrdata(wrdata), .wren(wren));

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
        t = 3'b0;

        // Initialize inputs:
        rst_n = 1'b1; // active-low
        en = 1'b0; #5;
 
        // TEST 1: Check reset
        rst_n = 1'b0; #5; // assert reset
        @(posedge clk);
        checksig(1'b1, 1'b0);
        checkoutputs(8'd0, 8'd0);
        if (~err) begin
            $display("TEST 1 PASSED");
            t = t + 3'd1;
        end else begin
            $display("TEST 1 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // TEST 2: Check outputs from IDLE -> START
        rst_n = 1'b1; #5;// de-assert reset
        en = 1'b1; #5;// assert en
        @(posedge clk);
        checksig(1'b0, 1'b1);
        checkoutputs(8'd0, 8'd0);
        if (~err) begin
            $display("TEST 2 PASSED");
            t = t + 3'd1;
        end else begin
            $display("TEST 2 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        en = 1'b0; #5;// de-assert en
        
        // TEST 3: Check outputs from START -> INCR
        @(posedge clk);
        checksig(1'b0, 1'b0);
        checkoutputs(8'd1, 8'd1);
        if (~err) begin
            $display("TEST 3 PASSED");
            t = t + 3'd1;
        end else begin
            $display("TEST 3 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end
        
        // TEST 4: Check outputs from INCR -> WRT
        @(posedge clk);
        checksig(1'b0, 1'b1);
        checkoutputs(8'd1, 8'd1);
        if (~err) begin
            $display("TEST 4 PASSED");
            t = t + 3'd1;
        end else begin
            $display("TEST 4 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // TEST 5: Check outputs from WRT -> INCR 
        @(posedge clk);
        checksig(1'b0, 1'b0);
        checkoutputs(8'd2, 8'd2);
        if (~err) begin
            $display("TEST 5 PASSED");
            t = t + 3'd1;
        end else begin
            $display("TEST 5 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        // TEST 6: Check that wrdata and addr reach 255
        // Need to increment 253 more times -- wait 2 cycles per increment in address abd 1 cycle to reach the final WRT state
        // Total cycles to wait = 253*2+1 = 507
        repeat(507) @(posedge clk);
        checksig(1'b0, 1'b1);
        checkoutputs(8'd255, 8'd255);
        if (~err) $display("TEST 6 PASSED");
        else begin
            $display("TEST 6 FAILED");
            err = 1'b0;
            totalerr = 1'b1; 
        end

        // TEST 7: Check outputs from WRT->IDLE
        @(posedge clk);
        checksig(1'b1, 1'b0);
        checkoutputs(8'd0, 8'd0);
        if (~err) begin
            $display("TEST 7 PASSED");
            t = t + 2'd1;
        end else begin
            $display("TEST 7 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end 

        if (~totalerr) $display("ALL TESTS PASSED:  %d / 6 Transitions Passed", t);
        else $display("TESTS FAILED:  %d / 6 Transitions Passed", t);

    end

endmodule: tb_syn_init