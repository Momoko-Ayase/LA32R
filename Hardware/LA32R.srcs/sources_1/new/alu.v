`timescale 1ns / 1ps

/*******************************************************************************
** Company:         Nantong University
** Engineer:        あやせももこ
**
** Create Date:     2025-06-16
** Design Name:     LA32R Single Cycle CPU
** Module Name:     alu
** Project Name:    Computer Architecture Course Design
** Target Devices:  Any FPGA
** Tool Versions:   Vivado 2018.1
** Description:
** This module implements the Arithmetic Logic Unit (ALU) for the LA32R CPU.
**
** [FIXED] The implementation of SLT now uses the $signed() system function
** to correctly handle comparisons that could cause overflow, such as
** comparing a positive and a negative number.
**
** Revision:
** Revision 0.02 - Corrected SLT implementation using $signed().
** Revision 0.01 - File Created
**
*******************************************************************************/

module alu (
    input  wire [31:0] a,         // 操作数 A (Operand A)
    input  wire [31:0] b,         // 操作数 B (Operand B)
    input  wire [3:0]  alu_op,    // ALU 操作控制码 (ALU Operation Control Code)
    output reg  [31:0] result,    // 运算结果 (Result)
    output wire        zero,      // 零标志位 (Zero Flag)
    output wire        lt         // 小于标志位 (Less Than Flag for BLT)
);

    // 定义ALU操作码的参数，增强可读性
    // Define parameters for ALU operations to enhance readability
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_NOR  = 4'b0100;
    localparam ALU_SLT  = 4'b0101;
    localparam ALU_SLTU = 4'b0110;

    // 减法结果的临时线网
    // Temporary wire for subtraction result
    wire [31:0] sub_result = a - b;
    
    // [FIX] 使用$signed()进行稳健的有符号比较
    // [FIX] Use $signed() for robust signed comparison
    wire slt_res = ($signed(a) < $signed(b));
    
    // 无符号比较
    // Unsigned comparison
    wire sltu_res = (a < b);

    // 主组合逻辑: 根据alu_op计算结果
    // Main combinational logic: calculate result based on alu_op
    always @(*) begin
        case (alu_op)
            ALU_ADD:  result = a + b;                  // 加法 (Addition)
            ALU_SUB:  result = sub_result;             // 减法 (Subtraction)
            ALU_AND:  result = a & b;                  // 与 (AND)
            ALU_OR:   result = a | b;                  // 或 (OR)
            ALU_NOR:  result = ~(a | b);               // 或非 (NOR)
            ALU_SLT:  result = {31'b0, slt_res};       // 有符号小于比较 (Set on Less Than, Signed)
            ALU_SLTU: result = {31'b0, sltu_res};      // 无符号小于比较 (Set on Less Than, Unsigned)
            default:  result = 32'hxxxxxxxx;           // 默认情况，输出不定态 (Default case, output undefined)
        endcase
    end

    // 零标志位输出: 当减法结果为0时置1，用于BEQ指令
    // Zero flag output: set to 1 when the subtraction result is zero, for BEQ instruction
    assign zero = (sub_result == 32'h00000000);

    // 小于标志位输出: 用于BLT指令
    // Less Than flag output: for BLT instruction
    assign lt = slt_res;

endmodule