proc start_step { step } {
  set stopFile ".stop.rst"
  if {[file isfile .stop.rst]} {
    puts ""
    puts "*** Halting run - EA reset detected ***"
    puts ""
    puts ""
    return -code error
  }
  set beginFile ".$step.begin.rst"
  set platform "$::tcl_platform(platform)"
  set user "$::tcl_platform(user)"
  set pid [pid]
  set host ""
  if { [string equal $platform unix] } {
    if { [info exist ::env(HOSTNAME)] } {
      set host $::env(HOSTNAME)
    }
  } else {
    if { [info exist ::env(COMPUTERNAME)] } {
      set host $::env(COMPUTERNAME)
    }
  }
  set ch [open $beginFile w]
  puts $ch "<?xml version=\"1.0\"?>"
  puts $ch "<ProcessHandle Version=\"1\" Minor=\"0\">"
  puts $ch "    <Process Command=\".planAhead.\" Owner=\"$user\" Host=\"$host\" Pid=\"$pid\">"
  puts $ch "    </Process>"
  puts $ch "</ProcessHandle>"
  close $ch
}

proc end_step { step } {
  set endFile ".$step.end.rst"
  set ch [open $endFile w]
  close $ch
}

proc step_failed { step } {
  set endFile ".$step.error.rst"
  set ch [open $endFile w]
  close $ch
}

set_msg_config -id {HDL 9-1061} -limit 100000
set_msg_config -id {HDL 9-1654} -limit 100000

start_step init_design
set rc [catch {
  create_msg_db init_design.pb
  debug::add_scope template.lib 1
  create_project -in_memory -part xc7z010clg400-1
  set_property board_part digilentinc.com:zybo:part0:1.0 [current_project]
  set_property design_mode GateLvl [current_fileset]
  set_property webtalk.parent_dir C:/xup/embedded/lab8_part1_zsy/lab8_part1_zsy.cache/wt [current_project]
  set_property parent.project_path C:/xup/embedded/lab8_part1_zsy/lab8_part1_zsy.xpr [current_project]
  set_property ip_repo_paths c:/xup/embedded/lab8_part1_zsy/lab8_part1_zsy.cache/ip [current_project]
  set_property ip_output_repo c:/xup/embedded/lab8_part1_zsy/lab8_part1_zsy.cache/ip [current_project]
  add_files -quiet C:/xup/embedded/lab8_part1_zsy/lab8_part1_zsy.runs/synth_1/lab8_part1_wrapper.dcp
  read_xdc -ref lab8_part1_processing_system7_0_0 -cells inst c:/xup/embedded/lab8_part1_zsy/lab8_part1_zsy.srcs/sources_1/bd/lab8_part1/ip/lab8_part1_processing_system7_0_0/lab8_part1_processing_system7_0_0.xdc
  set_property processing_order EARLY [get_files c:/xup/embedded/lab8_part1_zsy/lab8_part1_zsy.srcs/sources_1/bd/lab8_part1/ip/lab8_part1_processing_system7_0_0/lab8_part1_processing_system7_0_0.xdc]
  read_xdc C:/xup/embedded/lab8_part1_zsy/lab8_part1_zsy.srcs/constrs_1/new/lab8Constrian.xdc
  link_design -top lab8_part1_wrapper -part xc7z010clg400-1
  close_msg_db -file init_design.pb
} RESULT]
if {$rc} {
  step_failed init_design
  return -code error $RESULT
} else {
  end_step init_design
}

start_step opt_design
set rc [catch {
  create_msg_db opt_design.pb
  catch {write_debug_probes -quiet -force debug_nets}
  opt_design 
  write_checkpoint -force lab8_part1_wrapper_opt.dcp
  catch {report_drc -file lab8_part1_wrapper_drc_opted.rpt}
  close_msg_db -file opt_design.pb
} RESULT]
if {$rc} {
  step_failed opt_design
  return -code error $RESULT
} else {
  end_step opt_design
}

start_step place_design
set rc [catch {
  create_msg_db place_design.pb
  catch {write_hwdef -file lab8_part1_wrapper.hwdef}
  place_design 
  write_checkpoint -force lab8_part1_wrapper_placed.dcp
  catch { report_io -file lab8_part1_wrapper_io_placed.rpt }
  catch { report_utilization -file lab8_part1_wrapper_utilization_placed.rpt -pb lab8_part1_wrapper_utilization_placed.pb }
  catch { report_control_sets -verbose -file lab8_part1_wrapper_control_sets_placed.rpt }
  close_msg_db -file place_design.pb
} RESULT]
if {$rc} {
  step_failed place_design
  return -code error $RESULT
} else {
  end_step place_design
}

start_step route_design
set rc [catch {
  create_msg_db route_design.pb
  route_design 
  write_checkpoint -force lab8_part1_wrapper_routed.dcp
  catch { report_drc -file lab8_part1_wrapper_drc_routed.rpt -pb lab8_part1_wrapper_drc_routed.pb }
  catch { report_timing_summary -warn_on_violation -max_paths 10 -file lab8_part1_wrapper_timing_summary_routed.rpt -rpx lab8_part1_wrapper_timing_summary_routed.rpx }
  catch { report_power -file lab8_part1_wrapper_power_routed.rpt -pb lab8_part1_wrapper_power_summary_routed.pb }
  catch { report_route_status -file lab8_part1_wrapper_route_status.rpt -pb lab8_part1_wrapper_route_status.pb }
  catch { report_clock_utilization -file lab8_part1_wrapper_clock_utilization_routed.rpt }
  close_msg_db -file route_design.pb
} RESULT]
if {$rc} {
  step_failed route_design
  return -code error $RESULT
} else {
  end_step route_design
}

start_step write_bitstream
set rc [catch {
  create_msg_db write_bitstream.pb
  write_bitstream -force lab8_part1_wrapper.bit 
  catch { write_sysdef -hwdef lab8_part1_wrapper.hwdef -bitfile lab8_part1_wrapper.bit -meminfo lab8_part1_wrapper.mmi -ltxfile debug_nets.ltx -file lab8_part1_wrapper.sysdef }
  close_msg_db -file write_bitstream.pb
} RESULT]
if {$rc} {
  step_failed write_bitstream
  return -code error $RESULT
} else {
  end_step write_bitstream
}

