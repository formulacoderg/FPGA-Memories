`timescale 1ps/1ps

module tb_syn_task1();

    logic clk;
    logic [3:0] KEY;  
    logic [9:0] SW, LEDR;
    logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    
    // JTAG signals
    logic altera_reserved_tms;
    logic altera_reserved_tck;
    logic altera_reserved_tdi;
    logic altera_reserved_tdo;
    
    logic err_mem;
    integer i;
   
    // Instantiate DUT:
    task1 DUT(
        .altera_reserved_tms(altera_reserved_tms),
        .altera_reserved_tck(altera_reserved_tck),
        .altera_reserved_tdi(altera_reserved_tdi),
        .altera_reserved_tdo(altera_reserved_tdo),
        .CLOCK_50(clk), 
        .KEY(KEY),  
        .SW(SW),
        .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2),
        .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5),
        .LEDR(LEDR)
    );  

    initial clk = 1'b0;
    always #10 clk = ~clk;

    initial begin
        $display("Starting Post-Synthesis Simulation");
        err_mem = 1'b0;
        SW = 10'b0;
        KEY = 4'b1111;  // Initialize all KEY bits //this was causing the memory not to be initialized, so assign reset to key[3] directly or it wont start
        
        // Initialize JTAG signals
        altera_reserved_tms = 1'b0;
        altera_reserved_tck = 1'b0;
        altera_reserved_tdi = 1'b0;
       
        // Apply reset on KEY[3]
        KEY[3] = 1'b0;  // Assert reset
        repeat(10) @(posedge clk);
        $display("Reset released at time %t", $time);
        
        KEY[3] = 1'b1;  // De-assert reset
        
        // Wait for design to complete
        $display("Waiting for memory initialization to complete...");
        repeat(1000) @(posedge clk);
        
        $display("Checking memory at time %t", $time);
        
        // Memory check
        for (i = 0; i < 256; i = i + 1) begin
            if (DUT.\s|altsyncram_component|auto_generated|altsyncram1|ram_block3a0 .ram_core0.ram_core0.mem[i] !== i[7:0]) begin
                $display("ERROR: mem[%0d] = %h, expected %h", i,
                         DUT.\s|altsyncram_component|auto_generated|altsyncram1|ram_block3a0 .ram_core0.ram_core0.mem[i],
                         i[7:0]);
                err_mem = 1'b1;
            end
        end

        if (~err_mem)
            $display("MEMORY CHECK PASSED: All 256 addresses (0-255) initialized correctly");
        else
            $display("MEMORY CHECK FAILED: One or more addresses incorrect");
        
    end

 endmodule: tb_syn_task1