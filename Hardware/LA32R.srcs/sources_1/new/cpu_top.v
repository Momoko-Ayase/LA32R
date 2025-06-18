`timescale 1ns / 1ps

/*******************************************************************************
** Company:         Nantong University
** Engineer:        あやせももこ
**
** Create Date:     2025-06-16
** Design Name:     LA32R Single Cycle CPU
** Module Name:     cpu_top
** Project Name:    Computer Architecture Course Design
** Target Devices:  Any FPGA
** Tool Versions:   Vivado 2018.1
** Description:
** 本模块是LA32R单周期CPU的顶层模块。它实例化并连接了所有子模块，
** 包括程序计数器(PC)、指令存储器、数据存储器、寄存器堆、算术逻辑单元(ALU)、
** 立即数扩展器和控制单元。模块间的连接遵循课程设计指导书中提供的单周期CPU数据通路图。
** 为了支持LUI12I.W指令，ALU的第一个操作数（A操作数）增加了一个多路选择器，允许选择0作为输入。
** Features:
** - 集成CPU所有核心组件：PC、指令存储器、数据存储器、寄存器文件、ALU、立即数扩展器、控制单元。
** - 实现单周期数据通路，连接各模块以执行指令。
** - 根据控制单元产生的信号，协调数据流动和操作执行。
** - 支持LUI12I.W指令，通过alu_asrc信号控制ALU的A操作数选择。
** Revision:
** Revision 0.02 - 添加了alu_asrc控制信号及相应的数据通路修改，以支持LUI12I.W指令。
** Revision 0.01 - 文件创建。
** Additional Comments:
** - 本文件是整个CPU设计的集成核心。
** - 所有主要的子模块都在此文件中实例化和互连。
*******************************************************************************/

module cpu_top (
    input  wire clk, // 时钟信号输入
    input  wire rst  // 复位信号输入
);

    // --- 内部信号线声明 ---
    // 数据通路信号
    wire [31:0] pc_out;          // PC的输出，即当前指令地址
    wire [31:0] instr;           // 从指令存储器读出的指令
    wire [31:0] imm_ext;         // 立即数扩展器输出的扩展后立即数
    wire [31:0] read_data1;      // 从寄存器堆读出的第一个操作数 (rs)
    wire [31:0] read_data2;      // 从寄存器堆读出的第二个操作数 (rt / store data)
    wire [31:0] alu_result;      // ALU的运算结果
    wire [31:0] mem_read_data;   // 从数据存储器读出的数据
    wire [31:0] write_back_data; // 写回寄存器堆的数据
    wire [31:0] alu_a_operand;   // ALU的A操作数
    wire [31:0] alu_b_operand;   // ALU的B操作数

    // 控制信号线
    wire        reg_write_en;    // 寄存器写使能
    wire        mem_to_reg;      // 选择写回寄存器的数据来源 (ALU结果或内存数据)
    wire        mem_write_en;    // 存储器写使能
    wire        alu_src;         // ALU第二操作数来源选择 (寄存器或立即数)
    wire        src_reg;         // 寄存器堆第二读地址来源选择
    wire        alu_asrc;        // ALU第一操作数来源选择 (支持LUI)
    wire        pcsource;        // PC下一地址来源选择 (PC+4或分支目标)
    wire        zero_flag;       // ALU零标志位输出
    wire        lt_flag;         // ALU小于标志位输出 (用于BLT)
    wire [2:0]  ext_op;          // 立即数扩展操作控制
    wire [3:0]  alu_op;          // ALU操作控制

    // --- 各子模块实例化 ---

    // 程序计数器 (PC)
    pc u_pc (.clk(clk), .rst(rst), .pcsource(pcsource), .imm_ext(imm_ext), .pc_out(pc_out));

    // 指令存储器
    instruction_memory u_inst_mem (.addr(pc_out), .instr(instr));

    // 控制单元
    control_unit u_ctrl_unit (
        .instr(instr), .zero_flag(zero_flag), .lt_flag(lt_flag),
        .reg_write_en(reg_write_en), .mem_to_reg(mem_to_reg), .mem_write_en(mem_write_en),
        .alu_src(alu_src), .src_reg(src_reg), .ext_op(ext_op), .alu_op(alu_op),
        .alu_asrc(alu_asrc), .pcsource(pcsource)
    );

    // 立即数扩展器
    imm_extender u_imm_ext (.instr(instr), .ext_op(ext_op), .imm_ext(imm_ext));

    // 决定寄存器堆的第二个读取地址 (用于某些指令格式，如ST.W，其中rt是源数据)
    wire [4:0] reg_read_addr2_final = src_reg ? instr[4:0] : instr[14:10]; // src_reg=0: rd=instr[19:15] rt=instr[14:10]; src_reg=1: rd=instr[24:20] rt=instr[4:0]

    // 寄存器堆
    register_file u_reg_file (
        .clk(clk), .rst(rst), .reg_write_en(reg_write_en),
        .read_addr1(instr[9:5]),         // rs寄存器地址
        .read_addr2(reg_read_addr2_final),// rt寄存器地址 (根据src_reg选择)
        .write_addr(instr[4:0]),         // rd寄存器地址 (目标寄存器)
        .write_data(write_back_data),    // 写回的数据
        .read_data1(read_data1),         // 读出的rs寄存器数据
        .read_data2(read_data2)          // 读出的rt寄存器数据
    );

    // ALU的第一个操作数 (A) 的多路选择器，由alu_asrc控制
    // 当alu_asrc为1 (如LUI指令)，A操作数为0；否则为寄存器堆的read_data1
    assign alu_a_operand = alu_asrc ? 32'b0 : read_data1;
    
    // ALU的第二个操作数 (B) 的多路选择器，由alu_src控制
    // 当alu_src为1，B操作数为立即数扩展器的输出；否则为寄存器堆的read_data2
    assign alu_b_operand = alu_src ? imm_ext : read_data2;

    // 算术逻辑单元 (ALU)
    alu u_alu (
        .a(alu_a_operand), .b(alu_b_operand), .alu_op(alu_op),
        .result(alu_result), .zero(zero_flag), .lt(lt_flag)
    );

    // 数据存储器
    data_memory u_data_mem (
        .clk(clk), .mem_write_en(mem_write_en), .addr(alu_result), // 地址来自ALU计算结果
        .write_data(read_data2),                                  // 写入的数据来自寄存器堆的read_data2 (例如ST.W指令)
        .read_data(mem_read_data)                                 // 读出的数据
    );

    // 写回寄存器的数据选择多路选择器，由mem_to_reg控制
    // 当mem_to_reg为1 (如LD.W指令)，写回数据来自数据存储器；否则来自ALU的运算结果
    assign write_back_data = mem_to_reg ? mem_read_data : alu_result;

endmodule
