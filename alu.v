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
	
	//送到执行阶段的信息
	input wire[`AluOpBus]         aluop_i,
	input wire[`AluSelBus]        alusel_i,
	input wire[`RegBus]           reg1_i,
	input wire[`RegBus]           reg2_i,
	input wire[`RegAddrBus]       wd_i,
	input wire                    wreg_i,
	input wire[`RegBus]           inst_i,
	
	//HI、LO寄存器的值
	input wire[`RegBus]           hi_i,
	input wire[`RegBus]           lo_i,

	//回写阶段的指令是否要写HI、LO，用于检测HI、LO的数据冒险
	input wire[`RegBus]           wb_hi_i,
	input wire[`RegBus]           wb_lo_i,
	input wire                    wb_whilo_i,
	
	//访存阶段的指令是否要写HI、LO，用于检测HI、LO的数据冒险
	input wire[`RegBus]           mem_hi_i,
	input wire[`RegBus]           mem_lo_i,
	input wire                    mem_whilo_i,

	input wire[`DoubleRegBus]     hilo_temp_i,
	input wire[1:0]               cnt_i,


	//是否转移、以及link address
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

	//加载、存储指令接口
	output wire[`AluOpBus]        aluop_o,
	output wire[`RegBus]          mem_addr_o,
	output wire[`RegBus]          reg2_o,

	output reg					 stallreq       			
	
);

	reg[`RegBus] logicout;         //逻辑运算的结果
	reg[`RegBus] shiftres;         //移位运算的结果
	reg[`RegBus] moveres;          //移动操作结果
	reg[`RegBus] arithmeticres;   //保存算数运算结果
	reg[`DoubleRegBus] mulres;	  //保存乘法结果
	reg[`RegBus] HI;              //hi寄存器值，用于MFHI,MFLO,MTHI,MTLO
	reg[`RegBus] LO;              //lo寄存器值
	wire[`RegBus] reg2_i_mux;     //保存源操作数2的补码
	wire[`RegBus] reg1_i_not;	  //保存源操作数1取反的值
	wire[`RegBus] result_sum;    //保存加法结果
	wire ov_sum;                 //溢出标志
	wire reg1_eq_reg2;           //判断两个源操作数是否相等
	wire reg1_lt_reg2;           //判断源操作数1是否小于2
	wire[`RegBus] opdata1_mult; //被乘数
	wire[`RegBus] opdata2_mult; //乘数
	wire[`DoubleRegBus] hilo_temp;
	reg[`DoubleRegBus] hilo_temp1;


  //aluop_o传递到访存阶段，用于加载、存储指令
  assign aluop_o = aluop_i;
  
  //mem_addr传递到访存阶段，是加载、存储指令对应的存储器地址
  assign mem_addr_o = reg1_i + {{16{inst_i[15]}},inst_i[15:0]};

  //将两个操作数也传递到访存阶段，也是为记载、存储指令准备的
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
  //判断是否溢出
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

  //取得乘法操作的操作数，如果是有符号除法且被乘数是负数，那么取补码
	assign opdata1_mult = (((aluop_i == `fMUL_OP))
													&& (reg1_i[31] == 1'b1)) ? (~reg1_i + 1) : reg1_i;
//如果是有符号除法且乘数是负数，那么取补码
  assign opdata2_mult = (((aluop_i == `fMUL_OP))
													&& (reg2_i[31] == 1'b1)) ? (~reg2_i + 1) : reg2_i;	
//临时乘法结果
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

  //得到最新的HI、LO寄存器的值，此处要解决指令数据冒险问题
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

 

	//MFHI、MFLO、MOVN、MOVZ指令
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

