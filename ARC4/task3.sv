module task3(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [9:0] LEDR);
    logic pt_wren, rdy, en, rst_n;
    logic [7:0] ct_addr, pt_addr, pt_wrdata, ct_q, pt_q;
    logic [23:0] key;

    ct_mem ct(.address(ct_addr), .clock(CLOCK_50), .data(8'd0), .wren(1'b0), .q(ct_q)); // set ct_wren and ct_wrdata = 0 since we will not be writing to that file
    pt_mem pt(.address(pt_addr), .clock(CLOCK_50), .data(pt_wrdata), .wren(pt_wren), .q(pt_q));
    arc4 a4(.clk(CLOCK_50), .rst_n(KEY[3]), .en(en), .rdy(rdy), .key(key), .ct_addr(ct_addr), 
            .ct_rddata(ct_q), .pt_addr(pt_addr), .pt_rddata(pt_q), .pt_wrdata(pt_wrdata), .pt_wren(pt_wren));

    assign key = {14'b0, SW[9:0]};

    enum logic [1:0] {
        IDLE = 2'b00,
        WORKING = 2'b01,
        DONE = 2'b10,
        START = 2'b11
    } present_state, next_state;

    always_comb begin
        case(present_state)
            IDLE: next_state = rdy ? START : IDLE;
            START: next_state = ~rdy ? WORKING : START;
            WORKING: next_state = rdy ? DONE : WORKING;
            DONE: next_state = DONE;
            default: next_state = IDLE;
        endcase
    end

    always_ff @(posedge CLOCK_50) begin
        if (~KEY[3]) begin
            present_state <= IDLE;
        end else begin
            present_state <= next_state;
        end
    end

    always_comb begin
        if (present_state == START) en = 1'b1;
    end
 
endmodule: task3