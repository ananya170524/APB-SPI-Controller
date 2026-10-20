//APB SPI TOP LEVEL MODULE
module APB_SPI_Top(
    input PCLK,
    input PRESET_n,

    input PSEL,
    input PENABLE,
    input PWRITE,

    input miso,

    input [2:0] PADDR,
    input [7:0] PWDATA,

    output [7:0] PRDATA,
    output PREADY,
    output PSLVERR,

    output sclk,
    output ss,
    output mosi,
    output spi_interrupt_request
);

// APB Configuration Registers
wire mstr;
wire cpol;
wire cpha;
wire lsbfe;
wire spiswai;

wire [2:0] sppr;
wire [2:0] spr;
wire [1:0] spi_mode;

// Data Path
wire send_data;
wire receive_data;

wire [7:0] data_mosi;
wire [7:0] data_miso;

// Baud Generator
wire [11:0] BaudRateDivisor;

wire miso_receive_sclk;
wire miso_receive_sclk0;
wire mosi_send_sclk;
wire mosi_send_sclk0;

// Slave Select
wire tip;

spi_baud_generator A1 (
    .PCLK(PCLK),
    .PRESET_n(PRESET_n),

    .spi_mode_i(spi_mode),
    .spiswai_i(spiswai),

    .sppr_i(sppr),
    .spr_i(spr),

    .cpol_i(cpol),
    .cpha_i(cpha),
    .ss_i(ss),

    .sclk_o(sclk),

    .miso_receive_sclk_o(miso_receive_sclk),
    .miso_receive_sclk0_o(miso_receive_sclk0),

    .mosi_send_sclk_o(mosi_send_sclk),
    .mosi_send_sclk0_o(mosi_send_sclk0),

    .BaudRateDivisor_o(BaudRateDivisor)
);

spi_slave_select B1 (
    .PCLK(PCLK),
    .PRESET_n(PRESET_n),

    .mstr_i(mstr),
    .spiswai_i(spiswai),
    .spi_mode_i(spi_mode),
    .send_data_i(send_data),

    .BaudRateDivisor_i(BaudRateDivisor),

    .receive_data_o(receive_data),
    .ss_o(ss),
    .tip_o(tip)
);

spi_shift_register C1 (
    .PCLK(PCLK),
    .PRESET_n(PRESET_n),

    .ss_i(ss),
    .send_data_i(send_data),

    .lsbfe_i(lsbfe),
    .cpha_i(cpha),
    .cpol_i(cpol),

    .miso_receive_sclk_i(miso_receive_sclk),
    .miso_receive_sclk0_i(miso_receive_sclk0),

    .mosi_send_sclk_i(mosi_send_sclk),
    .mosi_send_sclk0_i(mosi_send_sclk0),

    .data_mosi_i(data_mosi),

    .miso_i(miso),

    .receive_data_i(receive_data),

    .mosi_o(mosi),
    .data_miso_o(data_miso)
);

APB_slave_interface D1 (
    .PCLK(PCLK),
    .PRESET_n(PRESET_n),

    .PADDR_i(PADDR),
    .PWRITE_i(PWRITE),
    .PSEL_i(PSEL),
    .PENABLE_i(PENABLE),
    .PWDATA_i(PWDATA),

    .ss_i(ss),

    .miso_data_i(data_miso),

    .receive_data_i(receive_data),
    .tip_i(tip),

    .PRDATA_o(PRDATA),

    .mstr_o(mstr),
    .cpol_o(cpol),
    .cpha_o(cpha),
    .lsbfe_o(lsbfe),
    .spiswai_o(spiswai),

    .sppr_o(sppr),
    .spr_o(spr),

    .spi_interrupt_request_o(spi_interrupt_request),

    .PREADY_o(PREADY),
    .PSLVERR_o(PSLVERR),

    .send_data_o(send_data),
    .mosi_data_o(data_mosi),

    .spi_mode_o(spi_mode)
);

endmodule
