// APB SPI TOP LEVEL MODULE TESTBENCH
module APB_SPI_Top_tb();

reg PCLK;
reg PRESET_n;

reg PSEL;
reg PENABLE;
reg PWRITE;

reg miso;

reg [2:0] PADDR;
reg [7:0] PWDATA;

wire [7:0] PRDATA;
wire PREADY;
wire PSLVERR;

wire sclk;
wire ss;
wire mosi;
wire spi_interrupt_request;

integer i;

APB_SPI_Top DUT (
    .PCLK(PCLK),
    .PRESET_n(PRESET_n),

    .PSEL(PSEL),
    .PENABLE(PENABLE),
    .PWRITE(PWRITE),

    .miso(miso),

    .PADDR(PADDR),
    .PWDATA(PWDATA),

    .PRDATA(PRDATA),
    .PREADY(PREADY),
    .PSLVERR(PSLVERR),

    .sclk(sclk),
    .ss(ss),
    .mosi(mosi),

    .spi_interrupt_request(spi_interrupt_request)
);
//clock generation
initial
    PCLK = 1'b0;

always
    #5 PCLK = ~PCLK;

//task reset
task reset;
begin
    PRESET_n = 1'b0;
    #15;
    PRESET_n = 1'b1;
end
endtask

//miso lsb first task
task miso_bits_lsb(input [7:0] miso_data);
begin
    wait(~ss);

    for(i=0;i<8;i=i+1)
    begin
        @(posedge sclk);
        miso = miso_data[i];
    end
end
endtask

//miso msb first task
task miso_bits_msb(input [7:0] miso_data);
begin
    wait(~ss);

    for(i=7;i>=0;i=i-1)
    begin
        @(posedge sclk);
        miso = miso_data[i];
    end
end
endtask

//spi register write task
task spi_config_reg(input [7:0] data, input [3:0] addr);
begin
    @(posedge PCLK);
    PADDR   = addr;
    PWDATA  = data;
    PSEL    = 1'b1;
    PENABLE = 1'b0;
    PWRITE  = 1'b1;

    @(posedge PCLK);
    PENABLE = 1'b1;

    wait(!PREADY);

    @(posedge PCLK);
    PSEL    = 1'b0;
    PENABLE = 1'b0;

    @(posedge PCLK);
end
endtask

//spi register read task
task spi_config_SR(input [3:0] addr);
begin
    @(negedge PCLK);
    PADDR   = addr;
    PSEL    = 1'b1;
    PENABLE = 1'b0;
    PWRITE  = 1'b0;

    @(negedge PCLK);
    PENABLE = 1'b1;

    wait(!PREADY);

    @(negedge PCLK);
    PSEL    = 1'b0;
    PENABLE = 1'b0;

    @(negedge PCLK);
end
endtask

//task stimulus
initial
begin
    reset;

    // CR1
    spi_config_reg(8'b11110111,4'd0);
    // CR2
    spi_config_reg(8'b0001_0000,4'd1);

    // Baud Rate Register
    spi_config_reg(8'b0000_0001,4'd2);

    // Status Register (optional)
    //spi_config_SR(4'd3);

    // Data Register
    spi_config_reg(8'd68,4'd5);

    // Send incoming MISO data
    miso_bits_msb(8'b10010011);

    // Read SR after transaction
    spi_config_SR(4'd3);
end

initial
    #2000 $finish;
endmodule

