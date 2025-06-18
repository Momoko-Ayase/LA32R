`timescale 1ns / 1ps

/*******************************************************************************
** Company:         Nantong University
** Engineer:        あやせももこ
**
** Create Date:     2025-06-16
** Design Name:     LA32R Single Cycle CPU
** Module Name:     data_memory
** Project Name:    Computer Architecture Course Design
** Target Devices:  Any FPGA
** Tool Versions:   Vivado 2018.1
** Description:
** 本模块为LA32R CPU实现数据存储器。它用于存储和加载CPU执行过程中需要读写的数据。
** 该存储器设计为字节寻址，但在此单周期CPU实现中，主要进行字(32位)的读写操作。
** 存储器采用同步写、异步读的方式工作。
** Features:
** - 提供1024个32位存储单元 (总共4KB)。
** - 支持同步写操作：在时钟上升沿根据写使能信号写入数据。
** - 支持异步读操作：根据地址信号直接读出数据，无需时钟同步。
** - 地址通过addr[11:2]进行选择，对应于32位字对齐的地址。
** Revision:
** Revision 0.01 - 文件创建及基本功能实现。
** Additional Comments:
** - 本模块在FPGA综合时，通常会被实现为块RAM (BRAM)。
** - 地址线的低两位(addr[1:0])被忽略，因为内存按字(4字节)对齐访问。
*******************************************************************************/

module data_memory (
    input  wire        clk,          // 时钟信号输入
    input  wire        mem_write_en, // 存储器写使能信号 (高有效)
    input  wire [31:0] addr,         // 数据读写地址输入
    input  wire [31:0] write_data,   // 待写入存储器的数据
    output wire [31:0] read_data     // 从存储器读出的数据
);
    // 此模块在FPGA实现中，通常会综合成一个同步写、异步读的RAM资源。
    // 例如，在Xilinx FPGA中，这可以映射到BRAM。

    // 定义一个1024深度、32位宽度的存储阵列，总容量为 1024 * 4 Bytes = 4KB。
    // 访问时使用地址的高10位 addr[11:2] 作为索引。
    reg [31:0] mem [0:1023]; // 存储阵列，共1024个字

    // 同步写逻辑：仅在时钟上升沿且写使能有效时，才将数据写入指定地址。
    always @(posedge clk) begin
        if (mem_write_en) begin
            // 使用地址信号的高10位 (addr[11:2]) 作为存储器阵列的索引，
            // 因为存储器是字寻址的 (32位 = 4字节)。
            mem[addr[11:2]] <= write_data;
        end
    end

    // 异步读逻辑：读操作是组合逻辑，直接根据地址索引从存储阵列中获取数据。
    // 同样使用地址的高10位作为索引。
    assign read_data = mem[addr[11:2]];

endmodule

