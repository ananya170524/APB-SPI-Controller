//slave select control testbench

module slave_control_select_tb;

reg PCLK;
reg PRESET_n;
reg mstr_i;
reg spiswai_i;
reg [1:0] spi_mode_i;
reg send_data_i;
reg [11:0] BaudRateDivisor_i;

wire receive_data_o;
wire ss_o;
wire tip_o;

spi_slave_select DUT (
    .PCLK(PCLK),
    .PRESET_n(PRESET_n),
    .mstr_i(mstr_i),
    .spiswai_i(spiswai_i),
    .spi_mode_i(spi_mode_i),
    .send_data_i(send_data_i),
    .BaudRateDivisor_i(BaudRateDivisor_i),

    .receive_data_o(receive_data_o),
    .ss_o(ss_o),
    .tip_o(tip_o)
);

//clock generation
initial
begin
PCLK = 0;
forever #5 PCLK = ~PCLK;
end

//task initialize
task initialize;
begin
{mstr_i,spiswai_i,send_data_i,BaudRateDivisor_i,spi_mode_i}=0;
end
endtask

//task reset
task resetn;
begin
#5;
PRESET_n=0;
#10;
PRESET_n=1;
end
endtask

// task stimulus
task stimulus;
begin
@(negedge PCLK)
spiswai_i=0;
send_data_i=1'b1;
mstr_i=1'b1;
spi_mode_i=2'b00;
#20;
@(negedge PCLK)
send_data_i=0;
end
endtask

/*task stimulus2;
begin
@(negedge PCLK)
spi_mode_i=2'b00;
send_data_i=1'b1;
#20;
send_data_i=1'b0;
end
endtask*/

initial 
begin
initialize;
resetn;
BaudRateDivisor_i=4;
stimulus;
end

initial #1000 $finish;
endmodule






