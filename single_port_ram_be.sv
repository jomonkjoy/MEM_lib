//=============================================================================
// Single Port RAM with Byte Enable
// Useful for processors and DMA controllers
//=============================================================================

module single_port_ram_be #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 256,
    parameter ADDR_WIDTH = $clog2(DEPTH),
    parameter NUM_BYTES = DATA_WIDTH / 8,
    parameter RAM_STYLE = "auto",
    parameter READ_MODE = "read_first"
) (
    input  logic                    clk,
    input  logic                    en,
    input  logic [NUM_BYTES-1:0]    we,          // Byte write enables
    input  logic [ADDR_WIDTH-1:0]   addr,
    input  logic [DATA_WIDTH-1:0]   din,
    output logic [DATA_WIDTH-1:0]   dout
);

    // RAM storage
    (* ram_style = RAM_STYLE *)
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    // Single port RAM with byte-level write enable
    always_ff @(posedge clk) begin
        if (en) begin
            case (READ_MODE)
                "read_first": begin
                    dout <= mem[addr];
                    for (int i = 0; i < NUM_BYTES; i++) begin
                        if (we[i]) begin
                            mem[addr][i*8 +: 8] <= din[i*8 +: 8];
                        end
                    end
                end
                
                "write_first": begin
                    for (int i = 0; i < NUM_BYTES; i++) begin
                        if (we[i]) begin
                            mem[addr][i*8 +: 8] <= din[i*8 +: 8];
                            dout[i*8 +: 8] <= din[i*8 +: 8];
                        end else begin
                            dout[i*8 +: 8] <= mem[addr][i*8 +: 8];
                        end
                    end
                end
                
                "no_change": begin
                    if (|we) begin
                        for (int i = 0; i < NUM_BYTES; i++) begin
                            if (we[i]) begin
                                mem[addr][i*8 +: 8] <= din[i*8 +: 8];
                            end
                        end
                    end else begin
                        dout <= mem[addr];
                    end
                end
                
                default: begin
                    dout <= mem[addr];
                    for (int i = 0; i < NUM_BYTES; i++) begin
                        if (we[i]) begin
                            mem[addr][i*8 +: 8] <= din[i*8 +: 8];
                        end
                    end
                end
            endcase
        end
    end

endmodule
