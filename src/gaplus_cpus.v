/********************************************
   CPU Modules for "FPGA Gaplus"

			  Copyright (c) 2007,2019 MiSTer-X
*********************************************/

//----------------------------------------
//  Main CPU
//----------------------------------------
module GAPLUS_MAIN
(
	input				MCPU_CLK,
	input				RESET,
	input				VBLK,

	input  [31:0]	INP0,
	input  [31:0]	INP1,
	input	  [3:0]	INP2,

	output [15:0]	mcpu_ma,
	output			mcpu_we,
	output  [7:0]	mcpu_do,
	input   [7:0]	mcpu_mr,

	output       	snd_we,
	input   [7:0]	snd_rd,

	output			mcpu_star_cs,

	output 			SUB_RESET,
	output			kick_explode,


	input				ROMCL,	// Downloaded ROM image
	input  [17:0]	ROMAD,
	input	  [7:0]	ROMDT,
	input				ROMEN
);

wire [7:0]  mcpu_di;
wire        mcpu_rw, mcpu_vma;
wire        mcpu_wr = ~mcpu_rw;
wire        mcpu_rd =  mcpu_rw;

wire mcpu_irom_cs = ( mcpu_ma[15]                ) & mcpu_vma;
wire mcpu_mram_cs = ( mcpu_ma[15:13] == 3'b000   ) & mcpu_vma;
wire mcpu_srst_cs = ( mcpu_ma[15:12] == 4'b1000  ) & mcpu_vma & mcpu_wr;
wire mcpu_irqe_cs = ( mcpu_ma[15:12] == 4'b0111  ) & mcpu_vma & mcpu_wr;
wire mcpu_sndw_cs = ( mcpu_ma[15:11] == 5'b01100 ) & mcpu_vma;
wire mcpu_iocr_cs;

wire [7:0] mrom_d;
MAIN_ROM imn( MCPU_CLK, mcpu_ma, mrom_d, ROMCL,ROMAD,ROMDT,ROMEN );

assign mcpu_we =  mcpu_mram_cs & mcpu_wr;
assign snd_we  =  mcpu_sndw_cs & mcpu_wr;

reg	 mirq_en  = 1'b1;
wire	 mcpu_irq = (~mirq_en) & VBLK;

reg 	 _SUBRESET = 1'b1;
assign SUB_RESET = _SUBRESET;

always @ ( negedge MCPU_CLK or posedge RESET ) begin
	if ( RESET ) begin
		_SUBRESET <= 1;
		mirq_en   <= 1;
	end else begin
		if ( mcpu_srst_cs ) _SUBRESET <= mcpu_ma[11];
		if ( mcpu_irqe_cs ) mirq_en   <= mcpu_ma[11];
	end
end

wire [7:0] io_rd;
dataselector4 mcpudsel( 
	mcpu_di,
	mcpu_irom_cs, mrom_d,
	mcpu_mram_cs, mcpu_mr,
	mcpu_sndw_cs, snd_rd,
	mcpu_iocr_cs, io_rd,
	8'hFF
);

cpu6809 maincpu (
	.clkx2(MCPU_CLK),
	.rst(RESET),
	.rw(mcpu_rw),
	.vma(mcpu_vma),
	.address(mcpu_ma),
	.data_in(mcpu_di),
	.data_out(mcpu_do),
	.halt(1'b0),
	.hold(1'b0),
	.irq(mcpu_irq),
	.firq(1'b0),
	.nmi(1'b0)
);

GAPLUS_IO io(
	RESET, MCPU_CLK, VBLK,
	mcpu_ma, mcpu_vma, mcpu_wr, mcpu_do, io_rd, mcpu_iocr_cs,
	INP0, INP1, INP2, kick_explode
);

assign mcpu_star_cs = ( mcpu_ma[15:11] == 5'b10100 ) & mcpu_vma & mcpu_wr;

endmodule


//----------------------------------------
//  Sub CPU
//----------------------------------------
module GAPLUS_SUB
(
	input SCPU_CLK,
	input	RESET,
	input VBLK,

	input   [7:0] scpu_mr,
	output [15:0] scpu_ma,
	output        scpu_we,
	output  [7:0] scpu_do,


	input				ROMCL,	// Downloaded ROM image
	input  [17:0]	ROMAD,
	input	  [7:0]	ROMDT,
	input				ROMEN
);

wire [7:0]  scpu_di;
wire        scpu_rw, scpu_vma;
wire        scpu_wr = ~scpu_rw;
wire        scpu_rd =  scpu_rw;

wire scpu_irom_cs = ( scpu_ma[15]               ) & scpu_vma;
wire scpu_mram_cs = ( scpu_ma[15:13] == 3'b000  ) & scpu_vma;
wire scpu_irqe_cs = ( scpu_ma[15:12] == 4'b0110 ) & scpu_vma;

wire	[7:0]	srom_d;
SUB_ROM isb( SCPU_CLK, scpu_ma, srom_d, ROMCL,ROMAD,ROMDT,ROMEN );

dataselector2 scpu_disel( scpu_di, scpu_irom_cs, srom_d, scpu_mram_cs, scpu_mr, 8'hFF );

assign scpu_we =  scpu_mram_cs & scpu_wr;

reg	sirq_en  = 1'b1;
wire	scpu_irq = (~sirq_en) & VBLK;

always @ ( negedge SCPU_CLK or posedge RESET ) begin
	if ( RESET ) begin
		sirq_en <= 1'b1;
	end else begin
		if ( scpu_irqe_cs ) sirq_en <= (~scpu_ma[0]);
	end
end

cpu6809 subcpu (
	.clkx2(SCPU_CLK),
	.rst(RESET),
	.rw(scpu_rw),
	.vma(scpu_vma),
	.address(scpu_ma),
	.data_in(scpu_di),
	.data_out(scpu_do),
	.halt(1'b0),
	.hold(1'b0),
	.irq(scpu_irq),
	.firq(1'b0),
	.nmi(1'b0)
);

endmodule


// CPU core wrapper
module cpu6809
(
	input				clkx2,
	input				rst,
	output 			rw,
	output			vma,
	output [15:0]	address,
	input   [7:0]	data_in,
	output  [7:0]	data_out,
	input				halt,
	input				hold,
	input				irq,
	input				firq,
	input				nmi
);

// Phase Generator
reg rE=1'b0, rQ=1'b0;
always @(posedge clkx2) rQ <= ~rQ;
always @(negedge clkx2) rE <= ~rE;

// CPU core
mc6809i core (
	.D(data_in),.DOut(data_out),.ADDR(address),.RnW(rw),.E(rE),.Q(rQ),
	.nIRQ(~irq),.nFIRQ(~firq),.nNMI(~nmi),
	.nHALT(~halt),.nRESET(~rst),
	.nDMABREQ(1'b1)
);

assign vma = rE;

endmodule

