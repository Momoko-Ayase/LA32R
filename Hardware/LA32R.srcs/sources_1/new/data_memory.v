`timescale 1ns / 1ps

/*******************************************************************************
** Data Memory Module
*******************************************************************************/

module data_memory (
    input  wire        clk,          // 时钟 (Clock)
    input  wire        mem_write_en, // 写使能 (Write Enable)
    input  wire [31:0] addr,         // 地址输入 (Address input)
    input  wire [31:0] write_data,   // 待写数据 (Write data)
    output wire [31:0] read_data     // 读出数据 (Read data)
);
    // 在FPGA中，这会综合成一个同步写的RAM
    // In an FPGA, this synthesizes into a synchronous-write RAM.

    reg [31:0] mem [0:1023]; // 示例: 1KB数据空间 (Example: 1KB data space)

    // 同步写
    // Synchronous write
    always @(posedge clk) begin
        if (mem_write_en) begin
            mem[addr[11:2]] <= write_data;
        end
    end

    // 异步读
    // Asynchronous read
    assign read_data = mem[addr[11:2]];

endmodule

