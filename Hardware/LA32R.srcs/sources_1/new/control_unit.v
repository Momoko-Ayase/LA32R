`timescale 1ns / 1ps

/*******************************************************************************
** Company:         Nantong University
** Engineer:        あやせももこ
**
** Create Date:     2025-06-16
** Design Name:     LA32R Single Cycle CPU
** Module Name:     control_unit
** Project Name:    Computer Architecture Course Design
** Target Devices:  Any FPGA
** Tool Versions:   Vivado 2018.1
** Description:
** This is the main control unit for the single-cycle LA32R CPU. It decodes
** the instruction's opcode and function fields to generate all necessary
** control signals for the datapath.
**
** [FIXED] Restructured the case statement to correctly handle instructions
** that share the same opcode, such as LD.W and ST.W.
** [FIXED] ADDI.W decoding now correctly uses opcode 000000 + func4.
** [FIXED] Added new control signal 'ALUAsrc' to force ALU's A-operand to 0
** for LUI12I.W instruction.
** [FINAL FIX] Corrected the logic within the opcode '000000' group.
** The previous version incorrectly evaluated func fields, causing 3R-type
** instructions to fail after the ADDI.W fix. This version ensures both
** ADDI.W and all 3R instructions are decoded correctly according to the ISA.
**
** Revision:
** Revision 0.04 - Fixed logic for 3R-type instructions.
** Revision 0.03 - Fixed ADDI.W decoding and shared opcode logic.
** Revision 0.02 - Corrected case statement logic for shared opcodes.
** Revision 0.01 - File Created
**
*******************************************************************************/

module control_unit (
    input  wire [31:0] instr,       // 指令输入 (Instruction Input)
    input  wire        zero_flag,   // 来自ALU的零标志位 (Zero flag from ALU)
    input  wire        lt_flag,     // 来自ALU的小于标志位 (Less-than flag from ALU)

    output reg         reg_write_en, // 寄存器写使能 (Register Write Enable)
    output reg         mem_to_reg,   // 选择写回寄存器的数据源 (Selects data source for register write-back)
    output reg         mem_write_en, // 存储器写使能 (Memory Write Enable)
    output reg         alu_src,      // 选择ALU的第二操作数源 (Selects ALU's second operand source)
    output reg         src_reg,      // 选择寄存器堆的第二读地址源 (Selects Register File's second read address source)
    output reg  [2:0]  ext_op,       // 立即数扩展控制 (Immediate extender control)
    output reg  [3:0]  alu_op,       // ALU操作控制 (ALU operation control)
    output reg         alu_asrc,     // [NEW] 选择ALU第一操作数源 (Selects ALU's first operand source)
    output wire        pcsource      // PC下一个地址来源选择 (PC next address source selection)
);

    wire [5:0] opcode = instr[31:26];
    
    // -- 功能码字段 --
    wire [3:0] func_2ri12 = instr[25:22]; // For ADDI.W, LD.W, ST.W
    wire [1:0] func_3r_f2 = instr[21:20]; // For 3R-type
    wire [4:0] func_3r_f5 = instr[19:15]; // For 3R-type

    // -- 操作码定义 --
    localparam OP_GROUP_00 = 6'b000000; // Contains 3R & ADDI.W
    localparam OP_LUI12I   = 6'b000101;
    localparam OP_GROUP_0A = 6'b001010; // Contains LD.W, ST.W
    localparam OP_B        = 6'b010100;
    localparam OP_BEQ      = 6'b010110;
    localparam OP_BLT      = 6'b011000;

    localparam ALU_ADD = 4'b0000, ALU_SUB  = 4'b0001, ALU_AND  = 4'b0010,
               ALU_OR  = 4'b0011, ALU_NOR  = 4'b0100, ALU_SLT  = 4'b0101,
               ALU_SLTU= 4'b0110;

    localparam EXT_SI12 = 3'b001, EXT_SI16 = 3'b010, EXT_UI20 = 3'b011, EXT_SI26 = 3'b100;
    
    always @(*) begin
        // -- 默认值 --
        reg_write_en = 1'b0; mem_to_reg = 1'b0; mem_write_en = 1'b0;
        alu_src = 1'b0; src_reg = 1'b0; alu_asrc = 1'b0;
        ext_op = 3'bxxx; alu_op = 4'bxxxx;

        case (opcode)
            OP_GROUP_00: begin
                // 3R 和 ADDI.W 共享主操作码 000000
                if (func_2ri12 == 4'b1010) begin // ADDI.W
                    reg_write_en = 1'b1;
                    alu_src = 1'b1;
                    ext_op = EXT_SI12;
                    alu_op = ALU_ADD;
                end
                // 对于3R指令, func_2ri12 ([25:22]) 字段为 '0000'
                // 并且 func_3r_f2 ([21:20]) 字段为 '01'
                else if (instr[25:22] == 4'b0000 && func_3r_f2 == 2'b01) begin // 3R-type
                    reg_write_en = 1'b1;
                    alu_src = 1'b0;
                    src_reg = 1'b0;
                    case(func_3r_f5)
                        5'b00000: alu_op = ALU_ADD;  5'b00010: alu_op = ALU_SUB;
                        5'b00100: alu_op = ALU_SLT;  5'b00101: alu_op = ALU_SLTU;
                        5'b01000: alu_op = ALU_NOR;  5'b01001: alu_op = ALU_AND;
                        5'b01010: alu_op = ALU_OR;   default:  alu_op = 4'bxxxx;
                    endcase
                end
            end
            OP_LUI12I: begin
                reg_write_en = 1'b1; alu_src = 1'b1; alu_asrc = 1'b1;
                ext_op = EXT_UI20; alu_op = ALU_ADD;
            end
            OP_GROUP_0A: begin
                if (func_2ri12 == 4'b0010) begin // LD.W
                    reg_write_en = 1'b1; mem_to_reg = 1'b1;
                    alu_src = 1'b1; ext_op = EXT_SI12; alu_op = ALU_ADD;
                end
                else if (func_2ri12 == 4'b0110) begin // ST.W
                    mem_write_en = 1'b1; alu_src = 1'b1; src_reg = 1'b1;
                    ext_op = EXT_SI12; alu_op = ALU_ADD;
                end
            end
            OP_B:   ext_op = EXT_SI26;
            OP_BEQ: begin alu_src = 1'b0; src_reg = 1'b1; ext_op = EXT_SI16; alu_op = ALU_SUB; end
            OP_BLT: begin alu_src = 1'b0; src_reg = 1'b1; ext_op = EXT_SI16; alu_op = ALU_SUB; end
            default: begin end
        endcase
    end
    
    wire beq_cond = (opcode == OP_BEQ) && zero_flag;
    wire blt_cond = (opcode == OP_BLT) && lt_flag;
    wire b_cond   = (opcode == OP_B);

    assign pcsource = beq_cond || blt_cond || b_cond;
endmodule