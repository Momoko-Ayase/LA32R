`timescale 1ns / 1ps

/*******************************************************************************
** Instruction Memory Module
*******************************************************************************/

module instruction_memory (
    input  wire [31:0] addr,    // 地址输入 (Address input)
    output wire [31:0] instr    // 指令输出 (Instruction output)
);
    // 指令存储器通常是只读的 (Instruction memory is typically read-only)
    // 在FPGA中，这会综合成一个ROM
    // In an FPGA, this synthesizes into a ROM.

    // 仿真时，使用reg数组和$readmemh加载程序
    // For simulation, use a reg array and $readmemh to load the program.
    reg [31:0] mem [0:1023]; // 示例: 1024条指令空间 (Example: 1024 instruction space)

    initial begin
        // 从文件中加载指令
        // Load instructions from a file.
        // 你需要创建一个名为 "program.hex" 的文件
        // You need to create a file named "program.hex".
        $readmemh("../../../../../Software/program.hex", mem);
    end

    // 字节地址转换为字地址
    // Convert byte address to word address.
    assign instr = mem[addr[11:2]];

endmodule