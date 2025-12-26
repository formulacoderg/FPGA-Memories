`timescale 1ps/1ps

module tb_rtl_task1();

    // DUT input and output signals:
    logic clk, rst_n;
    logic [9:0] SW, LEDR;

    logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

    // Debugging signals:
    logic err, totalerr, err_mem;
    logic [2:0] s, t; // s = number of states passed tests, t = number of transitions passed tests

    logic [8:0] i;
   
    // Instantiate DUT: 
    task1 DUT(.CLOCK_50(clk), .KEY(rst_n), .SW(SW),
             .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2),
             .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5),
             .LEDR(LEDR));
   
       // Declare state constants: 
    localparam logic [1:0]
        IDLE = 2'b00, // waiting state
        WORKING = 2'b01, // save first variable at addr = 0 and wrdata = 0
        DONE = 2'b10, START = 2'b11; // increment address and data
        
    // Checking current state:
    task checkstate;
    input [1:0] expected_state;
    begin
        assert(expected_state == DUT.present_state)
            else begin
                err = 1'b1;
                $display("Error: incorrect state - Expected: %b, Actual: %b", expected_state, DUT.present_state);
            end
    end
    endtask

    task checksig;
    input expected_en;
    begin
        assert(expected_en == DUT.en)
            else begin
                err = 1'b1;
                $display("Error: incorrect en signal - Expected: %d, Actual: %d", expected_en, DUT.en);
            end
    end
    endtask

    // Generate clock signal:
    initial clk = 1'b0;
    always  #10 clk = ~clk;

    // Start tests:
    initial begin
        // Initialize debugging signals:
        err = 1'b0;
        err_mem = 1'b0;
        totalerr = 1'b0;
        s = 3'b0;
        t = 3'b0;

        rst_n = 1'b0; // assert reset
        @(posedge clk); #5;

        checkstate(IDLE);
        checksig(1'b0);
   

        if (~err) begin
            $display("TEST 1 PASSED");
            s = s + 3'd1;
            t = t + 3'd1;
        end else begin
            $display("TEST 1 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

       // @(posedge clk);
        rst_n = 1'b1; #5;// de-assert reset

        @(posedge clk); #5;
        checkstate(START);
        checksig(1'b1);
        if (~err) begin
            $display("TEST 2 PASSED");
            s = s + 3'd1;
            t = t + 3'd1;
        end else begin
            $display("TEST 2 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        @(posedge clk); #5;
        checkstate(WORKING);
        checksig(1'b0);
        if (~err) begin
            $display("TEST 3 PASSED");
            s = s + 3'd1;
            t = t + 3'd1;
        end else begin
            $display("TEST 3 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        wait (DUT.rdy == 1);
        @(posedge clk);#5;   
        
        checkstate(DONE);
        checksig(1'b0);

        if (~err) begin
            $display("TEST 4 PASSED");
            s = s + 3'd1;
            t = t + 3'd1;
        end else begin
            $display("TEST 4 FAILED");
            err = 1'b0;
            totalerr = 1'b1;
        end

        @(posedge clk);#5;   
        
        checkstate(DONE);


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
        $display("Memory check FAILED: one or more addresses incorrect.");

        if (~totalerr) $display("ALL TESTS PASSED: %d / 4 States Passed, %d / 4 Transitions Passed", s, t);
        else $display("TESTS FAILED: %d / 4 States Passed, %d / 4 Transitions Passed", s, t);

    end

endmodule: tb_rtl_task1
