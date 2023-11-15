
// Efinity Top-level template
// Version: 2023.1.150.1.5
// Date: 2023-11-11 14:14

// Copyright (C) 2017 - 2023 Efinix Inc. All rights reserved.

// This file may be used as a starting point for Efinity synthesis top-level target.
// The port list here matches what is expected by Efinity constraint files generated
// by the Efinity Interface Designer.

// To use this:
//     #1)  Save this file with a different name to a different directory, where source files are kept.
//              Example: you may wish to save as F:\FPGA_PRJ\YLS\inf_riscv_interconnect_v6_2_test\efinity_project\DDR3_MC.v
//     #2)  Add the newly saved file into Efinity project as design file
//     #3)  Edit the top level entity in Efinity project to:  DDR3_MC
//     #4)  Insert design content.


module DDR3_MC
(
  input inf_in,
  input nrst,
  input [3:0] system_gpio_0_io_read,
  input system_uart_0_io_rxd,
  input DDR3_PLL_CLKOUT4,
  input DDR3_PLL_LOCK,
  input SYS_PLL_LOCK,
  input hdmi_rx_pll_LOCKED,
  input hdmi_tx_pll_LOCKED,
  input twd_clk,
  input tac_clk,
  input tdqss_clk,
  input sys_clk,
  input clk_10m,
  input core_clk,
  input hdmi_tx_slow_clk,
  input pll_inst4_CLKOUT0,
  input hdmi_tx_fast_clk,
  input clk_25m,
  input i_sysclk_div_2,
  input fb,
  input clk_125m,
  input hdmi_rx_fast_clk,
  input osc_clk,
  input hdmi_rx_slow_clk,
  input jtag_inst1_CAPTURE,
  input jtag_inst1_SEL,
  input jtag_inst1_SHIFT,
  input jtag_inst1_TCK,
  input jtag_inst1_TDI,
  input hdmi_rx_clk_RX_DATA,
  input [9:0] hdmi_rx_d0_RX_DATA,
  input [9:0] hdmi_rx_d1_RX_DATA,
  input [9:0] hdmi_rx_d2_RX_DATA,
  input FPGA_HDMI_SCL_IN,
  input FPGA_HDMI_SDA_IN,
  input HDMI_5V_N,
  input [15:0] i_dq_hi,
  input [15:0] i_dq_lo,
  input [1:0] i_dqs_hi,
  input [1:0] i_dqs_lo,
  input hdmi_tx_clk,
  input system_spi_0_io_data_0_read,
  input system_spi_0_io_data_1_read,
  output beep,
  output [3:0] system_gpio_0_io_write,
  output [3:0] system_gpio_0_io_writeEnable,
  output system_uart_0_io_txd,
  output DDR3_PLL_RSTN,
  output [2:0] shift,
  output shift_ena,
  output [4:0] shift_sel,
  output SYS_PLL_RSTN,
  output hdmi_rx_pll_RSTN,
  output hdmi_tx_pll_RSTN,
  output jtag_inst1_TDO,
  output hdmi_rx_clk_RX_ENA,
  output hdmi_rx_d0_RX_RST,
  output hdmi_rx_d0_RX_ENA,
  output hdmi_rx_d1_RX_RST,
  output hdmi_rx_d1_RX_ENA,
  output hdmi_rx_d2_RX_RST,
  output hdmi_rx_d2_RX_ENA,
  output tmds_tx_clk_TX_OE,
  output [9:0] tmds_tx_clk_TX_DATA,
  output tmds_tx_clk_TX_RST,
  output tmds_tx_data0_TX_OE,
  output [9:0] tmds_tx_data0_TX_DATA,
  output tmds_tx_data0_TX_RST,
  output tmds_tx_data1_TX_OE,
  output [9:0] tmds_tx_data1_TX_DATA,
  output tmds_tx_data1_TX_RST,
  output tmds_tx_data2_TX_OE,
  output [9:0] tmds_tx_data2_TX_DATA,
  output tmds_tx_data2_TX_RST,
  output FPGA_HDMI_SCL_OUT,
  output FPGA_HDMI_SCL_OE,
  output FPGA_HDMI_SDA_OUT,
  output FPGA_HDMI_SDA_OE,
  output HPD_N,
  output [15:0] addr,
  output [2:0] ba,
  output cas,
  output cke,
  output cs,
  output [1:0] o_dm_hi,
  output [1:0] o_dm_lo,
  output [15:0] o_dq_hi,
  output [15:0] o_dq_lo,
  output [15:0] o_dq_oe,
  output [1:0] o_dqs_hi,
  output [1:0] o_dqs_lo,
  output [1:0] o_dqs_oe,
  output [1:0] o_dqs_n_oe,
  output odt,
  output ras,
  output reset,
  output system_spi_0_io_data_0_write,
  output system_spi_0_io_data_0_writeEnable,
  output system_spi_0_io_data_1_write,
  output system_spi_0_io_data_1_writeEnable,
  output system_spi_0_io_sclk_write,
  output system_spi_0_io_ss,
  output we,
  output osc_en
);


endmodule

