`timescale 1ns / 1ps

/*******************************************************************************
** Company:         Nantong University
** Engineer:        あやせももこ
**
** Create Date:     2025-06-16
** Design Name:     LA32R Single Cycle CPU
** Module Name:     control_unit
** Project Name:    Computer Architecture Course Design
** Target Devices:  Any FPGA
** Tool Versions:   Vivado 2018.1
** Description:
** This is the main control unit for the single-cycle LA32R CPU. It decodes
** the instruction's opcode and function fields to generate all necessary
** control signals for the datapath.
**
** [FIXED] Restructured the case statement to correctly handle instructions
** that share the same opcode, such as LD.W and ST.W.
**
** Revision:
** Revision 0.02 - Corrected case statement logic for shared opcodes.
** Revision 0.01 - File Created
**
*******************************************************************************/

module control_unit (
    input  wire [31:0] instr,       // 指令输入 (Instruction Input)
    input  wire        zero_flag,   // 来自ALU的零标志位 (Zero flag from ALU)
    input  wire        lt_flag,     // 来自ALU的小于标志位 (Less-than flag from ALU)

    output reg         reg_write_en, // 寄存器写使能 (Register Write Enable)
    output reg         mem_to_reg,   // 选择写回寄存器的数据源 (Selects data source for register write-back)
    output reg         mem_write_en, // 存储器写使能 (Memory Write Enable)
    output reg         alu_src,      // 选择ALU的第二操作数源 (Selects ALU's second operand source)
    output reg         src_reg,      // 选择寄存器堆的第二读地址源 (Selects Register File's second read address source)
    output reg  [2:0]  ext_op,       // 立即数扩展控制 (Immediate extender control)
    output reg  [3:0]  alu_op,       // ALU操作控制 (ALU operation control)
    output wire        pcsource      // PC下一个地址来源选择 (PC next address source selection)
);

    // 提取指令中的关键字段
    // Extract key fields from the instruction
    wire [5:0] opcode = instr[31:26];
    wire [1:0] func2  = instr[21:20]; // for 3R-type per ISA document
    wire [4:0] func5  = instr[19:15]; // for 3R-type per ISA document
    wire [3:0] func4  = instr[25:22]; // for 2RI12-type

    // 定义指令操作码 (Opcode Definitions)
    localparam OP_GROUP_00 = 6'b000000; // Contains 3R instructions
    localparam OP_ADDI_W   = 6'b000010;
    localparam OP_LUI12I   = 6'b000101;
    localparam OP_GROUP_0A = 6'b001010; // Contains LD.W, ST.W
    localparam OP_B        = 6'b010100;
    localparam OP_BEQ      = 6'b010110;
    localparam OP_BLT      = 6'b011000;

    // 定义ALU操作码 (ALU Operation Definitions)
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_NOR  = 4'b0100;
    localparam ALU_SLT  = 4'b0101;
    localparam ALU_SLTU = 4'b0110;

    // 定义立即数扩展类型 (Immediate Extension Type Definitions)
    localparam EXT_SI12  = 3'b001;
    localparam EXT_SI16  = 3'b010;
    localparam EXT_UI20  = 3'b011;
    localparam EXT_SI26  = 3'b100;
    
    // 主译码逻辑 (Main Decoding Logic)
    always @(*) begin
        // --- 控制信号默认值，防止生成锁存器 ---
        // Default values for control signals to prevent latches
        reg_write_en = 1'b0;
        mem_to_reg   = 1'b0;
        mem_write_en = 1'b0;
        alu_src      = 1'b0;
        src_reg      = 1'b0;
        ext_op       = 3'bxxx;
        alu_op       = 4'bxxxx;

        case (opcode)
            OP_GROUP_00: begin
                // Differentiate based on func2 field
                if (func2 == 2'b01) begin // This is a 3R-type arithmetic/logic instruction
                    reg_write_en = 1'b1;
                    alu_src      = 1'b0; // B operand comes from register
                    src_reg      = 1'b0; // Second read address comes from rk field
                    // Further decode based on func5
                    case(func5)
                        5'b00000: alu_op = ALU_ADD;
                        5'b00010: alu_op = ALU_SUB;
                        5'b00100: alu_op = ALU_SLT;
                        5'b00101: alu_op = ALU_SLTU;
                        5'b01000: alu_op = ALU_NOR;
                        5'b01001: alu_op = ALU_AND;
                        5'b01010: alu_op = ALU_OR;
                        default:  alu_op = 4'bxxxx;
                    endcase
                end
            end
            OP_ADDI_W: begin
                 // ADDI.W has its own opcode
                reg_write_en = 1'b1;
                alu_src      = 1'b1; // B operand comes from immediate
                ext_op       = EXT_SI12;
                alu_op       = ALU_ADD;
            end
            OP_LUI12I: begin
                reg_write_en = 1'b1;
                alu_src      = 1'b1;
                mem_to_reg   = 1'b0; // ALU result writes back
                ext_op       = EXT_UI20;
                alu_op       = ALU_ADD; // ALU adds immediate to zero
            end
            OP_GROUP_0A: begin
                // Differentiate LD.W and ST.W based on func4
                if (func4 == 4'b0010) begin // LD.W
                    reg_write_en = 1'b1;
                    mem_to_reg   = 1'b1; // Data from memory writes back
                    alu_src      = 1'b1;
                    ext_op       = EXT_SI12;
                    alu_op       = ALU_ADD; // Calculate address
                end
                else if (func4 == 4'b0110) begin // ST.W
                    mem_write_en = 1'b1;
                    alu_src      = 1'b1;
                    src_reg      = 1'b1; // Second read address comes from rd field
                    ext_op       = EXT_SI12;
                    alu_op       = ALU_ADD; // Calculate address
                end
            end
            OP_B: begin
                // Unconditional branch
                ext_op       = EXT_SI26;
            end
            OP_BEQ: begin
                alu_src      = 1'b0;
                src_reg      = 1'b1; // Second read address comes from rd field
                ext_op       = EXT_SI16;
                alu_op       = ALU_SUB; // Compare
            end
            OP_BLT: begin
                alu_src      = 1'b0;
                src_reg      = 1'b1; // Second read address comes from rd field
                ext_op       = EXT_SI16;
                alu_op       = ALU_SUB; // Compare
            end
            default: begin
                // All signals keep their default values
            end
        endcase
    end
    
    // PC下一个地址来源的逻辑
    // Logic for PC's next address source
    wire beq_cond = (opcode == OP_BEQ) && zero_flag;
    wire blt_cond = (opcode == OP_BLT) && lt_flag;
    wire b_cond   = (opcode == OP_B);

    assign pcsource = beq_cond || blt_cond || b_cond;

endmodule
