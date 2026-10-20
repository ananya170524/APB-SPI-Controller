//SPI SHIFT REGISTER BLOCK
module spi_shift_register(
input PCLK,
input PRESET_n,
input ss_i,
input send_data_i,
input lsbfe_i,
input cpha_i,
input cpol_i,
input miso_receive_sclk_i,
input miso_receive_sclk0_i,
input mosi_send_sclk_i,
input mosi_send_sclk0_i,
input [7:0] data_mosi_i,
input miso_i,
input receive_data_i,

output reg mosi_o,
output [7:0] data_miso_o
);

// internal signals
reg [7:0] shift_register; // stores the bits that will be transmitted through mosi
reg [7:0] temp_reg; // stores incoming miso bits
reg [2:0] count,count1; //for MOSI shifting for both LSB first/MSB first
reg [2:0] count2,count3; //for MISO shifting for both LSB first/MSB first

//updating miso data
assign data_miso_o = receive_data_i? temp_reg:8'h00;

//updating shift register signal
always @(posedge PCLK or negedge PRESET_n)
begin
if(!PRESET_n)
shift_register <=8'h00;
else if(send_data_i)
shift_register <=data_mosi_i;
else
shift_register <=shift_register;
end

always @(posedge PCLK or negedge PRESET_n)
begin
if(!PRESET_n)
begin
mosi_o <=1'b0;
count  <=3'd0;
count1 <=3'd7;
end
else
begin
 if(!ss_i)
  begin
   if((!cpha_i && cpol_i) || (cpha_i && !cpol_i)) //negedge
      begin
       if(lsbfe_i) // count increment wrt mosi_send_sclk
 	 begin
	   if(count <=3'd7)
              begin
               if(mosi_send_sclk0_i)
                  begin
                    mosi_o <=shift_register[count];
		    count <=count+1'b1;
		  end
        end
       else
       count <=3'd0;
      end
      else // count1 decrement wrt mosi_send_sclk0_i ie negedge and MSB
      begin
        if(count1>=3'd0)
           begin
            if(mosi_send_sclk0_i)
              begin
               mosi_o <=shift_register[count1];
               count1 <=count1-1'b1;
               end
           end
        else
         count1 <=3'd7;
         end
        end
   else // posedge sclk when cpol == cpha
    begin
      if(lsbfe_i) //count increment wrt mosi_send_sclk
      begin
        if(count <=3'd7)
           begin
             if(mosi_send_sclk_i)
                begin
                  mosi_o <=shift_register[count];
                  count <=count+1'b1;

                end
        end
       else
       count <=3'd0;
      end
      else // count1 decrement wrt mosi_send_sclk
        begin
          if(count1>=3'd0)
            begin
              if(mosi_send_sclk_i)
                 begin
                   mosi_o <=shift_register[count1];
                   count1 <=count1- 1'b1;
                 end
             end
           else
            count1 <=3'd7;
           end
end
end
end
end

//MISO
always @(posedge PCLK or negedge PRESET_n)
begin
  if(!PRESET_n)
     begin
       temp_reg <=8'b0;
       count2   <=3'd0;
       count3   <=3'd7;
    end
 else                     
   begin
     if(!ss_i)
       begin
         if((!cpha_i && cpol_i) || (cpha_i && !cpol_i)) //negedge
           begin
             if(lsbfe_i) //count2 increments/ LSB first
               begin
                 if(count2 <= 3'd7)
                    begin
                      if(miso_receive_sclk0_i)
                         begin
                            temp_reg[count2] <=miso_i;
                            count2 <=count2 + 1'b1;
                         end
                    end
                  else
                    count2 <= 3'd0;
                end
             else //count3 decrements/ MSB first
               begin
                  if(count3 >=3'd0)
                     begin
                     if(miso_receive_sclk0_i)
                        begin
                          temp_reg[count3] <=miso_i;
                          count3 <=count3 -1'b1;
                        end
                    end
                 else
                   count3 <=3'd7;
                 end
               end
    else //posedge
       begin
             if(lsbfe_i) //count2 increments/ LSB first
               begin
                 if(count2 <= 3'd7)
                    begin
                      if(miso_receive_sclk_i)
                         begin
                            temp_reg[count2] <=miso_i;
                            count2 <=count2 + 1'b1;
                         end
                    end
                  else
                    count2 <= 3'd0;
                end
             else //count3 decrements/ MSB first
               begin
                  if(count3 >=3'd0)
                     begin
                     if(miso_receive_sclk_i)
                        begin
                          temp_reg[count3] <=miso_i;
                          count3 <=count3 -1'b1;
                        end
                    end
                 else
                   count3 <=3'd7;
                 end
               
end
end
end
end
endmodule



