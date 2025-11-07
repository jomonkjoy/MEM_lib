// Asynchronous FIFO with Modular Components
// Dual clock domain FIFO using Gray code for CDC
// Uses separate dual_port_ram and multibit_sync modules

module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH),
    parameter SYNC_STAGES = 2,
    parameter RAM_STYLE = "auto",
    parameter USE_XILINX_PRIM = 0
) (
    // Write clock domain
    input  logic                    wr_clk,
    input  logic                    wr_rst_n,
    input  logic                    wr_en,
    input  logic [DATA_WIDTH-1:0]   wr_data,
    output logic                    wr_full,
    
    // Read clock domain
    input  logic                    rd_clk,
    input  logic                    rd_rst_n,
    input  logic                    rd_en,
    output logic [DATA_WIDTH-1:0]   rd_data,
    output logic                    rd_empty
);

    // Write domain signals
    logic [ADDR_WIDTH:0] wr_ptr_bin;
    logic [ADDR_WIDTH:0] wr_ptr_gray;
    logic [ADDR_WIDTH:0] rd_ptr_gray_sync;
    logic                ram_wr_en;
    
    // Read domain signals
    logic [ADDR_WIDTH:0] rd_ptr_bin;
    logic [ADDR_WIDTH:0] rd_ptr_gray;
    logic [ADDR_WIDTH:0] wr_ptr_gray_sync;
    
    //=========================================================================
    // Binary to Gray code conversion functions
    //=========================================================================
    function automatic logic [ADDR_WIDTH:0] bin2gray(input logic [ADDR_WIDTH:0] bin);
        return bin ^ (bin >> 1);
    endfunction
    
    function automatic logic [ADDR_WIDTH:0] gray2bin(input logic [ADDR_WIDTH:0] gray);
        logic [ADDR_WIDTH:0] bin;
        bin[ADDR_WIDTH] = gray[ADDR_WIDTH];
        for (int i = ADDR_WIDTH-1; i >= 0; i--) begin
            bin[i] = bin[i+1] ^ gray[i];
        end
        return bin;
    endfunction
    
    //=========================================================================
    // Dual Port RAM Instantiation
    //=========================================================================
    
    // RAM write enable
    assign ram_wr_en = wr_en && !wr_full;
    
    dual_port_ram #(
        .DATA_WIDTH     (DATA_WIDTH),
        .DEPTH          (DEPTH),
        .ADDR_WIDTH     (ADDR_WIDTH),
        .RAM_STYLE      (RAM_STYLE),
        .USE_XILINX_PRIM(USE_XILINX_PRIM)
    ) u_ram (
        .wr_clk   (wr_clk),
        .wr_en    (ram_wr_en),
        .wr_addr  (wr_ptr_bin[ADDR_WIDTH-1:0]),
        .wr_data  (wr_data),
        .rd_clk   (rd_clk),
        .rd_addr  (rd_ptr_bin[ADDR_WIDTH-1:0]),
        .rd_data  (rd_data)
    );
    
    //=========================================================================
    // Write Clock Domain
    //=========================================================================
    
    // Write pointer management
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin  <= '0;
            wr_ptr_gray <= '0;
        end else if (wr_en && !wr_full) begin
            wr_ptr_bin  <= wr_ptr_bin + 1'b1;
            wr_ptr_gray <= bin2gray(wr_ptr_bin + 1'b1);
        end
    end
    
    // Synchronize read pointer to write clock domain
    multibit_sync #(
        .WIDTH(ADDR_WIDTH+1),
        .STAGES(SYNC_STAGES)
    ) u_rd_ptr_sync (
        .clk      (wr_clk),
        .rst_n    (wr_rst_n),
        .async_in (rd_ptr_gray),
        .sync_out (rd_ptr_gray_sync)
    );
    
    // Generate full flag
    // Full when write pointer catches up to read pointer
    // MSB and MSB-1 are inverted, rest are equal
    assign wr_full = (wr_ptr_gray == {~rd_ptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1], 
                                      rd_ptr_gray_sync[ADDR_WIDTH-2:0]});
    
    //=========================================================================
    // Read Clock Domain
    //=========================================================================
    
    // Read pointer management
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin  <= '0;
            rd_ptr_gray <= '0;
        end else if (rd_en && !rd_empty) begin
            rd_ptr_bin  <= rd_ptr_bin + 1'b1;
            rd_ptr_gray <= bin2gray(rd_ptr_bin + 1'b1);
        end
    end
    
    // Synchronize write pointer to read clock domain
    multibit_sync #(
        .WIDTH(ADDR_WIDTH+1),
        .STAGES(SYNC_STAGES)
    ) u_wr_ptr_sync (
        .clk      (rd_clk),
        .rst_n    (rd_rst_n),
        .async_in (wr_ptr_gray),
        .sync_out (wr_ptr_gray_sync)
    );
    
    // Generate empty flag
    // Empty when read pointer equals write pointer
    assign rd_empty = (rd_ptr_gray == wr_ptr_gray_sync);

endmodule
