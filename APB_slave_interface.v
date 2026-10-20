//APB SLAVE INTERFACE BLOCK
module APB_slave_interface(
input PCLK,
input PRESET_n,
input [2:0] PADDR_i,
input PWRITE_i,
input PSEL_i,
input PENABLE_i,
input [7:0] PWDATA_i,
input ss_i,
input [7:0] miso_data_i,
input receive_data_i,
input tip_i,

output reg [7:0] PRDATA_o,
output mstr_o,
output cpol_o,
output cpha_o,
output lsbfe_o,
output spiswai_o,
output [2:0] sppr_o,
output [2:0] spr_o,
output reg spi_interrupt_request_o,
output PREADY_o,
output PSLVERR_o,
output reg send_data_o,
output reg [7:0] mosi_data_o,
output reg [1:0] spi_mode_o
);

//internal pins
reg [7:0] SPI_BR;
reg [7:0] SPI_CR1;
reg [7:0] SPI_CR2;
reg [7:0] SPI_SR;
reg [7:0] SPI_DR;

wire sptef;
wire spif;
wire spe;
wire modfen;
wire modf;
wire ssoe;
wire wr_enb;
wire rd_enb;
wire spie;
wire sptie;

parameter cr2_mask = 8'b0001_1011;
parameter br_mask = 8'b0111_0111;

//spi mode states
parameter spi_run = 2'b00; //run mode
parameter spi_wait = 2'b01; //wait mode
parameter spi_stop=2'b10; //stop mode
//spi_mode
reg[1:0] next_mode; // for spi-FSM
reg[1:0] STATE,next_state; // for apb-FSM
//APB states
parameter IDLE = 2'b00; //idle state
parameter SETUP = 2'b01; //setup state
parameter ENABLE = 2'b10; //enable state

assign ssoe     = SPI_CR1[1];
assign mstr_o   = SPI_CR1[4];
assign spe      = SPI_CR1[6];
assign spie     = SPI_CR1[7];
assign sptie    = SPI_CR1[5];
assign cpol_o   = SPI_CR1[3];
assign cpha_o   = SPI_CR1[2];
assign lsbfe_o  = SPI_CR1[0];

assign modfen   = SPI_CR2[4];
assign spiswai_o= SPI_CR2[1];

assign sppr_o   = SPI_BR[6:4];
assign spr_o    = SPI_BR[2:0];

assign wr_enb   = PWRITE_i && (STATE == ENABLE);
assign rd_enb   = !PWRITE_i && (STATE == ENABLE);

assign PREADY_o = (STATE == ENABLE) ? 1'b1 : 1'b0;
assign PSLVERR_o= (STATE == ENABLE) ? tip_i : 1'b0;

//SPI_SR logic
always@(*)
begin
  if(!PRESET_n)
     SPI_SR=8'b00100000;
  else
     SPI_SR=({spif,1'b0,sptef,modf,4'b0});
end

assign modf = (!ss_i && mstr_o && modfen && (!ssoe));
assign sptef =(SPI_DR == 8'b0)? 1'b1:1'b0;
assign spif =(SPI_DR!=8'b0)? 1'b1:1'b0;


// SPI_CR1 Logic
always @(posedge PCLK or negedge PRESET_n)
begin
    if(!PRESET_n)
        SPI_CR1 <= 8'h04;

    else if(wr_enb)
    begin
        if(PADDR_i == 3'b000)
            SPI_CR1 <= PWDATA_i;
        else
            SPI_CR1 <= SPI_CR1;
    end
end

// SPI_CR2 Logic
always @(posedge PCLK or negedge PRESET_n)
begin
    if(!PRESET_n)
        SPI_CR2 <= 8'h00;

    else if(wr_enb)
    begin
        if(PADDR_i == 3'b001)
            SPI_CR2 <= (PWDATA_i & cr2_mask);
        else
            SPI_CR2 <= SPI_CR2;
    end
end

// SPI_BR Logic
always @(posedge PCLK or negedge PRESET_n)
begin
    if(!PRESET_n)
        SPI_BR <= 8'h00;

    else if(wr_enb)
    begin
        if(PADDR_i == 3'b010)
            SPI_BR <= (PWDATA_i & br_mask);
        else
            SPI_BR <= SPI_BR;
    end
end

// SPI_DR Logic
always @(posedge PCLK or negedge PRESET_n)
begin
    if(!PRESET_n)
        SPI_DR <= 8'b0;

    else if(wr_enb)
    begin
        if(PADDR_i == 3'b101)
            SPI_DR <= PWDATA_i;

        else
            SPI_DR <= SPI_DR;
    end

    else if(((SPI_DR == PWDATA_i) && (SPI_DR != miso_data_i))
            && (spi_mode_o == spi_run || spi_mode_o == spi_wait))
        SPI_DR <= 8'b0;

    else if((spi_mode_o == spi_run || spi_mode_o == spi_wait)
            && receive_data_i)
        SPI_DR <= miso_data_i;

    else
        SPI_DR <= SPI_DR;
end

//send_data_o Logic
always @(posedge PCLK or negedge PRESET_n)
begin
    if(!PRESET_n)
        send_data_o <= 1'b0;

    else if(~wr_enb && (SPI_DR == PWDATA_i && SPI_DR != miso_data_i
             && (spi_mode_o == spi_run || spi_mode_o == spi_wait)))
        send_data_o <= 1'b1;

    else if(((spi_mode_o == spi_run) || (spi_mode_o == spi_wait))
             && receive_data_i)
        send_data_o <= 0;

    else
        send_data_o <= 0;
end

//MOSI-data logic
always @(posedge PCLK or negedge PRESET_n)
begin
    if(!PRESET_n)
        mosi_data_o <= 0;

    else if(((SPI_DR == PWDATA_i) && (SPI_DR != miso_data_i))
             && (spi_mode_o == spi_run || spi_mode_o == spi_wait))
    begin
        mosi_data_o <= SPI_DR;
    end
end

// Updating SPI_INTERRUPT_Request
always @(*)
begin
    if(!spie && !sptie)
        spi_interrupt_request_o = 1'b0;

    else if(!sptie && spie)
        spi_interrupt_request_o = spif | modf;

    else if(!spie && sptie)
        spi_interrupt_request_o = sptef;

    else
        spi_interrupt_request_o = spif | modf | sptef;
end


//PRDATA LOGIC
always @(*)
begin
    if(rd_enb)
    begin
        case(PADDR_i)

            3'b000: PRDATA_o = SPI_CR1;
            3'b001: PRDATA_o = SPI_CR2;
            3'b010: PRDATA_o = SPI_BR;
            3'b011: PRDATA_o = SPI_SR;
            3'b101: PRDATA_o = SPI_DR;

            default: PRDATA_o = 8'b0;

        endcase
    end

    else
        PRDATA_o = 0;
end

// logic to update the SPI Mode
always @(posedge PCLK or negedge PRESET_n)
begin
    if(!PRESET_n)
        spi_mode_o <= spi_run;

    else
        spi_mode_o <= next_mode;
end

always @(*)
begin
    case(spi_mode_o)

        spi_run :
        begin
            if(!spe)
                next_mode = spi_wait;
            else
                next_mode = spi_run;
        end

        spi_wait :
        begin
            if(spe)
                next_mode = spi_run;
            else if(spiswai_o)
                next_mode = spi_stop;
            else
                next_mode = spi_wait;
        end

        spi_stop :
        begin
            if(spe)
                next_mode = spi_run;
            else if(!spiswai_o)
                next_mode = spi_wait;
            else
                next_mode = spi_stop;
        end

        default :
            next_mode = spi_run;

    endcase
end

// APB-FSM States
always @(posedge PCLK or negedge PRESET_n)
begin
    if(!PRESET_n)
        STATE <= IDLE;

    else
        STATE <= next_state;
end
// APB States
always @(*)
begin
    case(STATE)

        IDLE :
        begin
            if(PSEL_i && !PENABLE_i)
                next_state = SETUP;
            else
                next_state = IDLE;
        end

        SETUP :
        begin
            if(PSEL_i && PENABLE_i)
                next_state = ENABLE;

            else if(PSEL_i && !PENABLE_i)
                next_state = SETUP;
        end

        ENABLE :
        begin
            if(PSEL_i)
                next_state = SETUP;
            else
                next_state = IDLE;
        end

        default :
            next_state = IDLE;

    endcase
end


endmodule



