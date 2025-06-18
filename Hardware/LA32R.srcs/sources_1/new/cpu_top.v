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
** [FIXED] Added a multiplexer for the ALU's first operand (A-operand) to
** support the LUI12I.W instruction by allowing it to select 0.
**
** Revision:
** Revision 0.02 - Added ALUAsrc control signal to support LUI12I.W instruction.
** Revision 0.01 - File Created
** Additional Comments:
** - This file integrates the entire design.
**
*******************************************************************************/

module cpu_top (
    input  wire clk,
    input  wire rst
);

    // --- 内部连线声明 (Internal Wire Declarations) ---
    wire [31:0] pc_out, instr, imm_ext, read_data1, read_data2, alu_result,
                mem_read_data, write_back_data, alu_a_operand, alu_b_operand;

    // 控制信号 (Control Signals)
    wire        reg_write_en, mem_to_reg, mem_write_en, alu_src, src_reg,
                alu_asrc, pcsource, zero_flag, lt_flag;
    wire [2:0]  ext_op;
    wire [3:0]  alu_op;

    // --- 模块实例化 (Module Instantiation) ---

    pc u_pc (.clk(clk), .rst(rst), .pcsource(pcsource), .imm_ext(imm_ext), .pc_out(pc_out));

    instruction_memory u_inst_mem (.addr(pc_out), .instr(instr));

    control_unit u_ctrl_unit (
        .instr(instr), .zero_flag(zero_flag), .lt_flag(lt_flag),
        .reg_write_en(reg_write_en), .mem_to_reg(mem_to_reg), .mem_write_en(mem_write_en),
        .alu_src(alu_src), .src_reg(src_reg), .ext_op(ext_op), .alu_op(alu_op),
        .alu_asrc(alu_asrc), .pcsource(pcsource)
    );

    imm_extender u_imm_ext (.instr(instr), .ext_op(ext_op), .imm_ext(imm_ext));

    wire [4:0] reg_read_addr2_final = src_reg ? instr[4:0] : instr[14:10];

    register_file u_reg_file (
        .clk(clk), .rst(rst), .reg_write_en(reg_write_en),
        .read_addr1(instr[9:5]), .read_addr2(reg_read_addr2_final),
        .write_addr(instr[4:0]), .write_data(write_back_data),
        .read_data1(read_data1), .read_data2(read_data2)
    );

    // [NEW] MUX for ALU's first operand (A)
    assign alu_a_operand = alu_asrc ? 32'b0 : read_data1;
    
    // MUX for ALU's second operand (B)
    assign alu_b_operand = alu_src ? imm_ext : read_data2;

    alu u_alu (
        .a(alu_a_operand), .b(alu_b_operand), .alu_op(alu_op),
        .result(alu_result), .zero(zero_flag), .lt(lt_flag)
    );

    data_memory u_data_mem (
        .clk(clk), .mem_write_en(mem_write_en), .addr(alu_result),
        .write_data(read_data2), .read_data(mem_read_data)
    );

    assign write_back_data = mem_to_reg ? mem_read_data : alu_result;

endmodule
