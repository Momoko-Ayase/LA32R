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
** This is the top-level module of the single-cycle LA32R CPU. It instantiates
** and connects all sub-modules including PC, memories, register file, ALU,
** immediate extender, and the control unit. The connections follow the
** datapath diagram provided in the course design guide.
**
** Revision:
** Revision 0.01 - File Created
** Additional Comments:
** - This file integrates the entire design.
**
*******************************************************************************/

`timescale 1ns / 1ps

module cpu_top (
    input  wire clk,
    input  wire rst
);

    // --- 内部连线声明 (Internal Wire Declarations) ---
    wire [31:0] pc_out;
    wire [31:0] instr;
    wire [31:0] imm_ext;
    wire [31:0] read_data1;
    wire [31:0] read_data2;
    wire [31:0] alu_result;
    wire [31:0] mem_read_data;
    wire [31:0] write_back_data;
    wire [31:0] alu_b_operand;

    wire [4:0]  reg_write_addr;
    wire [4:0]  reg_read_addr1;
    wire [4:0]  reg_read_addr2;
    wire [4:0]  reg_read_addr2_final;

    // 控制信号
    // Control Signals
    wire        reg_write_en;
    wire        mem_to_reg;
    wire        mem_write_en;
    wire        alu_src;
    wire        src_reg;
    wire        pcsource;
    wire        zero_flag;
    wire        lt_flag;
    wire [2:0]  ext_op;
    wire [3:0]  alu_op;


    // --- 模块实例化 (Module Instantiation) ---

    // PC (程序计数器)
    pc u_pc (
        .clk        (clk),
        .rst        (rst),
        .pcsource   (pcsource),
        .imm_ext    (imm_ext),
        .pc_out     (pc_out)
    );

    // Instruction Memory (指令存储器)
    instruction_memory u_inst_mem (
        .addr       (pc_out),
        .instr      (instr)
    );

    // Control Unit (控制单元)
    control_unit u_ctrl_unit (
        .instr      (instr),
        .zero_flag  (zero_flag),
        .lt_flag    (lt_flag),
        .reg_write_en (reg_write_en),
        .mem_to_reg   (mem_to_reg),
        .mem_write_en (mem_write_en),
        .alu_src      (alu_src),
        .src_reg      (src_reg),
        .ext_op       (ext_op),
        .alu_op       (alu_op),
        .pcsource     (pcsource)
    );

    // Immediate Extender (立即数扩展单元)
    imm_extender u_imm_ext (
        .instr      (instr),
        .ext_op     (ext_op),
        .imm_ext    (imm_ext)
    );

    // MUX for Register File's second read address (src_reg_mux)
    assign reg_read_addr2_final = src_reg ? instr[4:0] : instr[14:10];

    // Register File (寄存器堆)
    register_file u_reg_file (
        .clk          (clk),
        .rst          (rst),
        .reg_write_en (reg_write_en),
        .read_addr1   (instr[9:5]),
        .read_addr2   (reg_read_addr2_final),
        .write_addr   (instr[4:0]),
        .write_data   (write_back_data),
        .read_data1   (read_data1),
        .read_data2   (read_data2)
    );

    // MUX for ALU's second operand (alu_src_mux)
    assign alu_b_operand = alu_src ? imm_ext : read_data2;

    // ALU (算术逻辑单元)
    alu u_alu (
        .a          (read_data1),
        .b          (alu_b_operand),
        .alu_op     (alu_op),
        .result     (alu_result),
        .zero       (zero_flag),
        .lt         (lt_flag)
    );

    // Data Memory (数据存储器)
    data_memory u_data_mem (
        .clk          (clk),
        .mem_write_en (mem_write_en),
        .addr         (alu_result),
        .write_data   (read_data2), // ST.W指令的数据来自第二个读端口(rd)
        .read_data    (mem_read_data)
    );

    // MUX for write-back data (mem_to_reg_mux)
    assign write_back_data = mem_to_reg ? mem_read_data : alu_result;


endmodule
