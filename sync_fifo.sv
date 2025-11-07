// Synchronous FIFO with Dual Port SRAM
// Single clock domain FIFO with configurable depth and data width
// Uses separate dual_port_ram module for memory

module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH),
    parameter RAM_STYLE = "auto",
    parameter USE_XILINX_PRIM = 0
) (
    input  logic                    clk,
    input  logic                    rst_n,
    
    // Write interface
    input  logic                    wr_en,
    input  logic [DATA_WIDTH-1:0]   wr_data,
    output logic                    full,
    output logic [ADDR_WIDTH:0]     wr_count,
    
    // Read interface
    input  logic                    rd_en,
    output logic [DATA_WIDTH-1:0]   rd_data,
    output logic                    empty,
    output logic [ADDR_WIDTH:0]     rd_count
);

    // Internal signals
    logic [ADDR_WIDTH-1:0] wr_ptr;
    logic [ADDR_WIDTH-1:0] rd_ptr;
    logic [ADDR_WIDTH:0]   count;
    logic                  ram_wr_en;
    
    // Full and empty generation
    assign full  = (count == DEPTH);
    assign empty = (count == 0);
    assign wr_count = count;
    assign rd_count = count;
    
    // RAM write enable (only write when not full and write requested)
    assign ram_wr_en = wr_en && !full;
    
    // Instantiate dual port RAM
    dual_port_ram #(
        .DATA_WIDTH     (DATA_WIDTH),
        .DEPTH          (DEPTH),
        .ADDR_WIDTH     (ADDR_WIDTH),
        .RAM_STYLE      (RAM_STYLE),
        .USE_XILINX_PRIM(USE_XILINX_PRIM)
    ) u_ram (
        .wr_clk   (clk),
        .wr_en    (ram_wr_en),
        .wr_addr  (wr_ptr),
        .wr_data  (wr_data),
        .rd_clk   (clk),
        .rd_addr  (rd_ptr),
        .rd_data  (rd_data)
    );
    
    // Write pointer
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
        end else if (wr_en && !full) begin
            wr_ptr <= wr_ptr + 1'b1;
        end
    end
    
    // Read pointer
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= '0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1'b1;
        end
    end
    
    // Count management
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= '0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: count <= count + 1'b1;  // Write only
                2'b01: count <= count - 1'b1;  // Read only
                default: count <= count;        // Both or neither
            endcase
        end
    end

endmodule
