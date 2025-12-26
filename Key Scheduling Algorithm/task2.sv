module task2(
    input  logic CLOCK_50,
    input  logic [3:0] KEY,
    input  logic [9:0] SW,
    output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output logic [9:0] LEDR
);


    // Internal signals
    logic i_en, i_rdy;
    logic k_en, k_rdy;
    logic [7:0] i_addr, k_addr, addr;
    logic [7:0] i_wrdata, k_wrdata, wrdata;
    logic i_wren, k_wren, wren;
    logic [7:0] q;
    logic [23:0] key;

    // Control FSM
    enum logic [2:0] {
        IDLE = 3'd0,
        STARTI = 3'd1,
        INIT = 3'd2,
        STARTK = 3'd3,
        KSA = 3'd4,
        DONE = 3'd5
    } present_state, next_state;

    // Reset signal
    logic rst_n;
    assign rst_n = KEY[3];

    // Instantiate s_mem
    s_mem s(
        .address(addr),
        .clock(CLOCK_50),
        .data(wrdata),
        .wren(wren),
        .q(q)
    );

    // Instantiate init module
    init i(
        .clk(CLOCK_50),
        .rst_n(rst_n),
        .en(i_en),
        .rdy(i_rdy),
        .addr(i_addr),
        .wrdata(i_wrdata),
        .wren(i_wren)
    );

    assign key = {14'b0, SW[9:0]};

        // Instantiate ksa module
    ksa k(
        .clk(CLOCK_50),
        .rst_n(rst_n),
        .en(k_en),
        .rdy(k_rdy),
        .key(key),
        .addr(k_addr),
        .rddata(q),
        .wrdata(k_wrdata),
        .wren(k_wren)
    );

    // State register
    always_ff @(posedge CLOCK_50) begin
        if (~rst_n) begin
            present_state <= IDLE;
        end else begin
            present_state <= next_state;
        end
    end

    // Next state logic - automatically progresses after reset
    always_comb begin
        case (present_state)
            IDLE: next_state = STARTI;  // Auto-start after reset applied
            STARTI: next_state = (~i_rdy) ? INIT : STARTI;
            INIT: next_state = i_rdy ? STARTK : INIT;            
            STARTK: next_state = (~k_rdy) ? KSA : STARTK;
            KSA: next_state = (k_rdy) ? DONE : KSA;
            DONE: next_state = DONE;
            default: next_state = IDLE;
        endcase
    end
    
    // Output control logic and memory multiplexing
    always_comb begin
        // Default values
        i_en = 1'b0;
        k_en = 1'b0;
        addr = 8'b0;
        wrdata = 8'b0;
        wren = 1'b0;   
        
        case (present_state)
            STARTI: begin
                i_en = 1'b1;  
                addr = i_addr;
                wrdata = i_wrdata;
                wren = i_wren;
            end
            
            INIT: begin
                i_en = 1'b0;
                addr = i_addr;
                wrdata = i_wrdata;
                wren = i_wren;
            end
            
            STARTK: begin
                k_en = 1'b1; 
                addr = k_addr;
                wrdata = k_wrdata;
                wren = k_wren;
            end
            
            KSA: begin
                k_en = 1'b0; 
                addr = k_addr;
                wrdata = k_wrdata;
                wren = k_wren;
            end
            
            default: begin
                i_en = 1'b0;
                k_en = 1'b0;
                addr = 8'b0;
                wrdata = 8'b0;
                wren = 1'b0;  
            end
        endcase
    end


endmodule