`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/30 21:50:46
// Design Name: 
// Module Name: ex_mem
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "defines.vh"

module alu_mem(

	input	wire				clk,
	input wire					rst,

	//来自控制模块的信息
	input wire[5:0]				stall,	
	
	//来自执行阶段的信息	
	input wire[`RegAddrBus]       alu_wd,
	input wire                    alu_wreg,
	input wire[`RegBus]			  alu_wdata, 	
	input wire[`RegBus]           alu_hi,
	input wire[`RegBus]           alu_lo,
	input wire                    alu_whilo, 	

  //为实现加载、访存指令而添加
  input wire[`AluOpBus]        alu_aluop,
	input wire[`RegBus]          alu_mem_addr,
	input wire[`RegBus]          alu_reg2,

	input wire[`DoubleRegBus]     hilo_i,	
	input wire[1:0]               cnt_i,	
	
	//送到访存阶段的信息
	output reg[`RegAddrBus]      mem_wd,
	output reg                   mem_wreg,
	output reg[`RegBus]			mem_wdata,
	output reg[`RegBus]          mem_hi,
	output reg[`RegBus]          mem_lo,
	output reg                   mem_whilo, //是否写入hi，lo寄存器

  //为实现加载、访存指令而添加
  output reg[`AluOpBus]        mem_aluop,
	output reg[`RegBus]          mem_mem_addr,
	output reg[`RegBus]          mem_reg2,
		
	output reg[`DoubleRegBus]    hilo_o,
	output reg[1:0]              cnt_o	
	
	
);


	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
		  mem_wdata <= `ZeroWord;	
		  mem_hi <= `ZeroWord;
		  mem_lo <= `ZeroWord;
		  mem_whilo <= `WriteDisable;		
	    hilo_o <= {`ZeroWord, `ZeroWord};
			cnt_o <= 2'b00;	
  		mem_aluop <= `fNOP_OP;
			mem_mem_addr <= `ZeroWord;
			mem_reg2 <= `ZeroWord;			
		end else if(stall[3] == `Stop && stall[4] == `NoStop) begin
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
		  mem_wdata <= `ZeroWord;
		  mem_hi <= `ZeroWord;
		  mem_lo <= `ZeroWord;
		  mem_whilo <= `WriteDisable;
	    hilo_o <= hilo_i;
			cnt_o <= cnt_i;	
  		mem_aluop <= `fNOP_OP;
			mem_mem_addr <= `ZeroWord;
			mem_reg2 <= `ZeroWord;						  				    
		end else if(stall[3] == `NoStop) begin
			mem_wd <= alu_wd;
			mem_wreg <= alu_wreg;
			mem_wdata <= alu_wdata;	
			mem_hi <= alu_hi;
			mem_lo <= alu_lo;
			mem_whilo <= alu_whilo;	
	    hilo_o <= {`ZeroWord, `ZeroWord};
			cnt_o <= 2'b00;	
  		mem_aluop <= alu_aluop;
			mem_mem_addr <= alu_mem_addr;
			mem_reg2 <= alu_reg2;			
		end else begin
	    hilo_o <= hilo_i;
			cnt_o <= cnt_i;											
		end    //if
	end      //always
endmodule


