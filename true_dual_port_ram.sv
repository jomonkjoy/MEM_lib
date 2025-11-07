//=============================================================================
// True Dual Port RAM (Both ports can read and write)
// More flexible but uses more resources
//=============================================================================

module true_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 256,
    parameter ADDR_WIDTH = $clog2(DEPTH),
    parameter RAM_STYLE = "auto",
    parameter READ_MODE_A = "read_first",
    parameter READ_MODE_B = "read_first",
    parameter INIT_FILE = ""
) (
    // Port A
    input  logic                    clk_a,
    input  logic                    en_a,
    input  logic                    we_a,
    input  logic [ADDR_WIDTH-1:0]   addr_a,
    input  logic [DATA_WIDTH-1:0]   din_a,
    output logic [DATA_WIDTH-1:0]   dout_a,
    
    // Port B
    input  logic                    clk_b,
    input  logic                    en_b,
    input  logic                    we_b,
    input  logic [ADDR_WIDTH-1:0]   addr_b,
    input  logic [DATA_WIDTH-1:0]   din_b,
    output logic [DATA_WIDTH-1:0]   dout_b
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
    
    // Port A logic
    always_ff @(posedge clk_a) begin
        if (en_a) begin
            case (READ_MODE_A)
                "read_first": begin
                    dout_a <= mem[addr_a];
                    if (we_a) begin
                        mem[addr_a] <= din_a;
                    end
                end
                
                "write_first": begin
                    if (we_a) begin
                        mem[addr_a] <= din_a;
                        dout_a <= din_a;
                    end else begin
                        dout_a <= mem[addr_a];
                    end
                end
                
                "no_change": begin
                    if (we_a) begin
                        mem[addr_a] <= din_a;
                    end else begin
                        dout_a <= mem[addr_a];
                    end
                end
                
                default: begin
                    dout_a <= mem[addr_a];
                    if (we_a) begin
                        mem[addr_a] <= din_a;
                    end
                end
            endcase
        end
    end
    
    // Port B logic
    always_ff @(posedge clk_b) begin
        if (en_b) begin
            case (READ_MODE_B)
                "read_first": begin
                    dout_b <= mem[addr_b];
                    if (we_b) begin
                        mem[addr_b] <= din_b;
                    end
                end
                
                "write_first": begin
                    if (we_b) begin
                        mem[addr_b] <= din_b;
                        dout_b <= din_b;
                    end else begin
                        dout_b <= mem[addr_b];
                    end
                end
                
                "no_change": begin
                    if (we_b) begin
                        mem[addr_b] <= din_b;
                    end else begin
                        dout_b <= mem[addr_b];
                    end
                end
                
                default: begin
                    dout_b <= mem[addr_b];
                    if (we_b) begin
                        mem[addr_b] <= din_b;
                    end
                end
            endcase
        end
    end

endmodule
