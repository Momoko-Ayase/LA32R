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
** 本模块是LA32R单周期CPU的主控制单元。它负责对指令的操作码(opcode)和功能码(func)字段
** 进行译码，并据此生成数据通路所需的所有控制信号。
** 该单元能够正确处理具有相同主操作码的指令（如LD.W和ST.W），
** 以及特殊指令（如ADDI.W, LUI12I.W）和所有3R类型指令的译码。
** Features:
** - 译码LA32R指令集中的所有指令。
** - 生成寄存器写使能（reg_write_en）、存储器到寄存器（mem_to_reg）、存储器写使能（mem_write_en）等控制信号。
** - 控制ALU的操作（alu_op）和操作数来源（alu_src, alu_asrc）。
** - 控制立即数扩展器的操作类型（ext_op）。
** - 根据指令类型和ALU标志（zero_flag, lt_flag）确定程序计数器（PC）的下一个来源（pcsource）。
** - 为LUI12I.W指令提供特殊的ALU第一操作数选择信号（alu_asrc）。
** Revision:
** Revision 0.04 - 修正了3R类型指令的译码逻辑，确保与ADDI.W指令的区分和正确执行。
** Revision 0.03 - 修正了ADDI.W的译码逻辑，并处理了共享操作码指令的译码问题。引入alu_asrc信号。
** Revision 0.02 - 调整了case语句逻辑以正确处理共享操作码。
** Revision 0.01 - 文件创建。
** Additional Comments:
** 控制信号的默认值在always块的开始处设置，以确保在未指定时信号处于安全状态。
*******************************************************************************/

module control_unit (
    input  wire [31:0] instr,       // 输入的32位指令
    input  wire        zero_flag,   // ALU运算结果的零标志位输入
    input  wire        lt_flag,     // ALU运算结果的小于标志位输入 (用于BLT)

    output reg         reg_write_en, // 寄存器文件写使能信号
    output reg         mem_to_reg,   // 数据选择信号：选择写入寄存器的数据来源 (0: ALU结果, 1: 存储器数据)
    output reg         mem_write_en, // 数据存储器写使能信号
    output reg         alu_src,      // 数据选择信号：选择ALU的B操作数来源 (0: 寄存器, 1: 立即数)
    output reg         src_reg,      // 数据选择信号：选择寄存器堆的第二个读地址来源 (0: instr[14:10], 1: instr[4:0])
    output reg  [2:0]  ext_op,       // 立即数扩展单元操作控制信号
    output reg  [3:0]  alu_op,       // ALU操作类型控制信号
    output reg         alu_asrc,     // 数据选择信号：选择ALU的A操作数来源 (0: 寄存器, 1: PC / 0 for LUI12I)
    output wire        pcsource      // PC下一个地址来源选择信号 (0: PC+4, 1: 分支/跳转目标地址)
);

    // 从指令中提取操作码字段
    wire [5:0] opcode = instr[31:26];
    
    // -- 从指令中提取功能码字段 --
    wire [3:0] func_2ri12 = instr[25:22]; // 用于 ADDI.W, LD.W, ST.W 等指令类型
    wire [1:0] func_3r_f2 = instr[21:20]; // 用于 3R 类型指令的辅助功能码
    wire [4:0] func_3r_f5 = instr[19:15]; // 用于 3R 类型指令的主要功能码

    // -- LA32R指令集操作码定义 (部分) --
    localparam OP_GROUP_00 = 6'b000000; // 包含3R类型指令 (如ADD, SUB) 和 ADDI.W 指令
    localparam OP_LUI12I   = 6'b000101; // LUI12I.W 指令的操作码
    localparam OP_GROUP_0A = 6'b001010; // 包含 LD.W 和 ST.W 指令
    localparam OP_B        = 6'b010100; // 无条件分支 B 指令
    localparam OP_BEQ      = 6'b010110; // 条件分支 BEQ 指令 (相等则跳转)
    localparam OP_BLT      = 6'b011000; // 条件分支 BLT 指令 (有符号小于则跳转)

    // -- ALU操作控制码定义 (与alu模块一致) --
    localparam ALU_ADD = 4'b0000, ALU_SUB  = 4'b0001, ALU_AND  = 4'b0010,
               ALU_OR  = 4'b0011, ALU_NOR  = 4'b0100, ALU_SLT  = 4'b0101,
               ALU_SLTU= 4'b0110;

    // -- 立即数扩展操作类型定义 --
    localparam EXT_SI12 = 3'b001, EXT_SI16 = 3'b010, EXT_UI20 = 3'b011, EXT_SI26 = 3'b100; // SI:有符号, UI:无符号
    
    // 主控制逻辑：根据操作码和功能码生成所有控制信号
    always @(*) begin
        // -- 控制信号默认值设定 --
        reg_write_en = 1'b0; // 默认不写入寄存器
        mem_to_reg   = 1'b0; // 默认ALU结果写入寄存器
        mem_write_en = 1'b0; // 默认不写入存储器
        alu_src      = 1'b0; // 默认ALU第二操作数来自寄存器
        src_reg      = 1'b0; // 默认寄存器堆第二读地址来自instr[14:10] (rk)
        alu_asrc     = 1'b0; // 默认ALU第一操作数来自寄存器
        ext_op       = 3'bxxx; // 默认立即数扩展操作无效
        alu_op       = 4'bxxxx; // 默认ALU操作无效

        case (opcode)
            OP_GROUP_00: begin // 处理主操作码为 000000 的指令 (3R类型 和 ADDI.W)
                // 3R 和 ADDI.W 指令共享此主操作码，需通过功能码进一步区分
                if (func_2ri12 == 4'b1010) begin // ADDI.W 指令 (instr[25:22] == 4'b1010)
                    reg_write_en = 1'b1;       // 需要写回寄存器
                    alu_src      = 1'b1;       // ALU第二操作数为立即数
                    ext_op       = EXT_SI12;   // 12位有符号立即数扩展
                    alu_op       = ALU_ADD;    // ALU执行加法
                end
                // 对于3R类型指令, instr[25:22] (func_2ri12) 应为 '0000'
                // 且 instr[21:20] (func_3r_f2) 应为 '01'
                else if (instr[25:22] == 4'b0000 && func_3r_f2 == 2'b01) begin // 3R类型指令
                    reg_write_en = 1'b1;       // 需要写回寄存器
                    alu_src      = 1'b0;       // ALU第二操作数来自寄存器
                    src_reg      = 1'b0;       // 寄存器堆第二读地址来自instr[14:10] (rk, 源操作数2)
                    case(func_3r_f5)           // 根据 instr[19:15] (func_3r_f5) 决定具体ALU操作
                        5'b00000: alu_op = ALU_ADD;  // ADD
                        5'b00010: alu_op = ALU_SUB;  // SUB
                        5'b00100: alu_op = ALU_SLT;  // SLT
                        5'b00101: alu_op = ALU_SLTU; // SLTU
                        5'b01000: alu_op = ALU_NOR;  // NOR
                        5'b01001: alu_op = ALU_AND;  // AND
                        5'b01010: alu_op = ALU_OR;   // OR
                        default:  alu_op = 4'bxxxx; // 未定义功能码则ALU操作无效
                    endcase
                end
            end
            OP_LUI12I: begin // LUI12I.W 指令 (高12位立即数加载)
                reg_write_en = 1'b1;       // 需要写回寄存器
                alu_src      = 1'b1;       // ALU第二操作数为立即数
                alu_asrc     = 1'b1;       // ALU第一操作数特殊处理 (对于LUI，通常是将立即数左移，另一输入为0)
                ext_op       = EXT_UI20;   // 20位无符号立即数扩展 (实际使用高12位)
                alu_op       = ALU_ADD;    // ALU执行加法 (0 + 扩展后的立即数)
            end
            OP_GROUP_0A: begin // 处理主操作码为 001010 的指令 (LD.W 和 ST.W)
                if (func_2ri12 == 4'b0010) begin // LD.W 指令 (加载字)
                    reg_write_en = 1'b1;       // 需要写回寄存器
                    mem_to_reg   = 1'b1;       // 数据来自存储器
                    alu_src      = 1'b1;       // ALU第二操作数为立即数 (地址偏移)
                    ext_op       = EXT_SI12;   // 12位有符号立即数扩展 (地址偏移)
                    alu_op       = ALU_ADD;    // ALU计算基地址+偏移
                end
                else if (func_2ri12 == 4'b0110) begin // ST.W 指令 (存储字)
                    mem_write_en = 1'b1;       // 需要写入存储器
                    alu_src      = 1'b1;       // ALU第二操作数为立即数 (地址偏移)
                    src_reg      = 1'b1;       // 寄存器堆第二读地址来自instr[4:0] (rd, 源数据寄存器)
                    ext_op       = EXT_SI12;   // 12位有符号立即数扩展 (地址偏移)
                    alu_op       = ALU_ADD;    // ALU计算基地址+偏移
                end
            end
            OP_B: begin // 无条件分支指令
                ext_op = EXT_SI26; // 26位有符号立即数扩展
            end
            OP_BEQ: begin // 相等则分支指令
                alu_src      = 1'b0;       // ALU比较两个寄存器的值
                src_reg      = 1'b1;       // 寄存器堆第二读地址来自instr[4:0] (rd)
                ext_op       = EXT_SI16;   // 16位有符号立即数扩展 (分支偏移)
                alu_op       = ALU_SUB;    // ALU执行减法以判断是否相等 (结果送zero_flag)
            end
            OP_BLT: begin // 小于则分支指令
                alu_src      = 1'b0;       // ALU比较两个寄存器的值
                src_reg      = 1'b1;       // 寄存器堆第二读地址来自instr[4:0] (rd)
                ext_op       = EXT_SI16;   // 16位有符号立即数扩展 (分支偏移)
                alu_op       = ALU_SUB;    // ALU执行减法以判断是否小于 (结果送lt_flag)
            end
            default: begin end // 其他未定义操作码，不产生任何有效控制信号（使用默认值）
        endcase
    end
    
    // 分支条件逻辑：根据操作码和ALU标志位判断是否进行分支
    wire beq_cond = (opcode == OP_BEQ) && zero_flag; // BEQ 指令且零标志位为1
    wire blt_cond = (opcode == OP_BLT) && lt_flag;   // BLT 指令且小于标志位为1
    wire b_cond   = (opcode == OP_B);                // B 指令无条件跳转

    // PC来源控制信号：如果任一分支条件满足，则pcsource为1，选择分支目标地址；否则为0，选择PC+4
    assign pcsource = beq_cond || blt_cond || b_cond;
endmodule