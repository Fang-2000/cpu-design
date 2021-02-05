`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/30 20:13:46
// Design Name: 
// Module Name: fmips_cpu
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
module fmips_cpu(

	input	wire				  clk,
	input wire					  rst,           //��λ�ź�
	
 
	input wire[`RegBus]           rom_data_i,    //��ָ��洢��ȡָ��
	output wire[`RegBus]           rom_addr_o,   //�����ָ��洢���ĵ�ַ
	output wire                    rom_ce_o,     //ָ��洢��ʹ��
	
  //�������ݴ洢��ram
	input wire[`RegBus]           ram_data_i,    //��ram�ж�ȡ������
	output wire[`RegBus]           ram_addr_o,   //Ҫ���ʵĵ����ݴ洢���ĵ�ַ
	output wire[`RegBus]           ram_data_o,   //Ҫд��ram������
	output wire                    ram_we_o,     //�Ƿ��ram����д����
	output wire[3:0]               ram_sel_o,    //�ֽ�ѡ��
	output wire[3:0]               ram_ce_o      //ramʹ���ź�
	
);

	wire[`InstAddrBus] pc;
	wire[`InstAddrBus] id_pc_i;
	wire[`InstBus] id_inst_i;
	
	//��������׶�IDģ��������ID/ALUģ�������
	wire[`AluOpBus] id_aluop_o;
	wire[`AluSelBus] id_alusel_o;
	wire[`RegBus] id_reg1_o;
	wire[`RegBus] id_reg2_o;
	wire id_wreg_o;
	wire[`RegAddrBus] id_wd_o;
	wire id_is_in_delayslot_o;
    wire[`RegBus] id_link_address_o;	
    wire[`RegBus] id_inst_o;
	
	//����ID/ALUģ��������ִ�н׶�ALUģ�������
	wire[`AluOpBus] alu_aluop_i;
	wire[`AluSelBus] alu_alusel_i;
	wire[`RegBus] alu_reg1_i;
	wire[`RegBus] alu_reg2_i;
	wire alu_wreg_i;
	wire[`RegAddrBus] alu_wd_i;
	wire alu_is_in_delayslot_i;	
  wire[`RegBus] alu_link_address_i;	
  wire[`RegBus] alu_inst_i;
	
	//����ִ�н׶�ALUģ��������ALU/MEMģ�������
	wire alu_wreg_o;
	wire[`RegAddrBus] alu_wd_o;
	wire[`RegBus] alu_wdata_o;
	wire[`RegBus] alu_hi_o;
	wire[`RegBus] alu_lo_o;
	wire alu_whilo_o;
	wire[`AluOpBus] alu_aluop_o;
	wire[`RegBus] alu_mem_addr_o;
	wire[`RegBus] alu_reg1_o;
	wire[`RegBus] alu_reg2_o;	

	//����ALU/MEMģ��������ô�׶�MEMģ�������
	wire mem_wreg_i;
	wire[`RegAddrBus] mem_wd_i;
	wire[`RegBus] mem_wdata_i;
	wire[`RegBus] mem_hi_i;
	wire[`RegBus] mem_lo_i;
	wire mem_whilo_i;		
	wire[`AluOpBus] mem_aluop_i;
	wire[`RegBus] mem_mem_addr_i;
	wire[`RegBus] mem_reg1_i;
	wire[`RegBus] mem_reg2_i;		

	//���ӷô�׶�MEMģ��������MEM/WBģ�������
	wire mem_wreg_o;
	wire[`RegAddrBus] mem_wd_o;
	wire[`RegBus] mem_wdata_o;
	wire[`RegBus] mem_hi_o;
	wire[`RegBus] mem_lo_o;
	wire mem_whilo_o;		
	
	//����MEM/WBģ���������д�׶ε�����	
	wire wb_wreg_i;
	wire[`RegAddrBus] wb_wd_i;
	wire[`RegBus] wb_wdata_i;
	wire[`RegBus] wb_hi_i;
	wire[`RegBus] wb_lo_i;
	wire wb_whilo_i;	
	
	//��������׶�IDģ����ͨ�üĴ���MUTIREGģ��
  wire reg1_read;
  wire reg2_read;
  wire[`RegBus] reg1_data;
  wire[`RegBus] reg2_data;
  wire[`RegAddrBus] reg1_addr;
  wire[`RegAddrBus] reg2_addr;

	//����ִ�н׶���hiloģ����������ȡHI��LO�Ĵ���
	wire[`RegBus] 	hi;
	wire[`RegBus]   lo;

  //����ִ�н׶���alu_regģ��
	wire[`DoubleRegBus] hilo_temp_o;
	wire[1:0] cnt_o;
	
	wire[`DoubleRegBus] hilo_temp_i;
	wire[1:0] cnt_i;

	wire is_in_delayslot_i;
	wire is_in_delayslot_o;
	wire next_inst_in_delayslot_o;
	wire id_branch_flag_o;
	wire[`RegBus] branch_target_address;

	wire[5:0] stall;
	wire stallreq_from_id;	
	wire stallreq_from_alu;
  
  //pc����
	pc pc0(
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.branch_flag_i(id_branch_flag_o),
		.branch_target_address_i(branch_target_address),		
		.pc(pc),
		.ce(rom_ce_o)		
			
	);
	
  assign rom_addr_o = pc;

  //IF/IDģ������
	if_id if_id0(
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.if_pc(pc),
		.if_inst(rom_data_i),
		.id_pc(id_pc_i),
		.id_inst(id_inst_i)      	
	);
	
	//����׶�IDģ��
	id id0(
		.rst(rst),
		.pc_i(id_pc_i),
		.inst_i(id_inst_i),

  	.alu_aluop_i(alu_aluop_o),

		.reg1_data_i(reg1_data),
		.reg2_data_i(reg2_data),

	  //����ִ�н׶ε�ָ��Ҫд���Ŀ�ļĴ�����Ϣ
		.alu_wreg_i(alu_wreg_o),
		.alu_wdata_i(alu_wdata_o),
		.alu_wd_i(alu_wd_o),

	  //���ڷô�׶ε�ָ��Ҫд���Ŀ�ļĴ�����Ϣ
		.mem_wreg_i(mem_wreg_o),
		.mem_wdata_i(mem_wdata_o),
		.mem_wd_i(mem_wd_o),

	  .is_in_delayslot_i(is_in_delayslot_i),

		//�͵�mutireg����Ϣ
		.reg1_read_o(reg1_read),
		.reg2_read_o(reg2_read), 	  

		.reg1_addr_o(reg1_addr),
		.reg2_addr_o(reg2_addr), 
	  
		//�͵�ID/ALUģ�����Ϣ
		.aluop_o(id_aluop_o),
		.alusel_o(id_alusel_o),
		.reg1_o(id_reg1_o),
		.reg2_o(id_reg2_o),
		.wd_o(id_wd_o),
		.wreg_o(id_wreg_o),
		.inst_o(id_inst_o),

	 	.next_inst_in_delayslot_o(next_inst_in_delayslot_o),	
		.branch_flag_o(id_branch_flag_o),
		.branch_target_address_o(branch_target_address),       
		.link_addr_o(id_link_address_o),
		
		.is_in_delayslot_o(id_is_in_delayslot_o),
		
		.stallreq(stallreq_from_id)		
	);

  //�Ĵ�����mutireg����
	mutireg mutireg1(
		.clk (clk),
		.rst (rst),
		.we	(wb_wreg_i),
		.waddr (wb_wd_i),
		.wdata (wb_wdata_i),
		.re1 (reg1_read),
		.raddr1 (reg1_addr),
		.rdata1 (reg1_data),
		.re2 (reg2_read),
		.raddr2 (reg2_addr),
		.rdata2 (reg2_data)
	);

	//ID/ALUģ��
	id_alu id_alu0(
		.clk(clk),
		.rst(rst),
		
		.stall(stall),
		
		//������׶�IDģ�鴫�ݵ���Ϣ
		.id_aluop(id_aluop_o),
		.id_alusel(id_alusel_o),
		.id_reg1(id_reg1_o),
		.id_reg2(id_reg2_o),
		.id_wd(id_wd_o),
		.id_wreg(id_wreg_o),
		.id_link_address(id_link_address_o),
		.id_is_in_delayslot(id_is_in_delayslot_o),
		.next_inst_in_delayslot_i(next_inst_in_delayslot_o),		
		.id_inst(id_inst_o),		
	
		//���ݵ�ִ�н׶�ALUģ�����Ϣ
		.alu_aluop(alu_aluop_i),
		.alu_alusel(alu_alusel_i),
		.alu_reg1(alu_reg1_i),
		.alu_reg2(alu_reg2_i),
		.alu_wd(alu_wd_i),
		.alu_wreg(alu_wreg_i),
		.alu_link_address(alu_link_address_i),
  	.alu_is_in_delayslot(alu_is_in_delayslot_i),
		.is_in_delayslot_o(is_in_delayslot_i),
		.alu_inst(alu_inst_i)		
	);		
	
	//aluģ��
   alu alu0(
		.rst(rst),
	
		//�͵�ִ�н׶�ALUģ�����Ϣ
		.aluop_i(alu_aluop_i),
		.alusel_i(alu_alusel_i),
		.reg1_i(alu_reg1_i),
		.reg2_i(alu_reg2_i),
		.wd_i(alu_wd_i),
		.wreg_i(alu_wreg_i),
		.hi_i(hi),
		.lo_i(lo),
		.inst_i(alu_inst_i),

	  .wb_hi_i(wb_hi_i),
	  .wb_lo_i(wb_lo_i),
	  .wb_whilo_i(wb_whilo_i),
	  .mem_hi_i(mem_hi_o),
	  .mem_lo_i(mem_lo_o),
	  .mem_whilo_i(mem_whilo_o),

	  .hilo_temp_i(hilo_temp_i),
	  .cnt_i(cnt_i),

	  .link_address_i(alu_link_address_i),
		.is_in_delayslot_i(alu_is_in_delayslot_i),	  
			  
	  //aluģ��������ALU/MEMģ����Ϣ
		.wd_o(alu_wd_o),
		.wreg_o(alu_wreg_o),
		.wdata_o(alu_wdata_o),

		.hi_o(alu_hi_o),
		.lo_o(alu_lo_o),
		.whilo_o(alu_whilo_o),

		.hilo_temp_o(hilo_temp_o),
		.cnt_o(cnt_o),

		.aluop_o(alu_aluop_o),
		.mem_addr_o(alu_mem_addr_o),
		.reg2_o(alu_reg2_o),
		
		.stallreq(stallreq_from_alu)     				
		
	);

  //ALU/MEMģ��
  alu_mem alu_mem0(
		.clk(clk),
		.rst(rst),
	  
	  .stall(stall),
	  
		//����ִ�н׶�ALUģ�����Ϣ	
		.alu_wd(alu_wd_o),
		.alu_wreg(alu_wreg_o),
		.alu_wdata(alu_wdata_o),
		.alu_hi(alu_hi_o),
		.alu_lo(alu_lo_o),
		.alu_whilo(alu_whilo_o),		

  	.alu_aluop(alu_aluop_o),
		.alu_mem_addr(alu_mem_addr_o),
		.alu_reg2(alu_reg2_o),			

		.hilo_i(hilo_temp_o),
		.cnt_i(cnt_o),	

		//�͵��ô�׶�MEMģ�����Ϣ
		.mem_wd(mem_wd_i),
		.mem_wreg(mem_wreg_i),
		.mem_wdata(mem_wdata_i),
		.mem_hi(mem_hi_i),
		.mem_lo(mem_lo_i),
		.mem_whilo(mem_whilo_i),

  	.mem_aluop(mem_aluop_i),
		.mem_mem_addr(mem_mem_addr_i),
		.mem_reg2(mem_reg2_i),
				
		.hilo_o(hilo_temp_i),
		.cnt_o(cnt_i)
						       	
	);
	
  //MEMģ������
	mem mem0(
		.rst(rst),
	
		//����ALU/MEMģ�����Ϣ	
		.wd_i(mem_wd_i),
		.wreg_i(mem_wreg_i),
		.wdata_i(mem_wdata_i),
		.hi_i(mem_hi_i),
		.lo_i(mem_lo_i),
		.whilo_i(mem_whilo_i),		

  	.aluop_i(mem_aluop_i),
		.mem_addr_i(mem_mem_addr_i),
		.reg2_i(mem_reg2_i),
	
		//����RAM����Ϣ
		.mem_data_i(ram_data_i),
	  
		//�͵�MEM/WBģ�����Ϣ
		.wd_o(mem_wd_o),
		.wreg_o(mem_wreg_o),
		.wdata_o(mem_wdata_o),
		.hi_o(mem_hi_o),
		.lo_o(mem_lo_o),
		.whilo_o(mem_whilo_o),
		
		//�͵�memory����Ϣ
		.mem_addr_o(ram_addr_o),
		.mem_we_o(ram_we_o),
		.mem_sel_o(ram_sel_o),
		.mem_data_o(ram_data_o),
		.mem_ce_o(ram_ce_o)		
	);

  //MEM/WBģ��
	mem_wb mem_wb0(
		.clk(clk),
		.rst(rst),

    .stall(stall),

		//���Էô�׶�MEMģ�����Ϣ	
		.mem_wd(mem_wd_o),
		.mem_wreg(mem_wreg_o),
		.mem_wdata(mem_wdata_o),
		.mem_hi(mem_hi_o),
		.mem_lo(mem_lo_o),
		.mem_whilo(mem_whilo_o),		
	
		//�͵���д�׶ε���Ϣ
		.wb_wd(wb_wd_i),
		.wb_wreg(wb_wreg_i),
		.wb_wdata(wb_wdata_i),
		.wb_hi(wb_hi_i),
		.wb_lo(wb_lo_i),
		.wb_whilo(wb_whilo_i)		
									       	
	);

	hilo_reg hilo_reg0(
		.clk(clk),
		.rst(rst),
	
		//д�˿�
		.we(wb_whilo_i),
		.hi_i(wb_hi_i),
		.lo_i(wb_lo_i),
	
		//���˿�1
		.hi_o(hi),
		.lo_o(lo)	
	);
	
	ctrl ctrl0(
		.rst(rst),
	
		.stallreq_from_id(stallreq_from_id),
	
  	//����ִ�н׶ε���ͣ����
		.stallreq_from_alu(stallreq_from_alu),

		.stall(stall)       	
	);

endmodule

