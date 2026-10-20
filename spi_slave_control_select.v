// SPI SLAVE CONTROL SELECT BLOCK
module spi_slave_select( 
input PCLK,
input PRESET_n,
input mstr_i,
input spiswai_i,
input [1:0] spi_mode_i,
input send_data_i,
input [11:0] BaudRateDivisor_i,

output reg receive_data_o,
output reg ss_o,
output tip_o
);

reg [15:0] count_s;
wire [15:0] target_s;
reg rcv_s;

assign target_s = 16*(BaudRateDivisor_i/2); // 16 clock edges 8 pulses.
assign tip_o = ~ss_o;

// generating recieve data signal
always @ (posedge PCLK or negedge PRESET_n)
begin
if(!PRESET_n)
   receive_data_o <=1'b0;
else
   receive_data_o <= rcv_s;
end


//controlling slave select signal, counter and recieve indicator

always @ (posedge PCLK or negedge PRESET_n)
begin
if(!PRESET_n)
 begin
  count_s <=16'hffff;
  ss_o    <=1'b1;
  rcv_s   <=1'b0;
 end
else if(mstr_i && (spi_mode_i==2'b00 || (spi_mode_i==2'b01 && !spiswai_i)))
begin
 if(send_data_i)
 begin
  ss_o <=1'b0;
  count_s <=16'h0000;
 end
 else if(count_s <= target_s-1'b1)
 begin
 ss_o    <=1'b0;
 count_s <= count_s+1'b1;
  if(count_s == target_s-1'b1)
   rcv_s <=1'b1;
 end
 else
 begin
   ss_o <=1'b1;
   rcv_s<=1'b0;
   count_s <=16'hffff;
end
end

else // when spi is not in master mode or unsported SPI mode
begin
ss_o  <= 1'b1;
rcv_s <= 1'b0;
count_s <=16'hffff;
end
end

endmodule





