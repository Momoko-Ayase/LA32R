`timescale 1ns / 1ps

/*******************************************************************************
** Company:         Nantong University
** Engineer:        あやせももこ
**
** Create Date:     2025-06-16
** Design Name:     LA32R Single Cycle CPU Testbench
** Module Name:     cpu_tb
** Project Name:    Computer Architecture Course Design
** Target Devices:  Any
** Tool Versions:   Vivado 2018.1
** Description:
** 本文件是为LA32R单周期CPU设计的一个自校验测试平台 (testbench)。
** 主要功能包括：
** - 生成时钟 (clk) 和复位 (rst) 信号。
** - 实例化顶层CPU模块 (cpu_top)。
** - CPU内部的指令存储器模块将从 "program.hex" 文件加载机器码。
** - 监控并显示程序计数器 (PC) 和寄存器堆的状态，以供分析。
** Features:
** - 产生周期性的时钟信号。
** - 提供可控的复位序列，用于初始化CPU。
** - 实例化待测试的CPU顶层模块 (uut)。
** - 通过预设的仿真时间控制仿真流程。
** - 在仿真结束时，打印所有非零寄存器的最终状态。
** - 在每个时钟周期的下降沿（确保信号稳定后）显示关键信号，如PC值、当前指令和特定寄存器的值。
** Revision:
** Revision 0.01 - 文件创建及基本测试流程实现。
** Additional Comments:
** - 请确保此测试平台文件和包含机器码的 "program.hex" 文件位于Vivado仿真工作目录下。
** - "program.hex" 的路径在 `instruction_memory.v` 模块中指定。
*******************************************************************************/

`timescale 1ns / 1ps

module cpu_tb;

    // --- 信号声明 ---
    reg clk; // 时钟信号
    reg rst; // 复位信号
    integer i; // 用于for循环的变量

    // --- 实例化待测设计 (DUT - Design Under Test) ---
    // 将cpu_top模块实例化为uut (unit under test)
    cpu_top uut (
        .clk(clk),
        .rst(rst)
    );

    // --- 时钟生成逻辑 ---
    localparam CLK_PERIOD = 10; // 定义时钟周期为10纳秒
    initial begin
        clk = 0; // 初始化时钟为0
        forever #(CLK_PERIOD / 2) clk = ~clk; // 每半个周期翻转时钟信号，产生方波
    end

    // --- 仿真控制和主程序流程 ---
    initial begin
        // 1. 初始化并施加复位信号
        rst = 1; // 断言复位信号
        #(CLK_PERIOD * 2); // 保持复位状态持续2个时钟周期，以确保CPU完全复位
        rst = 0; // 撤销复位信号，CPU开始正常执行
        $display("------------------------------------------------------------");
        $display("                CPU仿真开始。复位信号已释放。                 ");
        $display("------------------------------------------------------------");

        // 2. 设定仿真运行时间后停止
        // 由于测试程序末尾通常是无限循环，因此需要手动设置仿真停止时间。
        #500; // 仿真运行500纳秒

        // 3. 仿真结束前，打印寄存器堆的最终状态
        $display("\n------------------------------------------------------------");
        $display("                仿真结束。最终寄存器状态如下:                 ");
        $display("------------------------------------------------------------");
        // 使用循环遍历寄存器堆，并通过$display显示其值。注意hierarchical path的正确性。
        for (i = 0; i < 32; i = i + 1) begin
            // 为了简化输出，仅显示值非零的寄存器。
            if (uut.u_reg_file.registers[i] != 32'h00000000) begin
                $display("寄存器 R%0d: 0x%08h", i, uut.u_reg_file.registers[i]);
            end
        end
        $display("※ 请注意：值为零的寄存器已被隐藏，未在此处显示。 ※");
        $display("------------------------------------------------------------");

        $finish; // 调用$finish系统任务来结束仿真过程
    end

    // --- 信号监控和数据显示 ---
    // 在每个时钟周期的下降沿采样并显示信息，以确保在该时刻所有待显示的信号值均已稳定。
    always @(negedge clk) begin
        if (!rst) begin //仅在非复位状态下显示
            $display("时间: %0t ns | PC: 0x%08h | 指令: 0x%08h | R4=0x%h R5=0x%h R6=0x%h",
                $time,                        // 当前仿真时间
                uut.pc_out,                   // PC的当前值
                uut.instr,                    // 当前PC指向的指令
                uut.u_reg_file.registers[4],  // R4寄存器的值
                uut.u_reg_file.registers[5],  // R5寄存器的值
                uut.u_reg_file.registers[6]   // R6寄存器的值
            );
        end
    end

endmodule
