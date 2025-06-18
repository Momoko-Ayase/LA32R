`timescale 1ns / 1ps

/*******************************************************************************
** Company:         Nantong University
** Engineer:        あやせももこ
**
** Create Date:     2025-06-16
** Design Name:     LA32R Single Cycle CPU
** Module Name:     imm_extender
** Project Name:    Computer Architecture Course Design
** Target Devices:  Any FPGA
** Tool Versions:   Vivado 2018.1
** Description:
** 本模块负责处理LA32R架构中各种指令格式中出现的立即数的符号扩展或零扩展。
** 它根据输入的指令和控制信号 `ext_op` 生成一个32位的立即数值。
**
** 支持的扩展类型:
** - 12位有符号立即数 (si12)：用于 ADDI.W, LD.W, ST.W 等I型指令。
** - 20位立即数 (ui20)：用于 LUI12I.W 指令 (高20位，低12位补零)。
** - 16位有符号偏移量 (si16)：用于 BEQ, BLT 等分支指令 (扩展后需左移两位)。
** - 26位有符号偏移量 (si26)：用于 B 等无条件跳转指令 (扩展后需左移两位)。
** Features:
** - 根据ext_op控制信号选择执行的扩展操作。
** - 为I型指令（如ADDI.W）提供12位立即数的符号扩展。
** - 为LUI12I.W指令提供20位立即数的高位加载（低位补零）。
** - 为条件分支指令（如BEQ, BLT）提供16位立即数的符号扩展和左移两位。
** - 为无条件跳转指令（B）提供26位立即数的符号扩展和左移两位。
** - 输出固定为32位的扩展后立即数。
** Revision:
** Revision 0.01 - 文件创建及基本功能实现。
** Additional Comments:
** - 这是一个纯组合逻辑模块，输出仅取决于当前输入。
** - 扩展操作的正确性对CPU指令的正确执行至关重要。
*******************************************************************************/

module imm_extender (
    input  wire [31:0] instr,    // 32位指令字输入
    input  wire [2:0]  ext_op,   // 立即数扩展操作类型控制信号
    output reg  [31:0] imm_ext   // 输出的32位扩展后立即数
);

    // 定义用于指示不同立即数扩展操作的参数常量
    localparam EXT_SI12  = 3'b001; // 扩展类型：12位有符号立即数 (用于I型指令)
    localparam EXT_SI16  = 3'b010; // 扩展类型：16位有符号立即数 (用于BEQ, BLT等分支指令的偏移量)
    localparam EXT_UI20  = 3'b011; // 扩展类型：20位无符号立即数 (用于LUI12I.W指令)
    localparam EXT_SI26  = 3'b100; // 扩展类型：26位有符号立即数 (用于B指令的偏移量)

    // 从指令字中根据不同指令格式提取原始立即数字段
    wire [11:0] si12 = instr[21:10]; // I型指令的12位立即数 imm[11:0]
    wire [15:0] si16 = instr[25:10]; // 分支指令的16位偏移量 offs[15:0]
    wire [19:0] si20 = instr[24:5];  // LUI12I.W指令的20位立即数 imm[19:0]
    // B指令的26位偏移量由两部分拼接而成: offs[25:16] 位于 instr[9:0], offs[15:0] 位于 instr[25:10]
    wire [25:0] si26 = {instr[9:0], instr[25:10]};

    // 组合逻辑：根据ext_op控制信号选择相应的立即数扩展方式
    always @(*) begin
        case (ext_op)
            EXT_SI12:
                // 对12位立即数si12进行符号扩展至32位。
                // 即将si12的最高位(si12[11])复制填充到结果的高20位。
                imm_ext = {{20{si12[11]}}, si12};
            EXT_SI16:
                // 对16位立即数si16进行符号扩展并左移两位，以生成32位字地址偏移。
                // 即将si16的最高位(si16[15])复制填充到结果的高14位，低2位补零。
                imm_ext = {{14{si16[15]}}, si16, 2'b00};
            EXT_UI20:
                // 对20位立即数si20进行处理，用于LUI12I.W指令。
                // 将si20作为结果的高20位，低12位补零。
                imm_ext = {si20, 12'b0};
            EXT_SI26:
                 // 对26位立即数si26进行符号扩展并左移两位，以生成32位字地址偏移。
                 // 即将si26的最高位(si26[25])复制填充到结果的高4位，低2位补零。
                imm_ext = {{4{si26[25]}}, si26, 2'b00};
            default:
                // 若ext_op不匹配任何已知类型，则输出不确定值。
                imm_ext = 32'hxxxxxxxx;
        endcase
    end

endmodule
