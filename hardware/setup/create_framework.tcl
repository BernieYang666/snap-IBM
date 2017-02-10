#-----------------------------------------------------------
#
# Copyright 2016, International Business Machines
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#-----------------------------------------------------------

set root_dir    $::env(DONUT_HARDWARE_ROOT)
set fpga_part   $::env(FPGACHIP)
set pslse_dir   $::env(PSLSE_ROOT)
set dimm_dir    $::env(DIMMTEST)
set build_dir   $::env(DONUT_HARDWARE_ROOT)/build
set ip_dir      $root_dir/ip
set action_dir  $::env(ACTION_ROOT)
set ddri_used   $::env(DDRI_USED)
set ddr3_used   $::env(DDR3_USED)
set ddr4_used   $::env(DDR4_USED)
set bram_used   $::env(BRAM_USED)
set simulator   $::env(SIMULATOR)
set vivadoVer   [version -short]

#debug information
#puts $root_dir
#puts $pslse_dir
#puts $build_dir
#puts $vivadoVer
#puts $simulator

# Create a new Vivado Project
exec rm -rf $root_dir/viv_project
create_project framework $root_dir/viv_project -part $fpga_part -force 

# Project Settings
# General
set_property target_language VHDL [current_project]
set_property default_lib work [current_project]
# Simulation
if { ( $simulator == "ncsim" ) || ( $simulator == "irun" ) } {
  set_property target_simulator IES [current_project]
  set_property top top [get_filesets sim_1]
  set_property compxlib.ies_compiled_library_dir $::env(IES_LIBS) [current_project]
  set_property -name {ies.elaborate.ncelab.more_options} -value {-access +rwc} -objects [current_fileset -simset]
} else {
  set_property -name {xsim.elaborate.xelab.more_options} -value {-sv_lib libdpi -sv_root .} -objects [current_fileset -simset]
}
set_property export.sim.base_dir $root_dir [current_project]
# Synthesis
set_property STEPS.SYNTH_DESIGN.ARGS.FANOUT_LIMIT 400 [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FSM_EXTRACTION one_hot [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING off [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.SHREG_MIN_SIZE 5 [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS true [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.NO_LC true [get_runs synth_1]
# Project
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
# Bitstream
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

# Add Files
# PSL Files
add_files -norecurse -scan_for_includes $build_dir/Sources/top/std_ulogic_support.vhdl
add_files -norecurse -scan_for_includes $build_dir/Sources/top/psl_fpga.vhdl
add_files -norecurse -scan_for_includes $build_dir/Sources/top/std_ulogic_function_support.vhdl
add_files -norecurse -scan_for_includes $build_dir/Sources/top/std_ulogic_unsigned.vhdl
add_files -norecurse -scan_for_includes $build_dir/Sources/top/synthesis_support.vhdl
set_property library ibm              [get_files $build_dir/Sources/top/synthesis_support.vhdl]
set_property used_in_simulation false [get_files $root_dir/build/Sources/top/psl_fpga.vhdl]
# HDL Files
add_files -scan_for_includes $root_dir/hdl/
set_property used_in_simulation false [get_files  $root_dir/hdl/psl_accel_syn.vhd]
remove_files  $root_dir/hdl/psl_accel_sim.vhd
# Action Files
add_files            -fileset sources_1 -scan_for_includes $action_dir/
# Sim Files
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files    -fileset sim_1 -norecurse -scan_for_includes $pslse_dir/afu_driver/verilog/top.v
add_files    -fileset sim_1 -norecurse -scan_for_includes $root_dir/hdl/psl_accel_sim.vhd
set_property file_type SystemVerilog [get_files $pslse_dir/afu_driver/verilog/top.v]
set_property used_in_synthesis false [get_files $pslse_dir/afu_driver/verilog/top.v]
set_property used_in_synthesis false [get_files  $root_dir/hdl/psl_accel_sim.vhd]
# DDR3 Sim Files
if { $ddr3_used == TRUE } {
  add_files    -fileset sim_1            -scan_for_includes $dimm_dir/fpga/lib/ddr3_sdram_model-v1_1_0/src/
  remove_files -fileset sim_1                               $dimm_dir/fpga/lib/ddr3_sdram_model-v1_1_0/src/ddr3_sdram_twindie.vhd
  remove_files -fileset sim_1                               $dimm_dir/fpga/lib/ddr3_sdram_model-v1_1_0/src/ddr3_sdram_lwb.vhd
}
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Add IPs
# Donut IPs
add_files -norecurse $root_dir/ip/ram_520x64_2p/ram_520x64_2p.xci
export_ip_user_files -of_objects  [get_files "$root_dir/ip/ram_520x64_2p/ram_520x64_2p.xci"] -force -quiet
add_files -norecurse $root_dir/ip/ram_584x64_2p/ram_584x64_2p.xci
export_ip_user_files -of_objects  [get_files "$root_dir/ip/ram_584x64_2p/ram_584x64_2p.xci"] -force -quiet
add_files -norecurse  $root_dir/ip/fifo_513x512/fifo_513x512.xci
export_ip_user_files -of_objects  [get_files  "$root_dir/ip/fifo_513x512/fifo_513x512.xci"] -force -quiet
# DDR3 / BRAM IPs
if { $ddri_used == TRUE } {
  add_files -norecurse $root_dir/ip/axi_clock_converter/axi_clock_converter.xci
  export_ip_user_files -of_objects  [get_files "$root_dir/ip/axi_clock_converter/axi_clock_converter.xci"] -force -quiet
  if { $bram_used == TRUE } {
    add_files -norecurse $root_dir/ip/block_RAM/block_RAM.xci
    export_ip_user_files -of_objects  [get_files "$root_dir/ip/block_RAM/block_RAM.xci"] -force -quiet
  } elseif { $ddr3_used == TRUE } {
    add_files -norecurse $root_dir/ip/ddr3sdram/ddr3sdram.xci
    export_ip_user_files -of_objects  [get_files "$root_dir/ip/ddr3sdram/ddr3sdram.xci"] -force -quiet
  } elseif { $ddr4_used == TRUE } {
#    open_example_project -force -dir $ip_dir     [get_ips ddr4sdram]
#    close project
    add_files -norecurse $root_dir/ip/ddr4sdram/ddr4sdram.xci
    export_ip_user_files -of_objects  [get_files "$root_dir/ip/ddr4sdram/ddr4sdram.xci"] -force -quiet
  } else {
    puts "no DDR RAM was specified"
    exit
  }
}
update_compile_order -fileset sources_1

# Add PSL
read_checkpoint -cell b $build_dir/Checkpoint/b_route_design.dcp -strict

# XDC
# Donut XDC
#add_files -fileset constrs_1 -norecurse $root_dir/setup/donut_synth.xdc
#set_property used_in_implementation false [get_files   $root_dir/setup/donut_synth.xdc]
add_files -fileset constrs_1 -norecurse $root_dir/setup/donut_link.xdc
set_property used_in_synthesis false [get_files  $root_dir/setup/donut_link.xdc]
update_compile_order -fileset sources_1
# DDR XDCs
if { $ddri_used == TRUE } {
  if { $ddr3_used == TRUE } {
    add_files -fileset constrs_1 -norecurse $dimm_dir/example/dimm_test-admpcieku3-v3_0_0/fpga/src/refclk200.xdc
    if { $bram_used == FALSE } {
#      add_files -fileset constrs_1 -norecurse $dimm_dir/example/dimm_test-admpcieku3-v3_0_0/fpga/src/ddr3sdram_dm_b0_x72ecc.xdc
#      set_property used_in_synthesis false [get_files $dimm_dir/example/dimm_test-admpcieku3-v3_0_0/fpga/src/ddr3sdram_dm_b0_x72ecc.xdc]
#      add_files -fileset constrs_1 -norecurse $dimm_dir/example/dimm_test-admpcieku3-v3_0_0/fpga/src/ddr3sdram_locs_b0_8g_x72ecc.xdc
#      set_property used_in_synthesis false [get_files $dimm_dir/example/dimm_test-admpcieku3-v3_0_0/fpga/src/ddr3sdram_locs_b0_8g_x72ecc.xdc]
      add_files -fileset constrs_1 -norecurse $dimm_dir/example/dimm_test-admpcieku3-v3_0_0/fpga/src/ddr3sdram_dm_b1_x72ecc.xdc
      set_property used_in_synthesis false [get_files $dimm_dir/example/dimm_test-admpcieku3-v3_0_0/fpga/src/ddr3sdram_dm_b1_x72ecc.xdc]
      add_files -fileset constrs_1 -norecurse $dimm_dir/example/dimm_test-admpcieku3-v3_0_0/fpga/src/ddr3sdram_locs_b1_8g_x72ecc.xdc
      set_property used_in_synthesis false [get_files $dimm_dir/example/dimm_test-admpcieku3-v3_0_0/fpga/src/ddr3sdram_locs_b1_8g_x72ecc.xdc]
    }
  } elseif { $ddr4_used == TRUE } {
    add_files -fileset constrs_1 -norecurse $dimm_dir/snap_refclk200.xdc
    add_files -fileset constrs_1 -norecurse $dimm_dir/snap_ddr4pins_flash_gt.xdc
    set_property used_in_synthesis false [get_files $dimm_dir/snap_ddr4pins_flash_gt.xdc]

  } else {
    puts "no DDR RAM was specified"
    exit
  }
}

# EXPORT SIMULATION for xsim
if { [string equal -length 4 2016 $vivadoVer] > 0 } {
  puts "export_simulation 2016 syntax"
  export_simulation  -force -directory "$root_dir/sim" -simulator xsim -ip_user_files_dir "$root_dir/viv_project/framework.ip_user_files" -ipstatic_source_dir "$root_dir/viv_project/framework.ip_user_files/ipstatic" -use_ip_compiled_libs
} else {
  puts "export_simulation 2015 syntax"
  export_simulation  -force -directory "$root_dir/sim" -simulator xsim
}

close_project
