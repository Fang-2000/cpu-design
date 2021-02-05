`define RstEnable 1'b1
`define RstDisable 1'b0
`define ZeroWord 32'h00000000
`define WriteEnable 1'b1
`define WriteDisable 1'b0
`define ReadEnable 1'b1
`define ReadDisable 1'b0
`define AluOpBus 7:0          //ÒëÂë½×¶ÎÊä³öµÄaluopµÄ¿í¶È
`define AluSelBus 2:0         //ÒëÂë½×¶ÎÊä³öµÄaluselµÄ¿í¶È
`define InstValid 1'b0
`define InstInvalid 1'b1
`define Stop 1'b1
`define NoStop 1'b0
`define InDelaySlot 1'b1
`define NotInDelaySlot 1'b0
`define Branch 1'b1
`define NotBranch 1'b0
`define InterruptAssert 1'b1
`define InterruptNotAssert 1'b0
`define TrapAssert 1'b1
`define TrapNotAssert 1'b0
`define True_v 1'b1
`define False_v 1'b0
`define ChipEnable 1'b1
`define ChipDisable 1'b0


//Ö¸Áî
`define fAND  6'b100100
`define fOR   6'b100101
`define fXOR 6'b100110
`define fNOR 6'b100111
`define fANDI 6'b001100
`define fORI  6'b001101
`define fXORI 6'b001110
`define fLUI 6'b001111

`define fSLL  6'b000000
`define fSRL  6'b000010
`define fSYNC  6'b001111

`define fMOVZ  6'b001010
`define fMOVN  6'b001011
`define fMFHI  6'b010000
`define fMTHI  6'b010001
`define fMFLO  6'b010010
`define fMTLO  6'b010011
 
`define fADD  6'b100000
`define fSUB  6'b100010
`define fADDI  6'b001000

`define fMUL  6'b000010

`define fDIV  6'b011010
`define fDIVU  6'b011011

`define fJ  6'b000010
`define fJR  6'b001000
`define fBEQ  6'b000100
`define fBGEZ  5'b00001
`define fBLTZ  5'b00000
`define fBGEZAL  5'b10001
`define fLB  6'b100000
`define fLBU  6'b100100
`define fLH  6'b100001
`define fLHU  6'b100101
`define fLW  6'b100011
`define fSB  6'b101000
`define fSH  6'b101001
`define fSW  6'b101011


`define fNOP 6'b000000
`define SSNOP 32'b00000000000000000000000001000000

`define fSPECIAL_INST 6'b000000
`define fREGIMM_INST 6'b000001
`define fSPECIAL2_INST 6'b011100

//AluOp
`define fAND_OP   8'b00100100
`define fOR_OP    8'b00100101
`define fXOR_OP  8'b00100110
`define fNOR_OP  8'b00100111
`define fANDI_OP  8'b01011001
`define fORI_OP  8'b01011010
`define fXORI_OP  8'b01011011
`define fLUI_OP  8'b01011100   

`define fSLL_OP  8'b01111100
`define fSRL_OP  8'b00000010

`define fMOVZ_OP  8'b00001010
`define fMOVN_OP  8'b00001011
`define fMFHI_OP  8'b00010000
`define fMTHI_OP  8'b00010001
`define fMFLO_OP  8'b00010010
`define fMTLO_OP  8'b00010011
 
`define fADD_OP  8'b00100000
`define fSUB_OP  8'b00100010
`define fADDI_OP  8'b01010101

`define fMUL_OP  8'b10101001

`define fDIV_OP  8'b00011010
`define fDIVU_OP  8'b00011011

`define fJ_OP  8'b01001111
`define fJR_OP  8'b00001000
`define fBEQ_OP  8'b01010001
`define fBGEZ_OP  8'b01000001
`define fBLTZ_OP  8'b01000000
`define fBGEZAL_OP  8'b01001011
`define fLB_OP  8'b11100000
`define fLBU_OP  8'b11100100
`define fLH_OP  8'b11100001
`define fLHU_OP  8'b11100101
`define fLW_OP  8'b11100011
`define fSB_OP  8'b11101000
`define fSH_OP  8'b11101001
`define fSW_OP  8'b11101011
`define fSYNC_OP  8'b00001111

`define fNOP_OP    8'b00000000

//AluSel
`define fRES_LOGIC 3'b001
`define fRES_SHIFT 3'b010
`define fRES_MOVE 3'b011	
`define fRES_ARITHMETIC 3'b100	
`define fRES_MUL 3'b101
`define fRES_JUMP_BRANCH 3'b110
`define fRES_LOAD_STORE 3'b111	

`define fRES_NOP 3'b000


//Ö¸Áî´æ´¢Æ÷rom
`define InstAddrBus 31:0
`define InstBus 31:0
`define InstMemNum 131071
`define InstMemNumLog2 17

//Êý¾Ý´æ´¢Æ÷ram
`define DataAddrBus 31:0
`define DataBus 31:0
`define DataMemNum 131071
`define DataMemNumLog2 17
`define ByteWidth 7:0

//¼Ä´æÆ÷×émutireg
`define RegAddrBus 4:0
`define RegBus 31:0
`define RegWidth 32
`define DoubleRegWidth 64
`define DoubleRegBus 63:0
`define RegNum 32
`define RegNumLog2 5
`define NOPRegAddr 5'b00000

//³ý·¨div
`define DivFree 2'b00
`define DivByZero 2'b01
`define DivOn 2'b10
`define DivEnd 2'b11
`define DivResultReady 1'b1
`define DivResultNotReady 1'b0
`define DivStart 1'b1
`define DivStop 1'b0