onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /udp_parser_tb/DUT/clk
add wave -noupdate -radix hexadecimal /udp_parser_tb/DUT/reset
add wave -noupdate -radix hexadecimal /udp_parser_tb/DUT/s_axis_tdata
add wave -noupdate -radix hexadecimal /udp_parser_tb/DUT/s_axis_tvalid
add wave -noupdate -radix hexadecimal /udp_parser_tb/DUT/s_axis_tlast
add wave -noupdate -radix hexadecimal /udp_parser_tb/DUT/s_axis_tready
add wave -noupdate -radix hexadecimal /udp_parser_tb/DUT/dst_mac
add wave -noupdate -radix hexadecimal /udp_parser_tb/DUT/src_mac
add wave -noupdate -radix hexadecimal /udp_parser_tb/DUT/dst_ip
add wave -noupdate -radix hexadecimal /udp_parser_tb/DUT/src_ip
add wave -noupdate -radix hexadecimal /udp_parser_tb/DUT/dst_port
add wave -noupdate -radix hexadecimal /udp_parser_tb/DUT/src_port
add wave -noupdate -radix hexadecimal /udp_parser_tb/DUT/payload_length
add wave -noupdate -radix hexadecimal /udp_parser_tb/DUT/parsing_done
add wave -noupdate -radix hexadecimal /udp_parser_tb/DUT/shreg
add wave -noupdate -radix hexadecimal /udp_parser_tb/DUT/valid_pipe
add wave -noupdate -radix hexadecimal /udp_parser_tb/DUT/frame_ok
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {502333 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 278
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {838384 ps} {1222112 ps}
