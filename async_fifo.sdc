# SDC Constraints for Asynchronous FIFO with Modular Synchronizers
# This file defines timing constraints for proper CDC handling

#==============================================================================
# Clock Definitions
#==============================================================================

# Define write clock (example: 100 MHz)
create_clock -name wr_clk -period 10.0 [get_ports wr_clk]

# Define read clock (example: 125 MHz) 
create_clock -name rd_clk -period 8.0 [get_ports rd_clk]

# Mark clocks as asynchronous to each other
set_clock_groups -asynchronous \
    -group [get_clocks wr_clk] \
    -group [get_clocks rd_clk]

#==============================================================================
# Input/Output Delays
#==============================================================================

# Write interface input delays (relative to wr_clk)
set_input_delay -clock wr_clk -max 2.0 [get_ports {wr_en wr_data[*]}]
set_input_delay -clock wr_clk -min 0.5 [get_ports {wr_en wr_data[*]}]

# Read interface input delays (relative to rd_clk)
set_input_delay -clock rd_clk -max 2.0 [get_ports rd_en]
set_input_delay -clock rd_clk -min 0.5 [get_ports rd_en]

# Write interface output delays (relative to wr_clk)
set_output_delay -clock wr_clk -max 2.0 [get_ports wr_full]
set_output_delay -clock wr_clk -min 0.5 [get_ports wr_full]

# Read interface output delays (relative to rd_clk)
set_output_delay -clock rd_clk -max 2.0 [get_ports {rd_data[*] rd_empty}]
set_output_delay -clock rd_clk -min 0.5 [get_ports {rd_data[*] rd_empty}]

#==============================================================================
# False Path Constraints for CDC Signals (Modular Synchronizers)
#==============================================================================

# Gray code pointer crossing from write to read domain
# False path from source to first synchronizer stage
set_false_path -from [get_cells -hier -filter {NAME =~ *wr_ptr_gray_reg[*]}] \
               -to   [get_cells -hier -filter {NAME =~ *u_wr_ptr_sync/sync_chain_reg[0][*]}]

# Gray code pointer crossing from read to write domain  
# False path from source to first synchronizer stage
set_false_path -from [get_cells -hier -filter {NAME =~ *rd_ptr_gray_reg[*]}] \
               -to   [get_cells -hier -filter {NAME =~ *u_rd_ptr_sync/sync_chain_reg[0][*]}]

#==============================================================================
# Max Delay Constraints for CDC Paths
#==============================================================================

# Constrain the CDC path for write pointer Gray code bits
# Allow sufficient time for metastability resolution (use slower clock period)
set_max_delay -from [get_cells -hier -filter {NAME =~ *wr_ptr_gray_reg[*]}] \
              -to   [get_cells -hier -filter {NAME =~ *u_wr_ptr_sync/sync_chain_reg[0][*]}] \
              -datapath_only 8.0

# Constrain the CDC path for read pointer Gray code bits
set_max_delay -from [get_cells -hier -filter {NAME =~ *rd_ptr_gray_reg[*]}] \
              -to   [get_cells -hier -filter {NAME =~ *u_rd_ptr_sync/sync_chain_reg[0][*]}] \
              -datapath_only 10.0

#==============================================================================
# Reset Constraints
#==============================================================================

# Asynchronous reset paths - no timing requirements
set_false_path -from [get_ports wr_rst_n] -to [all_registers]
set_false_path -from [get_ports rd_rst_n] -to [all_registers]

#==============================================================================
# Metastability Analysis Settings for Synchronizer Module
#==============================================================================

# Mark all synchronizer chain registers for metastability analysis
# This applies to all stages in the multibit_sync modules

# Synchronizer in write clock domain (rd_ptr_sync)
set_property ASYNC_REG TRUE [get_cells -hier -filter {NAME =~ *u_rd_ptr_sync/sync_chain_reg[*][*]}]

# Synchronizer in read clock domain (wr_ptr_sync)
set_property ASYNC_REG TRUE [get_cells -hier -filter {NAME =~ *u_wr_ptr_sync/sync_chain_reg[*][*]}]

# Additional metastability protection attributes
set_property KEEP TRUE [get_cells -hier -filter {NAME =~ *u_rd_ptr_sync/sync_chain_reg[*][*]}]
set_property KEEP TRUE [get_cells -hier -filter {NAME =~ *u_wr_ptr_sync/sync_chain_reg[*][*]}]

set_property DONT_TOUCH TRUE [get_cells -hier -filter {NAME =~ *u_rd_ptr_sync/sync_chain_reg[*][*]}]
set_property DONT_TOUCH TRUE [get_cells -hier -filter {NAME =~ *u_wr_ptr_sync/sync_chain_reg[*][*]}]

#==============================================================================
# Synchronizer Placement Constraints (Optional but Recommended)
#==============================================================================

# Keep synchronizer flip-flops close together to minimize routing delay
# This reduces the chance of metastability propagation

# For Xilinx:
# set_property LOC SLICE_X0Y0 [get_cells -hier u_rd_ptr_sync/sync_chain_reg[0][*]]
# set_property LOC SLICE_X0Y1 [get_cells -hier u_rd_ptr_sync/sync_chain_reg[1][*]]

# For placement groups (more flexible):
# create_pblock pblock_rd_sync
# add_cells_to_pblock pblock_rd_sync [get_cells -hier u_rd_ptr_sync]
# resize_pblock pblock_rd_sync -add {SLICE_X0Y0:SLICE_X5Y5}

#==============================================================================
# Report Commands for Verification
#==============================================================================

# Use these commands after running timing analysis to verify constraints

# Report on clock domain crossings
# report_cdc

# Report on synchronizer chains
# report_synchronizer_chain

# Report timing on CDC paths
# report_timing -from [get_cells -hier *_gray_reg[*]] -to [get_cells -hier *sync_chain_reg[0][*]]

# Report metastability MTBF
# report_methodology

#==============================================================================
# Tool-Specific Synchronizer Identification
#==============================================================================

# Xilinx Vivado (using attributes in RTL and properties above)
# The ASYNC_REG attribute in the multibit_sync module handles this

# Intel Quartus Prime
# set_instance_assignment -name SYNCHRONIZER_IDENTIFICATION "FORCED IF ASYNCHRONOUS" \
#     -to [get_registers {*u_rd_ptr_sync|sync_chain[*][*]}]
# set_instance_assignment -name SYNCHRONIZER_IDENTIFICATION "FORCED IF ASYNCHRONOUS" \
#     -to [get_registers {*u_wr_ptr_sync|sync_chain[*][*]}]

# Synopsys Design Compiler
# set_dont_touch [get_cells -hier *u_rd_ptr_sync/sync_chain_reg*]
# set_dont_touch [get_cells -hier *u_wr_ptr_sync/sync_chain_reg*]

#==============================================================================
# Additional Best Practices
#==============================================================================

# 1. Verify MTBF (Mean Time Between Failures) meets requirements
#    - Typical target: > 1000 years
#    - MTBF depends on: clock frequency, synchronizer stages, and flip-flop characteristics

# 2. Ensure synchronizer registers are not optimized away
#    - Use KEEP, DONT_TOUCH attributes
#    - Verify in synthesis/implementation reports

# 3. Check that Gray code is correctly implemented
#    - Only one bit should change per clock cycle
#    - Verify in simulation

# 4. Review floorplanning
#    - Keep synchronizers physically close
#    - Minimize routing delays

# 5. Run CDC analysis tools
#    - Synopsys SpyGlass CDC
#    - Cadence Conformal CDC
#    - Built-in tools in Vivado/Quartus
