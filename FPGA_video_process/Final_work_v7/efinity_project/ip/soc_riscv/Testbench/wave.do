onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_soc/io_systemClk
add wave -noupdate /tb_soc/io_memoryClk
add wave -noupdate /tb_soc/systemClk_locked
add wave -noupdate /tb_soc/memoryClk_locked
add wave -noupdate /tb_soc/systemClk_rstn
add wave -noupdate /tb_soc/memoryClk_rstn
add wave -noupdate /tb_soc/rst
add wave -noupdate /tb_soc/systemClk_rst
add wave -noupdate /tb_soc/memoryClk_rst
add wave -noupdate -divider {New Divider}
add wave -noupdate /tb_soc/system_spi_0_io_ss
add wave -noupdate /tb_soc/system_spi_0_io_sclk_write
add wave -noupdate /tb_soc/system_spi_0_io_data_0
add wave -noupdate /tb_soc/system_spi_0_io_data_1
add wave -noupdate -divider {New Divider}
add wave -noupdate /tb_soc/system_uart_0_io_txd
add wave -noupdate /tb_soc/system_uart_0_io_rxd
add wave -noupdate -divider {New Divider}
add wave -noupdate /tb_soc/memoryCheckerPass
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {19014488 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 296
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {0 ps} {559949250 ps}
