`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/30 21:42:25
// Design Name: 
// Module Name: ex
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

module alu(

	input wire					  rst,
	
	//�͵�ִ�н׶ε���Ϣ
	input wire[`AluOpBus]         aluop_i,
	input wire[`AluSelBus]        alusel_i,
	input wire[`RegBus]           reg1_i,
	input wire[`RegBus]           reg2_i,
	input wire[`RegAddrBus]       wd_i,
	input wire                    wreg_i,
	input wire[`RegBus]           inst_i,
	
	//HI��LO�Ĵ�����ֵ
	input wire[`RegBus]           hi_i,
	input wire[`RegBus]           lo_i,

	//��д�׶ε�ָ���Ƿ�ҪдHI��LO�����ڼ��HI��LO������ð��
	input wire[`RegBus]           wb_hi_i,
	input wire[`RegBus]           wb_lo_i,
	input wire                    wb_whilo_i,
	
	//�ô�׶ε�ָ���Ƿ�ҪдHI��LO�����ڼ��HI��LO������ð��
	input wire[`RegBus]           mem_hi_i,
	input wire[`RegBus]           mem_lo_i,
	input wire                    mem_whilo_i,

	input wire[`DoubleRegBus]     hilo_temp_i,
	input wire[1:0]               cnt_i,


	//�Ƿ�ת�ơ��Լ�link address
	input wire[`RegBus]           link_address_i,
	input wire                    is_in_delayslot_i,	
	
	output reg[`RegAddrBus]       wd_o,
	output reg                    wreg_o,
	output reg[`RegBus]			wdata_o,

	output reg[`RegBus]           hi_o,
	output reg[`RegBus]           lo_o,
	output reg                    whilo_o,
	
	output reg[`DoubleRegBus]     hilo_temp_o,
	output reg[1:0]               cnt_o,

	//���ء��洢ָ��ӿ�
	output wire[`AluOpBus]        aluop_o,
	output wire[`RegBus]          mem_addr_o,
	output wire[`RegBus]          reg2_o,

	output reg					 stallreq       			
	
);

	reg[`RegBus] logicout;         //�߼�����Ľ��
	reg[`RegBus] shiftres;         //��λ����Ľ��
	reg[`RegBus] moveres;          //�ƶ��������
	reg[`RegBus] arithmeticres;   //��������������
	reg[`DoubleRegBus] mulres;	  //����˷����
	reg[`RegBus] HI;              //hi�Ĵ���ֵ������MFHI,MFLO,MTHI,MTLO
	reg[`RegBus] LO;              //lo�Ĵ���ֵ
	wire[`RegBus] reg2_i_mux;     //����Դ������2�Ĳ���
	wire[`RegBus] reg1_i_not;	  //����Դ������1ȡ����ֵ
	wire[`RegBus] result_sum;    //����ӷ����
	wire ov_sum;                 //�����־
	wire reg1_eq_reg2;           //�ж�����Դ�������Ƿ����
	wire reg1_lt_reg2;           //�ж�Դ������1�Ƿ�С��2
	wire[`RegBus] opdata1_mult; //������
	wire[`RegBus] opdata2_mult; //����
	wire[`DoubleRegBus] hilo_temp;
	reg[`DoubleRegBus] hilo_temp1;


  //aluop_o���ݵ��ô�׶Σ����ڼ��ء��洢ָ��
  assign aluop_o = aluop_i;
  
  //mem_addr���ݵ��ô�׶Σ��Ǽ��ء��洢ָ���Ӧ�Ĵ洢����ַ
  assign mem_addr_o = reg1_i + {{16{inst_i[15]}},inst_i[15:0]};

  //������������Ҳ���ݵ��ô�׶Σ�Ҳ��Ϊ���ء��洢ָ��׼����
  assign reg2_o = reg2_i;
			
	always @ (*) begin
		if(rst == `RstEnable) begin
			logicout <= `ZeroWord;
		end else begin
			case (aluop_i)
				`fOR_OP:			begin
					logicout <= reg1_i | reg2_i;
				end
				`fAND_OP:		begin
					logicout <= reg1_i & reg2_i;
				end
				`fNOR_OP:		begin
					logicout <= ~(reg1_i |reg2_i);
				end
				`fXOR_OP:		begin
					logicout <= reg1_i ^ reg2_i;
				end
				default:				begin
					logicout <= `ZeroWord;
				end
			endcase
		end    
	end      

	always @ (*) begin
		if(rst == `RstEnable) begin
			shiftres <= `ZeroWord;
		end else begin
			case (aluop_i)
				`fSLL_OP:			begin
					shiftres <= reg2_i << reg1_i[4:0] ;
				end
				`fSRL_OP:		begin
					shiftres <= reg2_i >> reg1_i[4:0];
				end
				default:				begin
					shiftres <= `ZeroWord;
				end
			endcase
		end   
	end     

	assign reg2_i_mux = ((aluop_i == `fSUB_OP)) 
											 ? (~reg2_i)+1 : reg2_i;

	assign result_sum = reg1_i + reg2_i_mux;										 
  //�ж��Ƿ����
	assign ov_sum = ((!reg1_i[31] && !reg2_i_mux[31]) && result_sum[31]) ||
									((reg1_i[31] && reg2_i_mux[31]) && (!result_sum[31]));  

  
  assign reg1_i_not = ~reg1_i;
							
	always @ (*) begin
		if(rst == `RstEnable) begin
			arithmeticres <= `ZeroWord;
		end else begin
			case (aluop_i)
				`fADD_OP, `fADDI_OP:		begin
					arithmeticres <= result_sum; 
				end
				`fSUB_OP:		begin
					arithmeticres <= result_sum; 
				end		
				default:				begin
					arithmeticres <= `ZeroWord;
				end
			endcase
		end
	end

  //ȡ�ó˷������Ĳ�������������з��ų����ұ������Ǹ�������ôȡ����
	assign opdata1_mult = (((aluop_i == `fMUL_OP))
													&& (reg1_i[31] == 1'b1)) ? (~reg1_i + 1) : reg1_i;
//������з��ų����ҳ����Ǹ�������ôȡ����
  assign opdata2_mult = (((aluop_i == `fMUL_OP))
													&& (reg2_i[31] == 1'b1)) ? (~reg2_i + 1) : reg2_i;	
//��ʱ�˷����
  assign hilo_temp = opdata1_mult * opdata2_mult;																				

	always @ (*) begin
		if(rst == `RstEnable) begin
			mulres <= {`ZeroWord,`ZeroWord};
		end else if ((aluop_i == `fMUL_OP))begin
			if(reg1_i[31] ^ reg2_i[31] == 1'b1) begin
				mulres <= ~hilo_temp + 1;
			end else begin
			  mulres <= hilo_temp;
			end
		end else begin
				mulres <= hilo_temp;
		end
	end

  //�õ����µ�HI��LO�Ĵ�����ֵ���˴�Ҫ���ָ������ð������
	always @ (*) begin
		if(rst == `RstEnable) begin
			{HI,LO} <= {`ZeroWord,`ZeroWord};
		end else if(mem_whilo_i == `WriteEnable) begin
			{HI,LO} <= {mem_hi_i,mem_lo_i};
		end else if(wb_whilo_i == `WriteEnable) begin
			{HI,LO} <= {wb_hi_i,wb_lo_i};
		end else begin
			{HI,LO} <= {hi_i,lo_i};			
		end
	end	

 

	//MFHI��MFLO��MOVN��MOVZָ��
	always @ (*) begin
		if(rst == `RstEnable) begin
	  	moveres <= `ZeroWord;
	  end else begin
	   moveres <= `ZeroWord;
	   case (aluop_i)
	   	`fMFHI_OP:		begin
	   		moveres <= HI;
	   	end
	   	`fMFLO_OP:		begin
	   		moveres <= LO;
	   	end
	   	`fMOVZ_OP:		begin
	   		moveres <= reg1_i;
	   	end
	   	`fMOVN_OP:		begin
	   		moveres <= reg1_i;
	   	end
	   	default : begin
	   	end
	   endcase
	  end
	end	 

 always @ (*) begin
	 wd_o <= wd_i;
	 	 	 	
	 if(((aluop_i == `fADD_OP) || (aluop_i == `fADDI_OP) || 
	      (aluop_i == `fSUB_OP)) && (ov_sum == 1'b1)) begin
	 	wreg_o <= `WriteDisable;
	 end else begin
	  wreg_o <= wreg_i;
	 end
	 
	 case ( alusel_i ) 
	 	`fRES_LOGIC:		begin
	 		wdata_o <= logicout;
	 	end
	 	`fRES_SHIFT:		begin
	 		wdata_o <= shiftres;
	 	end	 	
	 	`fRES_MOVE:		begin
	 		wdata_o <= moveres;
	 	end	 	
	 	`fRES_ARITHMETIC:	begin
	 		wdata_o <= arithmeticres;
	 	end
	 	`fRES_MUL:		begin
	 		wdata_o <= mulres[31:0];
	 	end	 	
	 	`fRES_JUMP_BRANCH:	begin
	 		wdata_o <= link_address_i;
	 	end	 	
	 	default:					begin
	 		wdata_o <= `ZeroWord;
	 	end
	 endcase
 end	
//MTHI,MTLO
	always @ (*) begin
		if(rst == `RstEnable) begin
			whilo_o <= `WriteDisable;
			hi_o <= `ZeroWord;
			lo_o <= `ZeroWord;		
		end  else if(aluop_i == `fMTHI_OP) begin
			whilo_o <= `WriteEnable;
			hi_o <= reg1_i;
			lo_o <= LO;
		end else if(aluop_i == `fMTLO_OP) begin
			whilo_o <= `WriteEnable;
			hi_o <= HI;
			lo_o <= reg1_i;
		end else begin
			whilo_o <= `WriteDisable;
			hi_o <= `ZeroWord;
			lo_o <= `ZeroWord;
		end				
	end			

endmodule

