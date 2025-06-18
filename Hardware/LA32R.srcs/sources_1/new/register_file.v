`timescale 1ns / 1ps

/*******************************************************************************
** Company:         Nantong University
** Engineer:        あやせももこ
**
** Create Date:     2025-06-16
** Design Name:     LA32R Single Cycle CPU
** Module Name:     register_file
** Project Name:    Computer Architecture Course Design
** Target Devices:  Any FPGA
** Tool Versions:   Vivado 2018.1
** Description:
** This module implements the 32x32-bit Register File for the LA32R CPU.
** It features two asynchronous read ports and one synchronous write port.
** A defensive design is implemented to ensure R0 is always zero.
**
** Features:
** - 包含32个通用寄存器，每个寄存器宽度为32位。
** - 异步读：两个读端口可以立即反映所选寄存器的内容，无需时钟同步。
** - 同步写：写操作在时钟的上升沿进行。
** - R0硬连线为零：寄存器R0不可写入，读取R0始终返回0。
**
** Revision:
** Revision 0.01 - 文件创建及基本功能实现。
** Additional Comments:
** - 包含了复位逻辑，在复位时将所有寄存器初始化为零，这对于仿真和综合是一个良好的实践。
** - R0始终为零的设计是MIPS等RISC架构的常见特性。
*******************************************************************************/

module register_file (
    input  wire        clk,          // 时钟信号输入
    input  wire        rst,          // 复位信号输入 (高有效)
    input  wire        reg_write_en, // 寄存器写使能信号 (高有效)
    input  wire [4:0]  read_addr1,   // 第一个读端口的寄存器地址 (5位选择32个寄存器之一)
    input  wire [4:0]  read_addr2,   // 第二个读端口的寄存器地址
    input  wire [4:0]  write_addr,   // 写端口的寄存器地址
    input  wire [31:0] write_data,   // 待写入寄存器的数据
    output wire [31:0] read_data1,   // 第一个读端口读出的数据
    output wire [31:0] read_data2    // 第二个读端口读出的数据
);

    // 声明一个包含32个32位寄存器的存储阵列。
    reg [31:0] registers[0:31];

    // 循环变量，用于复位逻辑。
    integer i;

    // 同步写逻辑：在时钟上升沿或复位信号有效时执行。
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 当复位信号有效时，将所有寄存器（包括R0）初始化为0。
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (reg_write_en) begin
            // 当写使能信号有效时，并且目标地址不是R0（5'd0），才执行写操作。
            // 这是为了确保R0始终为0。
            if (write_addr != 5'd0) begin
                registers[write_addr] <= write_data;
            end
        end
    end

    // 异步读端口1的逻辑：
    // 如果读取地址为R0 (5'd0)，则输出32'b0。
    // 否则，输出对应地址寄存器的内容。
    assign read_data1 = (read_addr1 == 5'd0) ? 32'b0 : registers[read_addr1];

    // 异步读端口2的逻辑：
    // 与读端口1类似，确保读取R0时返回0。
    assign read_data2 = (read_addr2 == 5'd0) ? 32'b0 : registers[read_addr2];

endmodule
