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
** This module handles the sign/zero extension of immediate values found in
** various instruction formats of the LA32R architecture. It generates a 32-bit
** immediate value based on the instruction and the control signal `ext_op`.
**
** Supported Extensions:
** - 12-bit signed immediate (si12) for ADDI.W, LD.W, ST.W
** - 20-bit immediate (si20) for LUI12I.W (zero-extended low)
** - 16-bit signed offset for BEQ, BLT
** - 26-bit signed offset for B
**
** Revision:
** Revision 0.01 - File Created
** Additional Comments:
** - This is a purely combinational logic module.
**
*******************************************************************************/

module imm_extender (
    input  wire [31:0] instr,    // 32位指令输入 (32-bit instruction input)
    input  wire [2:0]  ext_op,   // 扩展操作控制信号 (Extension operation control signal)
    output reg  [31:0] imm_ext   // 32位扩展后的立即数输出 (32-bit extended immediate output)
);

    // 定义立即数扩展类型的参数
    // Define parameters for immediate extension types
    localparam EXT_SI12  = 3'b001; // 12-bit signed immediate for I-type
    localparam EXT_SI16  = 3'b010; // 16-bit signed offset for branches
    localparam EXT_UI20  = 3'b011; // 20-bit immediate for LUI
    localparam EXT_SI26  = 3'b100; // 26-bit signed offset for jump

    // 提取指令中不同格式的立即数
    // Extract immediate values from different instruction formats
    wire [11:0] si12 = instr[21:10];
    wire [15:0] si16 = instr[25:10];
    wire [19:0] si20 = instr[24:5];
    wire [25:0] si26 = {instr[9:0], instr[25:10]}; // B指令的offs[25:16]在[9:0], offs[15:0]在[25:10]

    // 组合逻辑: 根据ext_op选择不同的扩展方式
    // Combinational logic: select extension method based on ext_op
    always @(*) begin
        case (ext_op)
            EXT_SI12:
                // 对si12进行符号位扩展
                // Sign-extend si12
                imm_ext = {{20{si12[11]}}, si12};
            EXT_SI16:
                // 对si16进行符号位扩展并左移两位
                // Sign-extend si16 and shift left by 2
                imm_ext = {{14{si16[15]}}, si16, 2'b00};
            EXT_UI20:
                // 对si20进行高位加载，低12位补0
                // Load si20 to high bits, pad low 12 bits with 0
                imm_ext = {si20, 12'b0};
            EXT_SI26:
                 // 对si26进行符号位扩展并左移两位
                 // Sign-extend si26 and shift left by 2
                imm_ext = {{4{si26[25]}}, si26, 2'b00};
            default:
                imm_ext = 32'hxxxxxxxx; // 默认情况，输出不定态
        endcase
    end

endmodule
