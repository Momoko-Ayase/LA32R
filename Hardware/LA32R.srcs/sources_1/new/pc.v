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
** - If no branch/jump: PC_next = PC_current + 4
** - If branch/jump taken: PC_next = Branch/Jump Target Address
**
** Revision:
** Revision 0.01 - File Created
**
*******************************************************************************/

module pc (
    input  wire        clk,         // 时钟 (Clock)
    input  wire        rst,         // 复位 (Reset)
    input  wire        pcsource,    // PC下一个地址来源选择 (PC next address source selection)
    input  wire [31:0] imm_ext,     // 来自立即数扩展单元的偏移量 (Offset from immediate extender)
    output reg  [31:0] pc_out       // 当前PC值 (Current PC value)
);

    wire [31:0] pc_plus_4;
    wire [31:0] pc_branch;
    wire [31:0] pc_next;

    // PC寄存器
    // PC register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out <= 32'h00000000; // 复位到0地址
        end else begin
            pc_out <= pc_next;
        end
    end

    // PC更新逻辑
    // PC update logic
    assign pc_plus_4 = pc_out + 32'd4;
    assign pc_branch = pc_out + imm_ext; // 偏移量已经左移两位

    assign pc_next = pcsource ? pc_branch : pc_plus_4;

endmodule
