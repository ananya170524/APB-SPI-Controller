//shift register tesb bench
module spi_shift_register_tb();

// Inputs
reg PCLK;
reg PRESET_n;
reg ss_i;
reg send_data_i;
reg lsbfe_i;
reg cpha_i;
reg cpol_i;
reg miso_receive_sclk_i;
reg miso_receive_sclk0_i;
reg mosi_send_sclk_i;
reg mosi_send_sclk0_i;
reg [7:0] data_mosi_i;
reg miso_i;
reg receive_data_i;

// Outputs
wire mosi_o;
wire [7:0] data_miso_o;

// Loop variable
integer i;

// Baud generation related signals
reg sclk_i, spiswai_i;
reg [2:0] sppr_i;
reg [2:0] spr_i;

wire [11:0] BaudRateDivisor_o;
wire pre_sclk_s;

reg [11:0] count_s;
reg [1:0] spi_mode_i;

spi_shift_register dut(
    .PCLK(PCLK),
    .PRESET_n(PRESET_n),
    .ss_i(ss_i),
    .send_data_i(send_data_i),
    .lsbfe_i(lsbfe_i),
    .cpha_i(cpha_i),
    .cpol_i(cpol_i),
    .miso_receive_sclk_i(miso_receive_sclk_i),
    .miso_receive_sclk0_i(miso_receive_sclk0_i),
    .mosi_send_sclk_i(mosi_send_sclk_i),
    .mosi_send_sclk0_i(mosi_send_sclk0_i),
    .data_mosi_i(data_mosi_i),
    .miso_i(miso_i),
    .receive_data_i(receive_data_i),
    .mosi_o(mosi_o),
    .data_miso_o(data_miso_o)
);

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
                                sclk_i  <= pre_sclk_s;
                        end
                else if(!ss_i && !spiswai_i && (spi_mode_i==2'b00 || spi_mode_i==2'b01))
			begin
				if(count_s == (BaudRateDivisor_o/2 - 1'b1))
					begin 
                                        count_s <= 12'b0;
   					sclk_i  <= ~sclk_i;
					end
			
                                else
					begin
                                        sclk_i  <= sclk_i;//hold the clock at its current value
                                        count_s <= count_s+1'b1;
					end
                       end
		else
  			begin
				sclk_i  <= pre_sclk_s;
	 			count_s <= 12'b0;
			end
        end

//Generating miso flag
always @(posedge PCLK or negedge PRESET_n)
begin
 if(!PRESET_n)
  begin
   miso_receive_sclk_i  <=1'b0;
   miso_receive_sclk0_i <=1'b0;
  end 
 else
 begin
  if((!cpha_i && cpol_i)||(cpha_i && !cpol_i))
  begin
   if(sclk_i)
    begin
     if(count_s == BaudRateDivisor_o/2-1'b1)
        miso_receive_sclk0_i <=1'b1;
      else
        miso_receive_sclk0_i <=1'b0;
    end
   else
    miso_receive_sclk0_i <=1'b0;
  end
  else if((!cpha_i && !cpol_i)||(cpha_i && cpol_i))
  begin
   if(!sclk_i)
   begin
    if(count_s == BaudRateDivisor_o/2-1'b1)
       miso_receive_sclk_i <=1'b1;
    else
       miso_receive_sclk_i <=1'b0;
    end
  else
miso_receive_sclk_i <=1'b0;
end
end
end

//Generating MOSI flags
always @(posedge PCLK or negedge PRESET_n)
begin
 if(!PRESET_n)
  begin
   mosi_send_sclk0_i  <=1'b0;
   mosi_send_sclk_i   <=1'b0;
  end
 else
 begin
  if((!cpha_i && cpol_i)||(cpha_i && !cpol_i))
  begin
   if(sclk_i)
   begin
     if(count_s == BaudRateDivisor_o/2 - 2'b10)
        mosi_send_sclk0_i <= 1'b1;
     else
        mosi_send_sclk0_i <= 1'b0;
   end
   else
     mosi_send_sclk0_i <= 1'b0;
 end
 else if((!cpha_i && !cpol_i) || (cpha_i && cpol_i))
 begin
  if(!sclk_i)
   begin
    if(count_s == BaudRateDivisor_o/2 - 2'b10)
       mosi_send_sclk_i <=1'b1;
    else
       mosi_send_sclk_i <=1'b0;
   end
  else
   mosi_send_sclk_i <=1'b0;
end
end
end


//clock generation
initial
    PCLK = 0;

always
    #5 PCLK = ~PCLK;

// Task to initialize signals
task initialize;
begin
    @(negedge PCLK)

    PRESET_n = 0;

    sppr_i = 1;
    spr_i  = 0;

    ss_i = 1;

    spiswai_i = 0;
    spi_mode_i = 0;

    send_data_i = 0;

    lsbfe_i = 0;
    cpha_i  = 0;
    cpol_i  = 0;

    miso_receive_sclk_i  = 0;
    miso_receive_sclk0_i = 0;

    mosi_send_sclk_i  = 0;
    mosi_send_sclk0_i = 0;

    miso_i = 0;
    receive_data_i = 0;

    data_mosi_i = 8'b0;
end
endtask

// Task to reset the DUT
task reset_dut;
begin
    #10;
    PRESET_n = 0;

    #10;
    PRESET_n = 1;
end
endtask

// Task to send data
task send_spi_data(
    input [7:0] spi_data,
    input lsb_first
);

begin
    send_data_i = 1;
    data_mosi_i = spi_data;
    lsbfe_i     = lsb_first;

    #10;

    send_data_i = 0;
end
endtask

task send_miso_task;
begin
    for(i = 0; i < 7; i = i + 1)
    begin
        @(negedge sclk_i)
        miso_i = ~miso_i;
    end
end
endtask

task spi_transfer(
    input ss_active,
    input mosi_ss_v_i,
    input mosi_ss0_v_i,
    input miso_rs_v_i,
    input miso_rs0_v_i
);

begin
    ss_i = ss_active;

    mosi_send_sclk_i  = mosi_ss_v_i;
    mosi_send_sclk0_i = mosi_ss0_v_i;

    miso_receive_sclk_i  = miso_rs_v_i;
    miso_receive_sclk0_i = miso_rs0_v_i;

    #1000;

    ss_i = 1;
end
endtask

initial
begin

    // Initialize signals
    initialize;

    // Apply reset
    reset_dut;

    fork

        // Test Case 1 : Normal data transfer with specific flag settings

       $display($time,"Starting Test case 1");

        send_spi_data(8'b00001010,1);   // 0x0A, LSB first

        receive_data_i = 0;

        send_miso_task;

        cpol_i = 1'b0;
        cpha_i = 1'b1;

        spi_transfer(0,1,0,1,0);

        receive_data_i = 1; 

    join


    /* Test Case 2 : Different flag settings

    $display($time,"Starting Test case 2");

    send_spi_data(8'h3C,0);    // Send 0x3C with MSB first

    spi_transfer(0,0,1,0,1); */

 
    /* Test Case 3 : Edge case with all flags high

    $display($time,"Starting Test case 3");

    send_spi_data(8'hFF,1);    // Send 0xFF with LSB first

    spi_transfer(0,1,1,1,1);
    

    // Test Case 4 : Edge case with all flags low

    $display($time,"Starting Test case 4");

    send_spi_data(8'h00,0);    // Send 0x00 with MSB first

    spi_transfer(0,0,0,0,0);
*/

    // End simulation

    $display($time,"All test cases completed");

    #100;
    $finish;

end
endmodule


