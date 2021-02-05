`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/30 21:33:31
// Design Name: 
// Module Name: if_id
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
//暂存取指令阶段取得的指令
module if_id(

	input	wire				clk,
	input wire				    rst,

	//来自控制模块的信息
	input wire[5:0]               stall,	

	input wire[`InstAddrBus]	  if_pc,     //取指令阶段取得指令对应的地址
	input wire[`InstBus]          if_inst,  //取得的指令
	output reg[`InstAddrBus]      id_pc,    //译码阶段指令对应的地址
	output reg[`InstBus]          id_inst   //译码阶段的指令
	
);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;
		end else if(stall[1] == `Stop && stall[2] == `NoStop) begin
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;	
	  end else if(stall[1] == `NoStop) begin
		  id_pc <= if_pc;
		  id_inst <= if_inst;
		end
	end

endmodule

