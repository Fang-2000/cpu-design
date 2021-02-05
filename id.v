`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/30 20:26:17
// Design Name: 
// Module Name: id
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
//ָ�����������õ���������ͺ������ͣ�Դ��������д���Ŀ�ļĴ�������Ϣ
module id(

	input wire				rst,     //��λ�ź�
	input wire[31:0]		pc_i,    //����׶ε�ָ���Ӧ�ĵ�ַ
	input wire[31:0]        inst_i,  //����׶ε�ָ��

    //����ִ�н׶ε�ָ���һЩ��Ϣ�����ڽ��load���
    input wire[`AluOpBus]	alu_aluop_i,

    //�˴�Ϊ�������������ӵĽӿ�
	//����ִ�н׶ε�ָ��Ҫд���Ŀ�ļĴ�����Ϣ
	input wire				alu_wreg_i,    //ִ�н׶ε�ָ���Ƿ�Ҫд��Ŀ�ļĴ���
	input wire[`RegBus]		alu_wdata_i,   //ִ�н׶ε�ָ��Ҫд��Ŀ�ļĴ���������
	input wire[`RegAddrBus] alu_wd_i,      //ִ�н׶ε�ָ��Ҫд��Ŀ�ļĴ����ĵ�ַ
	
	//���ڷô�׶ε�ָ��Ҫд���Ŀ�ļĴ�����Ϣ
	input wire					  mem_wreg_i,
	input wire[`RegBus]			  mem_wdata_i,
	input wire[`RegAddrBus]       mem_wd_i,
	input wire[`RegBus]           reg1_data_i,   //�Ĵ������һ�����Ĵ����˿ڵ�����
	input wire[`RegBus]           reg2_data_i,   //�Ĵ�����ڶ������Ĵ����˿ڵ�����

	//�����һ��ָ����ת��ָ���ô��һ��ָ���������ʱ��is_in_delayslotΪtrue
	input wire                    is_in_delayslot_i,

	//������Ĵ��������Ϣ
	output reg                    reg1_read_o,   //�Ĵ������һ�����Ĵ����˿ڵĶ�ʹ��
	output reg                    reg2_read_o,   //�Ĵ�����ڶ������Ĵ����˿ڵĶ�ʹ��
	output reg[`RegAddrBus]       reg1_addr_o,   //�Ĵ������һ�����Ĵ����˿ڵĶ���ַ�ź�
	output reg[`RegAddrBus]       reg2_addr_o, 	 //�Ĵ�����ڶ������Ĵ����˿ڵĶ���ַ�ź�    
	
	//�����ִ�н׶ε���Ϣ
	output reg[`AluOpBus]         aluop_o,       //����׶�ָ������������ͣ����룬��
	output reg[`AluSelBus]        alusel_o,      //����׶�ָ����������ͣ��߼����㣬���������
	output reg[`RegBus]           reg1_o,        //����׶�Դ������1
	output reg[`RegBus]           reg2_o,        //����׶�Դ������2
	output reg[`RegAddrBus]       wd_o,          //ָ��Ҫд���Ŀ�ļĴ�����ַ
	output reg                    wreg_o,        //ָ���Ƿ���Ҫд���Ŀ�ļĴ���
	output wire[`RegBus]          inst_o,

	output reg                    next_inst_in_delayslot_o,
	
	output reg                    branch_flag_o,
	output reg[`RegBus]           branch_target_address_o,       
	output reg[`RegBus]           link_addr_o,
	output reg                    is_in_delayslot_o,
	
	output wire                   stallreq	
);

//ָ��Ĳ�����͵�ַ��
  wire[5:0] op = inst_i[31:26];
  wire[4:0] op2 = inst_i[10:6];
  wire[5:0] op3 = inst_i[5:0];
  wire[4:0] op4 = inst_i[20:16];
  reg[`RegBus]	imm;          //����ָ��ִ�������������
  reg instvalid;              //�ж�ָ���Ƿ���Ч
  wire[`RegBus] pc_plus_8;
  wire[`RegBus] pc_plus_4;
  wire[`RegBus] imm_sll2_signedext;  

  reg stallreq_for_reg1_loadrelate;
  reg stallreq_for_reg2_loadrelate;
  wire pre_inst_is_load;
  
  assign pc_plus_8 = pc_i + 8;
  assign pc_plus_4 = pc_i +4;
  assign imm_sll2_signedext = {{14{inst_i[15]}}, inst_i[15:0], 2'b00 };  
  assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;
  assign pre_inst_is_load = ((alu_aluop_i == `fLB_OP) || 
  													(alu_aluop_i == `fLBU_OP)||
  													(alu_aluop_i == `fLH_OP) ||
  													(alu_aluop_i == `fLHU_OP)||
  													(alu_aluop_i == `fLW_OP)) ? 1'b1 : 1'b0;

  assign inst_o = inst_i;
//��λʱ���ܲ���   
	always @ (*) begin	
		if (rst == `RstEnable) 
		begin
			aluop_o <= 8'b00000000;
			alusel_o <= 3'b000;
			wd_o <= 5'b00000;
			wreg_o <= `WriteDisable;
			instvalid <= `InstValid;
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= 5'b00000;
			reg2_addr_o <= 5'b00000;
			imm <= 32'h0;	
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot;					
	    end 
	    else 
		begin
			aluop_o <= 8'b00000000;
			alusel_o <= 3'b000;
			wd_o <= inst_i[15:11];
			wreg_o <= `WriteDisable;
			instvalid <= `InstInvalid;	   
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= inst_i[25:21];       //Դ������1
			reg2_addr_o <= inst_i[20:16];		//Դ������2
			imm <= `ZeroWord;
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;	
			next_inst_in_delayslot_o <= `NotInDelaySlot; 			
		  case (op)
		    `fSPECIAL_INST:		begin
		    	case (op2)
		    		5'b00000:			begin
		    			case (op3)
		    				`fOR:	begin
		    					wreg_o <= `WriteEnable;		aluop_o <= `fOR_OP;
		  						alusel_o <= `fRES_LOGIC; 	reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end  
		    				`fAND:	begin
		    					wreg_o <= `WriteEnable;		aluop_o <= `fAND_OP;
		  						alusel_o <= `fRES_LOGIC;	  reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	
		  						instvalid <= `InstValid;	
								end  	
		    				`fXOR:	begin
		    					wreg_o <= `WriteEnable;		aluop_o <= `fXOR_OP;
		  						alusel_o <= `fRES_LOGIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	
		  						instvalid <= `InstValid;	
								end  				
		    				`fNOR:	begin
		    					wreg_o <= `WriteEnable;		aluop_o <= `fNOR_OP;
		  						alusel_o <= `fRES_LOGIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	
		  						instvalid <= `InstValid;	
								end 				
								`fMFHI: begin
									wreg_o <= `WriteEnable;		aluop_o <= `fMFHI_OP;
		  						alusel_o <= `fRES_MOVE;   reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
		  						instvalid <= `InstValid;	
								end
								`fMFLO: begin
									wreg_o <= `WriteEnable;		aluop_o <= `fMFLO_OP;
		  						alusel_o <= `fRES_MOVE;   reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
		  						instvalid <= `InstValid;	
								end
								`fMTHI: begin
									wreg_o <= `WriteDisable;		aluop_o <= `fMTHI_OP;
		  						reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0; instvalid <= `InstValid;	
								end
								`fMTLO: begin
									wreg_o <= `WriteDisable;		aluop_o <= `fMTLO_OP;
		  						reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0; instvalid <= `InstValid;	
								end
								`fMOVN: begin
									aluop_o <= `fMOVN_OP;
		  						alusel_o <= `fRES_MOVE;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;
								 	if(reg2_o != `ZeroWord) begin
	 									wreg_o <= `WriteEnable;
	 								end else begin
	 									wreg_o <= `WriteDisable;
	 								end
								end
								`fMOVZ: begin
									aluop_o <= `fMOVZ_OP;
		  						alusel_o <= `fRES_MOVE;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;
								 	if(reg2_o == `ZeroWord) begin
	 									wreg_o <= `WriteEnable;
	 								end else begin
	 									wreg_o <= `WriteDisable;
	 								end		  							
								end
								`fSYNC: begin
									wreg_o <= `WriteDisable;		aluop_o <= `fNOP_OP;
		  						alusel_o <= `fRES_NOP;		reg1_read_o <= 1'b0;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end								
								`fADD: begin
									wreg_o <= `WriteEnable;		aluop_o <= `fADD_OP;
		  						alusel_o <= `fRES_ARITHMETIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end
								`fSUB: begin
									wreg_o <= `WriteEnable;		aluop_o <= `fSUB_OP;
		  						alusel_o <= `fRES_ARITHMETIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end	
								`fJR: begin
									wreg_o <= `WriteDisable;		aluop_o <= `fJR_OP;
		  						alusel_o <= `fRES_JUMP_BRANCH;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  						link_addr_o <= `ZeroWord;
		  						
			            	branch_target_address_o <= reg1_o;
			            	branch_flag_o <= `Branch;
			           
			            next_inst_in_delayslot_o <= `InDelaySlot;
			            instvalid <= `InstValid;	
								end									 											  											
						    default:	begin
						    end
						  endcase
						 end
						default: begin
						end
					endcase	
					end									  
		  	`fORI:			begin                        
		  		wreg_o <= `WriteEnable;		aluop_o <= `fOR_OP;
		  		alusel_o <= `fRES_LOGIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {16'h0, inst_i[15:0]};		wd_o <= inst_i[20:16];
					instvalid <= `InstValid;	
		  	end
		  	`fANDI:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `fAND_OP;
		  		alusel_o <= `fRES_LOGIC;	reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {16'h0, inst_i[15:0]};		wd_o <= inst_i[20:16];		  	
					instvalid <= `InstValid;	
				end	 	
		  	`fXORI:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `fXOR_OP;
		  		alusel_o <= `fRES_LOGIC;	reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {16'h0, inst_i[15:0]};		wd_o <= inst_i[20:16];		  	
					instvalid <= `InstValid;
				end	
			`fLUI:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `fOR_OP;
		  		alusel_o <= `fRES_LOGIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {inst_i[15:0], 16'h0};		wd_o <= inst_i[20:16];		  	
					instvalid <= `InstValid;	
				end			
				`fADDI:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `fADDI_OP;
		  		alusel_o <= `fRES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};		wd_o <= inst_i[20:16];		  	
					instvalid <= `InstValid;	
				end
				`fJ:			begin
		  		wreg_o <= `WriteDisable;		aluop_o <= `fJ_OP;
		  		alusel_o <= `fRES_JUMP_BRANCH; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
		  		link_addr_o <= `ZeroWord;
			    branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
			    branch_flag_o <= `Branch;
			    next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    instvalid <= `InstValid;	
				end
				`fBEQ:			begin
		  		wreg_o <= `WriteDisable;		aluop_o <= `fBEQ_OP;
		  		alusel_o <= `fRES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  		instvalid <= `InstValid;	
		  		if(reg1_o == reg2_o) begin
			    	branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    	branch_flag_o <= `Branch;
			    	next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    end
				end
				`fLB:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `fLB_OP;
		  		alusel_o <= `fRES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
				end
				`fLBU:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `fLBU_OP;
		  		alusel_o <= `fRES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
				end
				`fLH:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `fLH_OP;
		  		alusel_o <= `fRES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
				end
				`fLHU:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `fLHU_OP;
		  		alusel_o <= `fRES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
				end
				`fLW:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `fLW_OP;
		  		alusel_o <= `fRES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
				end
				`fSB:			begin
		  		wreg_o <= `WriteDisable;		aluop_o <= `fSB_OP;
		  		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
		  		alusel_o <= `fRES_LOAD_STORE; 
				end
				`fSH:			begin
		  		wreg_o <= `WriteDisable;		aluop_o <= `fSH_OP;
		  		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
		  		alusel_o <= `fRES_LOAD_STORE; 
				end
				`fSW:			begin
		  		wreg_o <= `WriteDisable;		aluop_o <= `fSW_OP;
		  		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
		  		alusel_o <= `fRES_LOAD_STORE; 
				end
				`fREGIMM_INST:		begin
					case (op4)
						`fBGEZ:	begin
							wreg_o <= `WriteDisable;		aluop_o <= `fBGEZ_OP;
		  				alusel_o <= `fRES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  				instvalid <= `InstValid;	
		  				if(reg1_o[31] == 1'b0) begin
			    			branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    			branch_flag_o <= `Branch;
			    			next_inst_in_delayslot_o <= `InDelaySlot;		  	
			   			end
						end
						`fBLTZ:		begin
						  wreg_o <= `WriteDisable;		aluop_o <= `fBGEZAL_OP;
		  				alusel_o <= `fRES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  				instvalid <= `InstValid;	
		  				if(reg1_o[31] == 1'b1) begin
			    			branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    			branch_flag_o <= `Branch;
			    			next_inst_in_delayslot_o <= `InDelaySlot;		  	
			   			end
						end
						default:	begin
						end
					endcase
				end								
				`fSPECIAL2_INST:		begin
					case ( op3 )
						`fMUL:		begin
							wreg_o <= `WriteEnable;		aluop_o <= `fMUL_OP;
		  				alusel_o <= `fRES_MUL; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	
		  				instvalid <= `InstValid;	  			
						end			
						default:	begin
						end
					endcase      //fSPECIAL_INST2 case
				end																		  	
		    default:			begin
		    end
		  endcase		  //case op
		  
		  if (inst_i[31:21] == 11'b00000000000) begin
		  	if (op3 == `fSLL) begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `fSLL_OP;
		  		alusel_o <= `fRES_SHIFT; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b1;	  	
					imm[4:0] <= inst_i[10:6];		wd_o <= inst_i[15:11];
					instvalid <= `InstValid;	
				end else if ( op3 == `fSRL ) begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `fSRL_OP;
		  		alusel_o <= `fRES_SHIFT; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b1;	  	
					imm[4:0] <= inst_i[10:6];		wd_o <= inst_i[15:11];
					instvalid <= `InstValid;	
				end 
			end		  
		  
		end     
	end        
	

	always @ (*) begin
			stallreq_for_reg1_loadrelate <= `NoStop;	
		if(rst == `RstEnable) begin
			reg1_o <= `ZeroWord;	
		end else if(pre_inst_is_load == 1'b1 && alu_wd_i == reg1_addr_o 
								&& reg1_read_o == 1'b1 ) begin
		  stallreq_for_reg1_loadrelate <= `Stop;

		//���Խ��ô��ִ�н׶ε�ֵ�����Ĵ���1
		end else if((reg1_read_o == 1'b1) && (alu_wreg_i == 1'b1) 
								&& (alu_wd_i == reg1_addr_o)) begin
			reg1_o <= alu_wdata_i; 
		end else if((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) 
								&& (mem_wd_i == reg1_addr_o)) begin
			reg1_o <= mem_wdata_i;
	  end else if(reg1_read_o == 1'b1) begin
	  	reg1_o <= reg1_data_i;
	  end else if(reg1_read_o == 1'b0) begin
	  	reg1_o <= imm;
	  end else begin
	    reg1_o <= `ZeroWord;
	  end
	end
	
	always @ (*) begin
			stallreq_for_reg2_loadrelate <= `NoStop;
		if(rst == `RstEnable) begin
			reg2_o <= `ZeroWord;
		end else if(pre_inst_is_load == 1'b1 && alu_wd_i == reg2_addr_o 
								&& reg2_read_o == 1'b1 ) begin
		  stallreq_for_reg2_loadrelate <= `Stop;

		//�Ĵ���2ͬ��
		end else if((reg2_read_o == 1'b1) && (alu_wreg_i == 1'b1) 
								&& (alu_wd_i == reg2_addr_o)) begin
			reg2_o <= alu_wdata_i; 
		end else if((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) 
								&& (mem_wd_i == reg2_addr_o)) begin
			reg2_o <= mem_wdata_i;			
	  end else if(reg2_read_o == 1'b1) begin
	  	reg2_o <= reg2_data_i;
	  end else if(reg2_read_o == 1'b0) begin
	  	reg2_o <= imm;
	  end else begin
	    reg2_o <= `ZeroWord;
	  end
	end

	always @ (*) begin
		if(rst == `RstEnable) begin
			is_in_delayslot_o <= `NotInDelaySlot;
		end else begin
		  is_in_delayslot_o <= is_in_delayslot_i;		
	  end
	end

endmodule

