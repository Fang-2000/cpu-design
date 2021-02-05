`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/30 20:23:25
// Design Name: 
// Module Name: pc
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

//取指令阶段，取出指令存储器中的指令，并实现pc值的递增
module pc(

	input	wire				clk,
	input wire					rst,

	//来自控制模块的信息
	input wire[5:0]               stall,

	//译码阶段
	input wire                    branch_flag_i,
	input wire[`RegBus]           branch_target_address_i,
	
	output reg[`InstAddrBus]	  pc,
	output reg                    ce    //指令存储器的使能信号
	
);

	always @ (posedge clk) begin
		if (ce == `ChipDisable) begin
			pc <= 32'h00000000;
		end else if(stall[0] == `NoStop) begin
		  	if(branch_flag_i == `Branch) begin
					pc <= branch_target_address_i;    //判断是否发生转移，用于分支跳转指令
				end else begin
		  		pc <= pc + 4'h4;
		  	end
		end
	end

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			ce <= `ChipDisable;
		end else begin
			ce <= `ChipEnable;
		end
	end

endmodule
