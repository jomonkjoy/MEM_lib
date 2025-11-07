// Single Port RAM Module
// Supports both behavioral model and Xilinx primitive instantiation
// Single port: shared address for read and write operations

module single_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 256,
    parameter ADDR_WIDTH = $clog2(DEPTH),
    parameter RAM_STYLE = "auto",      // "auto", "block", "distributed", "ultra", "registers"
    parameter READ_MODE = "read_first", // "read_first", "write_first", "no_change"
    parameter USE_XILINX_PRIM = 0,     // 0: behavioral, 1: Xilinx RAM primitives
    parameter INIT_FILE = ""           // Optional initialization file (hex format)
) (
    input  logic                    clk,
    input  logic                    en,          // Chip enable
    input  logic                    we,          // Write enable (1=write, 0=read)
    input  logic [ADDR_WIDTH-1:0]   addr,
    input  logic [DATA_WIDTH-1:0]   din,
    output logic [DATA_WIDTH-1:0]   dout
);

    generate
        if (USE_XILINX_PRIM == 1 && DEPTH == 32 && DATA_WIDTH == 1) begin : xilinx_prim_32x1
            // Xilinx RAM32X1S primitive - 32x1 single-port RAM
            
            RAM32X1S #(
                .INIT(32'h00000000)
            ) RAM32X1S_inst (
                .O(dout),           // 1-bit data output
                .A0(addr[0]),       // Address[0] input bit
                .A1(addr[1]),       // Address[1] input bit
                .A2(addr[2]),       // Address[2] input bit
                .A3(addr[3]),       // Address[3] input bit
                .A4(addr[4]),       // Address[4] input bit
                .D(din),            // 1-bit data input
                .WCLK(clk),         // Write clock input
                .WE(we & en)        // Write enable input
            );
            
        end else if (USE_XILINX_PRIM == 1 && DEPTH == 64 && DATA_WIDTH == 1) begin : xilinx_prim_64x1
            // Xilinx RAM64X1S primitive - 64x1 single-port RAM
            
            RAM64X1S #(
                .INIT(64'h0000000000000000)
            ) RAM64X1S_inst (
                .O(dout),           // 1-bit data output
                .A0(addr[0]),       // Address[0] input bit
                .A1(addr[1]),       // Address[1] input bit
                .A2(addr[2]),       // Address[2] input bit
                .A3(addr[3]),       // Address[3] input bit
                .A4(addr[4]),       // Address[4] input bit
                .A5(addr[5]),       // Address[5] input bit
                .D(din),            // 1-bit data input
                .WCLK(clk),         // Write clock input
                .WE(we & en)        // Write enable input
            );
            
        end else if (USE_XILINX_PRIM == 1 && DEPTH == 128 && DATA_WIDTH == 1) begin : xilinx_prim_128x1
            // Xilinx RAM128X1S primitive - 128x1 single-port RAM
            
            RAM128X1S #(
                .INIT(128'h00000000000000000000000000000000)
            ) RAM128X1S_inst (
                .O(dout),           // 1-bit data output
                .A0(addr[0]),       // Address[0] input bit
                .A1(addr[1]),       // Address[1] input bit
                .A2(addr[2]),       // Address[2] input bit
                .A3(addr[3]),       // Address[3] input bit
                .A4(addr[4]),       // Address[4] input bit
                .A5(addr[5]),       // Address[5] input bit
                .A6(addr[6]),       // Address[6] input bit
                .D(din),            // 1-bit data input
                .WCLK(clk),         // Write clock input
                .WE(we & en)        // Write enable input
            );
            
        end else if (USE_XILINX_PRIM == 1 && DEPTH == 256 && DATA_WIDTH == 1) begin : xilinx_prim_256x1
            // Xilinx RAM256X1S primitive - 256x1 single-port RAM
            
            RAM256X1S #(
                .INIT(256'h0000000000000000000000000000000000000000000000000000000000000000)
            ) RAM256X1S_inst (
                .O(dout),           // 1-bit data output
                .A(addr),           // 8-bit address input
                .D(din),            // 1-bit data input
                .WCLK(clk),         // Write clock input
                .WE(we & en)        // Write enable input
            );
            
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
            
            // Single port RAM with configurable read modes
            always_ff @(posedge clk) begin
                if (en) begin
                    case (READ_MODE)
                        "read_first": begin
                            // Read happens before write
                            dout <= mem[addr];
                            if (we) begin
                                mem[addr] <= din;
                            end
                        end
                        
                        "write_first": begin
                            // Write happens before read
                            if (we) begin
                                mem[addr] <= din;
                                dout <= din;  // Read new data
                            end else begin
                                dout <= mem[addr];
                            end
                        end
                        
                        "no_change": begin
                            // Output doesn't change during write
                            if (we) begin
                                mem[addr] <= din;
                            end else begin
                                dout <= mem[addr];
                            end
                        end
                        
                        default: begin
                            // Default to read_first
                            dout <= mem[addr];
                            if (we) begin
                                mem[addr] <= din;
                            end
                        end
                    endcase
                end
            end
            
        end
    endgenerate

endmodule
