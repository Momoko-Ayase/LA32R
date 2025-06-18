`timescale 1ns / 1ps

/*******************************************************************************
** Company:         Nantong University
** Engineer:        あやせももこ
**
** Create Date:     2025-06-16
** Design Name:     LA32R Single Cycle CPU
** Module Name:     instruction_memory
** Project Name:    Computer Architecture Course Design
** Target Devices:  Any FPGA
** Tool Versions:   Vivado 2018.1
** Description:
** 本模块为LA32R CPU实现指令存储器。它负责根据程序计数器(PC)提供的地址
** 输出相应的32位指令。在实际硬件中，这通常是一个只读存储器(ROM)。
** 在仿真环境中，它通过一个寄存器数组实现，并使用`$readmemh`系统任务
** 从外部十六进制文件加载指令。
** Features:
** - 提供1024个32位存储单元，可存储1024条指令。
** - 根据输入的32位字节地址（addr）获取指令，实际通过addr[11:2]选择字。
** - 在FPGA实现中通常综合为ROM。
** - 仿真时支持从外部文件加载指令。
** Revision:
** Revision 0.01 - 文件创建及基本功能实现。
** Additional Comments:
** - 仿真时，指令从位于"../../../../../Software/program.hex"的十六进制文件加载。
** - 确保该路径相对于仿真工作目录是正确的。
** - 硬件实现中，指令内容通常在FPGA配置时被编程到ROM中。
*******************************************************************************/

module instruction_memory (
    input  wire [31:0] addr,    // 输入的指令地址 (来自PC)
    output wire [31:0] instr    // 输出的32位指令
);
    // 指令存储器在硬件实现中通常是只读存储器 (ROM)。
    // 在FPGA综合时，此模块将被实现为一个ROM。

    // 为了进行仿真，我们使用一个寄存器数组来模拟指令存储器，
    // 并使用 $readmemh 系统任务从一个十六进制文件中加载程序指令。
    reg [31:0] mem [0:1023]; // 定义一个可存储1024条32位指令的存储阵列 (4KB容量)

    // `initial`块仅在仿真开始时执行一次。
    initial begin
        // 从指定的十六进制文件中加载指令到mem数组中。
        // 文件路径是相对于仿真执行目录的相对路径。
        // 用户需要创建一个名为 "program.hex" 的文件，其中包含机器码。
        $readmemh("../../../../../Software/program.hex", mem);
    end

    // CPU发出的地址是字节地址，而指令存储器是按字(32位)组织的。
    // 因此，需要将字节地址转换为字地址索引。addr[1:0]被忽略。
    // 例如，地址0x00, 0x04, 0x08 分别对应 mem[0], mem[1], mem[2]。
    assign instr = mem[addr[11:2]]; // 使用地址的高10位作为mem数组的索引

endmodule