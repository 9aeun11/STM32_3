# Vivado 프로젝트 생성 스크립트 (STM32_3 · fpga_spi_rx)
# 사용법 1) Vivado Tcl Console:  cd <이 폴더의 상위 폴더>; source tools/create_vivado_project.tcl
# 사용법 2) 명령창:              vivado -mode batch -source tools/create_vivado_project.tcl -tclargs bit
#   -tclargs bit 를 주면 합성·구현·비트스트림까지 실행한다.
set project_root [file normalize [file join [file dirname [info script]] ..]]
set proj_dir     [file join $project_root vivado]
set proj_name    spi_rx
set design_top   spi_rx_top
set sim_top      tb_spi_rx

create_project -force $proj_name $proj_dir -part xc7s75fgga484-1
set_property target_language Verilog [current_project]
add_files -norecurse [glob [file join $project_root src *.v]]
add_files -fileset sim_1 -norecurse [glob [file join $project_root sim *.v]]
add_files -fileset constrs_1 -norecurse [glob [file join $project_root constraints *.xdc]]
set_property top $design_top [get_filesets sources_1]
set_property top $sim_top    [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "Vivado 프로젝트 생성: [file join $proj_dir $proj_name.xpr]"

if {[lsearch $argv bit] >= 0} {
    launch_runs synth_1 -jobs 4
    wait_on_run synth_1
    launch_runs impl_1 -to_step write_bitstream -jobs 4
    wait_on_run impl_1
    if {[get_property STATUS [get_runs impl_1]] ne "write_bitstream Complete!"} {
        error "구현 실패: [get_property STATUS [get_runs impl_1]]"
    }
    set bit [glob [file join $proj_dir $proj_name.runs impl_1 *.bit]]
    file copy -force $bit [file join $project_root $design_top.bit]
    puts "비트스트림: [file join $project_root $design_top.bit]"
}
