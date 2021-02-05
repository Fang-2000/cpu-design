`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/30 22:22:12
// Design Name: 
// Module Name: id_ex
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
//������׶ε��������ͺ�Դ����������Ϣ����alu
module id_alu(

	input	wire				clk,
	input wire					rst,

	//���Կ���ģ�����Ϣ
	input wire[5:0]				stall,
	
	//������׶δ��ݵ���Ϣ
	input wire[`AluOpBus]         id_aluop,
	input wire[`AluSelBus]        id_alusel,
	input wire[`RegBus]           id_reg1,            //����׶�Դ������1
	input wire[`RegBus]           id_reg2,            //����׶�Դ������2
	input wire[`RegAddrBus]       id_wd,
	input wire                    id_wreg,
	input wire[`RegBus]           id_link_address,
	input wire                    id_is_in_delayslot,
	input wire                    next_inst_in_delayslot_i,		
	input wire[`RegBus]           id_inst,		
	
	//���ݵ�ִ�н׶ε���Ϣ
	output reg[`AluOpBus]         alu_aluop,
	output reg[`AluSelBus]        alu_alusel,
	output reg[`RegBus]           alu_reg1,
	output reg[`RegBus]           alu_reg2,
	output reg[`RegAddrBus]       alu_wd,
	output reg                    alu_wreg,
	output reg[`RegBus]           alu_link_address,
    output reg                    alu_is_in_delayslot,
	output reg                    is_in_delayslot_o,
	output reg[`RegBus]           alu_inst	
	
);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			alu_aluop <= `fNOP_OP;
			alu_alusel <= `fRES_NOP;
			alu_reg1 <= `ZeroWord;
			alu_reg2 <= `ZeroWord;
			alu_wd <= `NOPRegAddr;
			alu_wreg <= `WriteDisable;
			alu_link_address <= `ZeroWord;
			alu_is_in_delayslot <= `NotInDelaySlot;
	    is_in_delayslot_o <= `NotInDelaySlot;		
	    alu_inst <= `ZeroWord;	
		end else if(stall[2] == `Stop && stall[3] == `NoStop) begin
			alu_aluop <= `fNOP_OP;
			alu_alusel <= `fRES_NOP;
			alu_reg1 <= `ZeroWord;
			alu_reg2 <= `ZeroWord;
			alu_wd <= `NOPRegAddr;
			alu_wreg <= `WriteDisable;	
			alu_link_address <= `ZeroWord;
	    alu_is_in_delayslot <= `NotInDelaySlot;	
	    alu_inst <= `ZeroWord;			
		end else if(stall[2] == `NoStop) begin		
			alu_aluop <= id_aluop;
			alu_alusel <= id_alusel;
			alu_reg1 <= id_reg1;
			alu_reg2 <= id_reg2;
			alu_wd <= id_wd;
			alu_wreg <= id_wreg;		
			alu_link_address <= id_link_address;
			alu_is_in_delayslot <= id_is_in_delayslot;
	    is_in_delayslot_o <= next_inst_in_delayslot_i;
	    alu_inst <= id_inst;				
		end
	end
	
endmodule

