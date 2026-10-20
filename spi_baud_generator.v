// BAUD RATE GENERATOR BLOCK
// _i denotes the inputs to the block and _o denotes the outputs of the block
module spi_baud_generator(
input PCLK, 
input PRESET_n,
 
input [1:0] spi_mode_i, 
input spiswai_i,
 
input [2:0] sppr_i, 
input [2:0] spr_i, 

input cpol_i, 
input cpha_i, 
input ss_i, 

output reg sclk_o,
 
output reg miso_receive_sclk_o, 
output reg miso_receive_sclk0_o,

output reg mosi_send_sclk_o,
output reg mosi_send_sclk0_o,

output [11:0] BaudRateDivisor_o
);

//internal signals
wire pre_sclk_s;
reg [11:0] count_s;

//computing baud rate divisor
assign BaudRateDivisor_o = ((sppr_i+1)*(2**(spr_i+1)));

//inital SCLK polarity
assign pre_sclk_s=cpol_i?1'b1:1'b0;

//spi clock SCLK generation
always @(posedge PCLK or negedge PRESET_n)
	begin
		if(!PRESET_n)
                	begin
                        	count_s <= 12'b0; //clear counter
                                sclk_o  <= pre_sclk_s;
                        end
                else if(!ss_i && !spiswai_i && (spi_mode_i==2'b00 || spi_mode_i==2'b01))
			begin
				if(count_s == (BaudRateDivisor_o/2 - 1'b1))
					begin 
                                        count_s <= 12'b0;
   					sclk_o  <= ~sclk_o;
					end
			
                                else
					begin
                                        sclk_o  <= sclk_o;//hold the clock at its current value
                                        count_s <= count_s+1'b1;
					end
                       end
		else
  			begin
				sclk_o  <= pre_sclk_s;
	 			count_s <= 12'b0;
			end
        end

//Generating miso flag
always @(posedge PCLK or negedge PRESET_n)
begin
 if(!PRESET_n)
  begin
   miso_receive_sclk_o  <=1'b0;
   miso_receive_sclk0_o <=1'b0;
  end 
 else
 begin
  if((!cpha_i && cpol_i)||(cpha_i && !cpol_i))
  begin
   if(sclk_o)
    begin
     if(count_s == BaudRateDivisor_o/2-1'b1)
        miso_receive_sclk0_o <=1'b1;
      else
        miso_receive_sclk0_o <=1'b0;
    end
   else
    miso_receive_sclk0_o <=1'b0;
  end
  else if((!cpha_i && !cpol_i)||(cpha_i && cpol_i))
  begin
   if(!sclk_o)
   begin
    if(count_s == BaudRateDivisor_o/2-1'b1)
       miso_receive_sclk_o <=1'b1;
    else
       miso_receive_sclk_o <=1'b0;
    end
  else
miso_receive_sclk_o <=1'b0;
end
end
end

//Generating MOSI flags
always @(posedge PCLK or negedge PRESET_n)
begin
 if(!PRESET_n)
  begin
   mosi_send_sclk0_o  <=1'b0;
   mosi_send_sclk_o   <=1'b0;
  end
 else
 begin
  if((!cpha_i && cpol_i)||(cpha_i && !cpol_i))
  begin
   if(sclk_o)
   begin
     if(count_s == BaudRateDivisor_o/2 - 2'b10)
        mosi_send_sclk0_o <= 1'b1;
     else
        mosi_send_sclk0_o <= 1'b0;
   end
   else
     mosi_send_sclk0_o <= 1'b0;
 end
 else if((!cpha_i && !cpol_i) || (cpha_i && cpol_i))
 begin
  if(!sclk_o)
   begin
    if(count_s == BaudRateDivisor_o/2 - 2'b10)
       mosi_send_sclk_o <=1'b1;
    else
       mosi_send_sclk_o <=1'b0;
   end
  else
   mosi_send_sclk_o=1'b0;
end
end
end

endmodule

