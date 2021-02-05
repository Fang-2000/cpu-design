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
//�ݴ�ȡָ��׶�ȡ�õ�ָ��
module if_id(

	input	wire				clk,
	input wire				    rst,

	//���Կ���ģ�����Ϣ
	input wire[5:0]               stall,	

	input wire[`InstAddrBus]	  if_pc,     //ȡָ��׶�ȡ��ָ���Ӧ�ĵ�ַ
	input wire[`InstBus]          if_inst,  //ȡ�õ�ָ��
	output reg[`InstAddrBus]      id_pc,    //����׶�ָ���Ӧ�ĵ�ַ
	output reg[`InstBus]          id_inst   //����׶ε�ָ��
	
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

