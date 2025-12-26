`timescale 1ps/1ps
module task1(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [9:0] LEDR);

    logic [7:0] addr, wrdata, address, data, q;
    logic rdy, en, wren;
    
    // instantiate s_mem
    s_mem s(.address(address), .clock(CLOCK_50), .data(data), .wren(wren), .q(q));

    // instantiate init
    init i(.clk(CLOCK_50), .rst_n(KEY[3]), .en(en), .rdy(rdy), .addr(addr), .wrdata(wrdata), .wren(wren));

    enum logic [1:0] {
        IDLE = 2'b00,
        WORKING = 2'b01,
        DONE = 2'b10,
        START = 2'b11
    } present_state, next_state;

    always_comb begin
        case(present_state)
            IDLE: next_state = rdy ? START : IDLE;
            START: next_state = WORKING;
            WORKING: next_state = rdy ? DONE : WORKING;
            DONE: next_state = DONE;
            default:begin
                next_state = IDLE;
            end
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
        case(present_state) 

            START: begin
                en = 1'b1;
                address = addr;
                data = wrdata;
            end
            WORKING: begin
                en = 1'b0;
                address = addr;
                data = wrdata;
            end DONE: begin
                en = 1'b0;
                address = 8'd0;
                data = 8'd0;
            end default: begin
                en = 1'b0;
                address = 8'd0;
                data = 8'd0;
            end
        endcase
    end

    endmodule: task1