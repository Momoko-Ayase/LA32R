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
** A self-checking testbench for the LA32R single-cycle CPU.
** - Generates clock and reset signals.
** - Instantiates the cpu_top module.
** - The instruction_memory module (instantiated within cpu_top) will load
** the machine code from "program.hex".
** - Monitors and displays the state of the PC and register file.
**
** Revision:
** Revision 0.01 - File Created
** Additional Comments:
** - Place this file and "program.hex" in the simulation directory.
**
*******************************************************************************/

`timescale 1ns / 1ps

module cpu_tb;

    // --- 信号声明 (Signal Declarations) ---
    reg clk;
    reg rst;

    // --- 实例化待测设计 (Instantiate the Design Under Test) ---
    cpu_top uut (
        .clk(clk),
        .rst(rst)
    );

    // --- 时钟生成器 (Clock Generator) ---
    localparam CLK_PERIOD = 10; // 时钟周期为10ns (Clock period is 10ns)
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // --- 仿真控制 (Simulation Control) ---
    initial begin
        // 1. 复位CPU (Reset the CPU)
        rst = 1;
        #(CLK_PERIOD * 2); // 保持复位2个周期 (Hold reset for 2 cycles)
        rst = 0;
        $display("------------------------------------------------------------");
        $display("         CPU Simulation Started. Reset is released.         ");
        $display("------------------------------------------------------------");

        // 2. 运行一段时间后停止仿真
        // Stop the simulation after a certain amount of time.
        // The test program has an infinite loop at the end,
        // so we need to manually stop the simulation.
        #500; // 运行500ns (Run for 500ns)

        // 3. 打印最终的寄存器状态
        // Print the final state of the registers
        $display("\n------------------------------------------------------------");
        $display("         Simulation Finished. Final Register State:         ");
        $display("------------------------------------------------------------");
        // 使用$display来显示寄存器的值。注意路径需要正确。
        // Use $display to show register values. Note the path must be correct.
        for (integer i = 0; i < 32; i = i + 1) begin
            // 检查寄存器值是否非零，以简化输出
            // Check if register value is non-zero to simplify output
            if (uut.u_reg_file.registers[i] != 32'h00000000) begin
                $display("Register R%0d: 0x%08h", i, uut.u_reg_file.registers[i]);
            end
        end
        $display("※Please note that registers with value zero are hidden.※");
        $display("------------------------------------------------------------");

        $finish; // 结束仿真 (End simulation)
    end

    // --- 监控和显示 (Monitoring and Display) ---
    // 在每个时钟周期的下降沿打印信息，确保所有信号稳定
    // Display info at the falling edge of the clock to ensure all signals are stable.
    always @(negedge clk) begin
        if (!rst) begin
            $display("Time: %0t ns | PC: 0x%08h | Instruction: 0x%08h | R4=0x%h R5=0x%h R6=0x%h",
                $time,
                uut.pc_out,
                uut.instr,
                uut.u_reg_file.registers[4],
                uut.u_reg_file.registers[5],
                uut.u_reg_file.registers[6]
            );
        end
    end

endmodule
