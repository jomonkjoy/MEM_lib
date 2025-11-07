// Dual Port SRAM Module
// Supports both behavioral model and Xilinx primitive instantiation
// True dual port: independent read and write ports with separate addresses

module dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH),
    parameter RAM_STYLE = "auto",      // "auto", "block", "distributed", "ultra", "registers"
    parameter READ_MODE = "read_first", // "read_first", "write_first", "no_change"
    parameter USE_XILINX_PRIM = 0,     // 0: behavioral, 1: Xilinx RAM primitives
    parameter INIT_FILE = ""           // Optional initialization file (hex format)
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

    generate
        if (USE_XILINX_PRIM == 1 && DEPTH == 32) begin : xilinx_prim_32
            // Xilinx RAM32X1D primitive implementation
            // Supports 32-deep memories (5-bit address)
            // Instantiate one primitive per data bit
            
            genvar i;
            for (i = 0; i < DATA_WIDTH; i = i + 1) begin : ram_gen
                RAM32X1D #(
                    .INIT(32'h00000000) // Initial contents of RAM
                ) RAM32X1D_inst (
                    .DPO(rd_data[i]),        // Read-only 1-bit data output
                    .SPO(),                  // R/W 1-bit data output (unused)
                    .A0(wr_addr[0]),         // R/W address[0] input bit
                    .A1(wr_addr[1]),         // R/W address[1] input bit
                    .A2(wr_addr[2]),         // R/W address[2] input bit
                    .A3(wr_addr[3]),         // R/W address[3] input bit
                    .A4(wr_addr[4]),         // R/W address[4] input bit
                    .D(wr_data[i]),          // Write 1-bit data input
                    .DPRA0(rd_addr[0]),      // Read-only address[0] input bit
                    .DPRA1(rd_addr[1]),      // Read-only address[1] input bit
                    .DPRA2(rd_addr[2]),      // Read-only address[2] input bit
                    .DPRA3(rd_addr[3]),      // Read-only address[3] input bit
                    .DPRA4(rd_addr[4]),      // Read-only address[4] input bit
                    .WCLK(wr_clk),           // Write clock input
                    .WE(wr_en)               // Write enable input
                );
            end
            
        end else if (USE_XILINX_PRIM == 1 && DEPTH == 64) begin : xilinx_prim_64
            // Xilinx RAM64X1D primitive implementation
            // Supports 64-deep memories (6-bit address)
            
            genvar i;
            for (i = 0; i < DATA_WIDTH; i = i + 1) begin : ram_gen
                RAM64X1D #(
                    .INIT(64'h0000000000000000)
                ) RAM64X1D_inst (
                    .DPO(rd_data[i]),        // Read-only 1-bit data output
                    .SPO(),                  // R/W 1-bit data output (unused)
                    .A0(wr_addr[0]),         // R/W address[0] input bit
                    .A1(wr_addr[1]),         // R/W address[1] input bit
                    .A2(wr_addr[2]),         // R/W address[2] input bit
                    .A3(wr_addr[3]),         // R/W address[3] input bit
                    .A4(wr_addr[4]),         // R/W address[4] input bit
                    .A5(wr_addr[5]),         // R/W address[5] input bit
                    .D(wr_data[i]),          // Write 1-bit data input
                    .DPRA0(rd_addr[0]),      // Read-only address[0] input bit
                    .DPRA1(rd_addr[1]),      // Read-only address[1] input bit
                    .DPRA2(rd_addr[2]),      // Read-only address[2] input bit
                    .DPRA3(rd_addr[3]),      // Read-only address[3] input bit
                    .DPRA4(rd_addr[4]),      // Read-only address[4] input bit
                    .DPRA5(rd_addr[5]),      // Read-only address[5] input bit
                    .WCLK(wr_clk),           // Write clock input
                    .WE(wr_en)               // Write enable input
                );
            end
            
        end else begin : behavioral
            // Behavioral implementation - synthesizable for any FPGA/ASIC
            
            // RAM storage
            (* ram_style = RAM_STYLE *)
            logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
            
            // Optional initialization from file
            initial begin
                if (INIT_FILE != "") begin
                    $readmemh(INIT_FILE, mem);
                end else begin
                    for (int i = 0; i < DEPTH; i++) begin
                        mem[i] = '0;
                    end
                end
            end
            
            // Write port with configurable read modes
            always_ff @(posedge wr_clk) begin
                if (wr_en) begin
                    mem[wr_addr] <= wr_data;
                end
            end
            
            // Read port (registered output)
            always_ff @(posedge rd_clk) begin
                if (rd_en) begin
                    rd_data <= mem[rd_addr];
                end
            end
            
        end
    endgenerate

endmodule
