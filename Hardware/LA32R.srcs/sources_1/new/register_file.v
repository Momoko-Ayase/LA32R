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
** - 32 general-purpose registers, each 32 bits wide.
** - Asynchronous read: Read ports reflect content immediately.
** - Synchronous write: Write operation occurs on the rising edge of the clock.
** - R0 Hardwired to Zero: Cannot be written to, and reading it always returns 0.
**
** Revision:
** Revision 0.01 - File Created
** Additional Comments:
** - Reset logic is included to initialize all registers to zero, which is good practice for simulation and synthesis.
**
*******************************************************************************/

module register_file (
    input  wire        clk,          // 时钟 (Clock)
    input  wire        rst,          // 复位 (Reset)
    input  wire        reg_write_en, // 写使能 (Write Enable)
    input  wire [4:0]  read_addr1,   // 读地址1 (Read Address 1)
    input  wire [4:0]  read_addr2,   // 读地址2 (Read Address 2)
    input  wire [4:0]  write_addr,   // 写地址 (Write Address)
    input  wire [31:0] write_data,   // 写数据 (Write Data)
    output wire [31:0] read_data1,   // 读数据1 (Read Data 1)
    output wire [31:0] read_data2    // 读数据2 (Read Data 2)
);

    // 声明32个32位的寄存器阵列
    // Declare an array of 32 registers, each 32 bits wide.
    reg [31:0] registers[0:31];

    integer i;

    // 同步写操作 (时钟上升沿触发)
    // Synchronous write operation (triggered on the rising edge of the clock)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 复位时，将所有寄存器清零
            // On reset, clear all registers to zero.
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (reg_write_en) begin
            // 写使能有效时，执行写操作
            // When write enable is active, perform the write operation.
            // 防御性设计：确保不写入0号寄存器
            // Defensive design: ensure register R0 is not written to.
            if (write_addr != 5'd0) begin
                registers[write_addr] <= write_data;
            end
        end
    end

    // 异步读操作1
    // Asynchronous read port 1
    // 防御性设计：确保读取0号寄存器时返回0
    // Defensive design: ensure reading from R0 always returns zero.
    assign read_data1 = (read_addr1 == 5'd0) ? 32'b0 : registers[read_addr1];

    // 异步读操作2
    // Asynchronous read port 2
    assign read_data2 = (read_addr2 == 5'd0) ? 32'b0 : registers[read_addr2];

endmodule
