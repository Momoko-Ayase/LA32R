`timescale 1ns / 1ps

/*******************************************************************************
** Company:         Nantong University
** Engineer:        あやせももこ
**
** Create Date:     2025-06-16
** Design Name:     LA32R Single Cycle CPU
** Module Name:     pc
** Project Name:    Computer Architecture Course Design
** Target Devices:  Any FPGA
** Tool Versions:   Vivado 2018.1
** Description:
** This module implements the Program Counter (PC) and its update logic.
** The PC is a 32-bit register that holds the address of the instruction
** to be fetched. It updates on every clock cycle.
**
** Update Logic:
** - 若无分支或跳转 (pcsource=0): PC_next = PC_current + 4
** - 若发生分支或跳转 (pcsource=1): PC_next = PC_current + imm_ext (分支/跳转目标地址)
**   (其中 imm_ext 是已经过符号扩展和适当左移的偏移量)
** Features:
** - 32位程序计数器。
** - 同步复位功能，复位时PC置为0x00000000。
** - 在每个时钟上升沿更新PC值。
** - 支持顺序执行 (PC + 4)。
** - 支持基于立即数偏移量的分支和跳转。
** Revision:
** Revision 0.01 - 文件创建及基本功能实现。
** Additional Comments:
** - `imm_ext` 输入假定已经由立即数扩展单元处理过（例如，对于分支指令，已经左移两位）。
*******************************************************************************/

module pc (
    input  wire        clk,         // 时钟信号输入
    input  wire        rst,         // 复位信号输入 (高有效)
    input  wire        pcsource,    // PC下一地址来源选择信号 (0: PC+4; 1: 分支/跳转目标)
    input  wire [31:0] imm_ext,     // 来自立即数扩展单元的32位扩展后立即数 (用作偏移量)
    output reg  [31:0] pc_out       // 输出当前的PC值 (即当前指令地址)
);

    wire [31:0] pc_plus_4; // 存储PC + 4的结果
    wire [31:0] pc_branch; // 存储分支或跳转目标地址
    wire [31:0] pc_next;   // 存储下一个PC的值

    // PC寄存器逻辑：在时钟上升沿或复位信号有效时更新
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out <= 32'h00000000; // 系统复位时，PC清零
        end else begin
            pc_out <= pc_next;      // 否则，PC更新为pc_next的值
        end
    end

    // PC下一状态逻辑 (组合逻辑)
    // 计算PC顺序递增4的值 (指向下一条指令)
    assign pc_plus_4 = pc_out + 32'd4;
    // 计算分支/跳转目标地址。imm_ext是带符号的偏移量，
    // 对于分支指令，imm_extender模块已经将其处理为乘以4之后的值（即左移两位）。
    assign pc_branch = pc_out + imm_ext;

    // 根据pcsource信号选择下一个PC值：
    // 如果pcsource为1 (表示发生分支或跳转)，则pc_next为计算出的目标地址pc_branch。
    // 如果pcsource为0 (表示顺序执行)，则pc_next为pc_plus_4。
    assign pc_next = pcsource ? pc_branch : pc_plus_4;

endmodule
