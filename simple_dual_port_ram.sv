//=============================================================================
// Simple Dual Port RAM (1 write port, 1 read port)
// Most common configuration for FIFOs and buffers
//=============================================================================

module simple_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 256,
    parameter ADDR_WIDTH = $clog2(DEPTH),
    parameter RAM_STYLE = "auto",
    parameter INIT_FILE = ""
) (
    // Write port
    input  logic                    wr_clk,
    input  logic                    wr_en,
    input  logic [ADDR_WIDTH-1:0]   wr_addr,
    input  logic [DATA_WIDTH-1:0]   wr_data,
    
    // Read port
    input  logic                    rd_clk,
    input  logic                    rd_en,
    input  logic [ADDR_WIDTH-1:0]   rd_addr,
    output logic [DATA_WIDTH-1:0]   rd_data
);

    // RAM storage
    (* ram_style = RAM_STYLE *)
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    // Optional initialization
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end
    
    // Write port
    always_ff @(posedge wr_clk) begin
        if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end
    
    // Read port
    always_ff @(posedge rd_clk) begin
        if (rd_en) begin
            rd_data <= mem[rd_addr];
        end
    end

endmodule
