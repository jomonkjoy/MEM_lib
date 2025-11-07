// Multi-bit Synchronizer Module
// 2-stage synchronizer for Gray code CDC
// Includes attributes for proper synthesis and metastability handling

module multibit_sync #(
    parameter WIDTH = 4,
    parameter STAGES = 2  // Number of synchronizer stages (typically 2 or 3)
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic [WIDTH-1:0] async_in,
    output logic [WIDTH-1:0] sync_out
);

    // Synchronizer chain
    (* ASYNC_REG = "TRUE" *)
    (* KEEP = "TRUE" *)
    (* DONT_TOUCH = "TRUE" *)
    logic [WIDTH-1:0] sync_chain [STAGES-1:0];
    
    // First stage - receives asynchronous input
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_chain[0] <= '0;
        end else begin
            sync_chain[0] <= async_in;
        end
    end
    
    // Additional stages
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 1; i < STAGES; i++) begin
                sync_chain[i] <= '0;
            end
        end else begin
            for (int i = 1; i < STAGES; i++) begin
                sync_chain[i] <= sync_chain[i-1];
            end
        end
    end
    
    // Output the last stage
    assign sync_out = sync_chain[STAGES-1];

endmodule
