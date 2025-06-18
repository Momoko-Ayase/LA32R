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
** 本模块为LA32R CPU实现算术逻辑单元(ALU)。
** 它负责执行CPU指令所规定的算术运算（如加法、减法）和逻辑运算（如与、或、或非）。
** 同时，它也处理比较操作（如有符号小于、无符号小于）并产生相应的标志位。
** Features:
** - 支持加法、减法、与、或、或非等基本运算。
** - 支持有符号小于比较 (SLT) 和无符号小于比较 (SLTU)。
** - SLT 操作使用 $signed() 以确保对有符号数的正确比较。
** - 输出运算结果以及零标志位和小于标志位。
** Revision:
** Revision 0.02 - 修正了SLT指令的实现，使用$signed()处理有符号比较，确保结果的正确性。
** Revision 0.01 - 文件创建。
** Additional Comments:
** 无。
*******************************************************************************/

module alu (
    input  wire [31:0] a,         // 操作数A
    input  wire [31:0] b,         // 操作数B
    input  wire [3:0]  alu_op,    // ALU操作控制信号
    output reg  [31:0] result,    // ALU运算结果
    output wire        zero,      // 零标志位，用于判断结果是否为零
    output wire        lt         // 小于标志位，用于BLT指令判断
);

    // 定义ALU支持的各种操作码，使用localparam增强代码的可读性和可维护性
    localparam ALU_ADD  = 4'b0000; // 加法操作
    localparam ALU_SUB  = 4'b0001; // 减法操作
    localparam ALU_AND  = 4'b0010; // 逻辑与操作
    localparam ALU_OR   = 4'b0011; // 逻辑或操作
    localparam ALU_NOR  = 4'b0100; // 逻辑或非操作
    localparam ALU_SLT  = 4'b0101; // 有符号小于比较操作
    localparam ALU_SLTU = 4'b0110; // 无符号小于比较操作

    // 执行减法操作，结果存储在临时线网sub_result中
    wire [31:0] sub_result = a - b;
    
    // 执行有符号小于比较，使用$signed()确保对负数的正确处理
    wire slt_res = ($signed(a) < $signed(b));
    
    // 执行无符号小于比较
    wire sltu_res = (a < b);

    // ALU核心逻辑：根据alu_op输入选择执行相应的操作
    always @(*) begin
        case (alu_op)
            ALU_ADD:  result = a + b;                  // 执行加法
            ALU_SUB:  result = sub_result;             // 执行减法
            ALU_AND:  result = a & b;                  // 执行逻辑与
            ALU_OR:   result = a | b;                  // 执行逻辑或
            ALU_NOR:  result = ~(a | b);               // 执行逻辑或非
            ALU_SLT:  result = {31'b0, slt_res};       // 执行有符号小于比较，结果为0或1
            ALU_SLTU: result = {31'b0, sltu_res};      // 执行无符号小于比较，结果为0或1
            default:  result = 32'hxxxxxxxx;           // 默认行为：当alu_op无效时，输出不确定值
        endcase
    end

    // 零标志位(zero flag)的生成逻辑：当减法结果（通常用于比较指令）为全零时，zero置1
    assign zero = (sub_result == 32'h00000000);

    // 小于标志位(less than flag)的生成逻辑：直接使用有符号比较的结果slt_res
    assign lt = slt_res;

endmodule