//=============================================================================
// Dual Port RAM with Byte Enable
// Useful for processors with byte-level access
//=============================================================================

module dual_port_ram_be #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 256,
    parameter ADDR_WIDTH = $clog2(DEPTH),
    parameter NUM_BYTES = DATA_WIDTH / 8,
    parameter RAM_STYLE = "auto"
) (
    // Write port
    input  logic                    wr_clk,
    input  logic [NUM_BYTES-1:0]    wr_be,       // Byte write enables
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
    
    // Write port with byte enables
    always_ff @(posedge wr_clk) begin
        for (int i = 0; i < NUM_BYTES; i++) begin
            if (wr_be[i]) begin
                mem[wr_addr][i*8 +: 8] <= wr_data[i*8 +: 8];
            end
        end
    end
    
    // Read port
    always_ff @(posedge rd_clk) begin
        if (rd_en) begin
            rd_data <= mem[rd_addr];
        end
    end

endmodule
