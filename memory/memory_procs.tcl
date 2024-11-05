#source [find ps7_init.tcl]
proc mrd {addr} {
    set cur_target [target current]
    set value [$cur_target read_memory $addr 32 1]
    set correctedValue [correct_value $value]
    return $correctedValue
}

proc mwr {args} {
    set force [lindex $args 0]
    set addr [lindex $args 1]
    set val [lindex $args 2]
    if {$force == "-force"} {
    } else {
    	set val [format "%08x" $addr]
    	set addr [format "%08x" $force]
    } 
    set numericAddr [scan $addr %x]
    set numericVal [scan $val %x]
    set cur_target [target current]
    $cur_target write_memory $numericAddr 32 $numericVal
}

proc mask_write {addr mask data} {
    set numericAddr [scan $addr %x]
    set numericMask [scan $mask %x]
    set numericData [scan $data %x]
    set cur_target [target current]
    set curVal [$cur_target read_memory $addr 32 1]
    set newVal [expr {($curVal & ~$numericMask) | ($numericData & $numericMask)}]
    $cur_target write_memory $addr 32 $newVal
}

proc correct_value {value} {
    regsub -all {0x} $value "" correctedValue
    return $correctedValue
}

proc configparams {args} {
    
}

proc target_initialization {} {
    targets zynq.cpu0
    halt
    poll off 
    ps7_debug
    ps7_init
    ps7_post_config
    poll on 
}

proc run_project {bitstream_path program_path program_counter bit_speed init_speed elf_speed} { 
    init_reset halt 
    
    # After trial and error, the bitstream can be uploaded using 
    # the maximum allowed frequency by the adapter.
    poll off
    adapter speed $bit_speed
    "pld load" zynq_pl.pld $bitstream_path
    poll on
    puts "Bitstream Uploaded"
    adapter speed $init_speed
    #targets zynq.cpu0
    
    # In contrast this is the maximum available frequency for detecting 
    # the targets and loading.  
    
    target_initialization
    adapter speed $elf_speed
    load_image $program_path
    puts "Image Uploaded"
    
    zynq.cpu0 set_reg {pc $program_counter}
    puts "Programming Successfull"
    resume $program_counter
    exit
}
