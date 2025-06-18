# -*- coding: utf-8 -*-
import re

"""
LA32R Simple Assembler
- Converts a simplified assembly language into 32-bit hexadecimal machine code.
- Supports all 14 instructions required by the course design.
- Handles register names like '$r4', '$r12' and immediate values.
- Outputs a 'program.hex' file suitable for Verilog's $readmemh.
- [FIXED] Corrected the encoding for ADDI.W to match the ISA specification
  (opcode 000000 + func4).
- [FINAL FIX] Corrected the string formatting for 3R-type instructions, which
  was scrambling the register and function fields.
"""

# 指令编码定义
OPCODES = {
    'add.w': '000000', 'sub.w': '000000', 'slt': '000000', 'sltu': '000000',
    'nor': '000000', 'and': '000000', 'or': '000000',
    'addi.w': '000000', 'lu12i.w': '000101', 'ld.w': '001010', 'st.w': '001010',
    'b': '010100', 'beq': '010110', 'blt': '011000'
}

FUNC_3R = {
    'add.w': ('01', '00000'), 'sub.w': ('01', '00010'), 'slt': ('01', '00100'),
    'sltu': ('01', '00101'), 'nor': ('01', '01000'), 'and': ('01', '01001'),
    'or': ('01', '01010')
}

FUNC_2RI12 = {
    'addi.w': '1010', 'ld.w': '0010', 'st.w': '0110'
}


def to_binary(value, bits):
    """Converts an integer to a two's complement binary string of specified length."""
    if value >= 0:
        return format(value, 'b').zfill(bits)
    else:
        return format((1 << bits) + value, 'b')


def parse_register(reg_str):
    """Parses register string '$rX' to a 5-bit binary string."""
    return to_binary(int(reg_str.strip('$r')), 5)


def assemble_line(line):
    """Assembles a single line of assembly code into a 32-bit binary string."""
    line = line.lower().strip()
    parts = re.split(r'[\s,]+', line)
    op = parts[0]

    if op in FUNC_3R:  # 3R-type
        rd, rj, rk = parse_register(parts[1]), parse_register(parts[2]), parse_register(parts[3])
        opcode = OPCODES[op]
        func2, func5 = FUNC_3R[op]
        # [THE FIX] Removed the erroneous hardcoded '00000' field.
        # The correct format for these 3R instructions is opcode | 0000 | func2 | func5 | rk | rj | rd
        return f"{opcode}0000{func2}{func5}{rk}{rj}{rd}"

    elif op in ['addi.w', 'ld.w', 'st.w']:  # 2RI12-type
        rd = parse_register(parts[1])
        rj = parse_register(parts[2])
        imm = to_binary(int(parts[3], 0), 12)
        opcode = OPCODES[op]
        func4 = FUNC_2RI12[op]
        return f"{opcode}{func4}{imm}{rj}{rd}"

    elif op == 'lu12i.w':  # 1RI20-type
        rd = parse_register(parts[1])
        imm = to_binary(int(parts[2], 0), 20)
        opcode = OPCODES[op]
        return f"{opcode}0{imm}{rd}"

    elif op in ['beq', 'blt']:  # 2RI16-type
        rj, rd = parse_register(parts[1]), parse_register(parts[2])
        offset = int(parts[3], 0) >> 2
        imm = to_binary(offset, 16)
        opcode = OPCODES[op]
        return f"{opcode}{imm}{rj}{rd}"

    elif op == 'b':  # I26-type
        offset = int(parts[1], 0) >> 2
        imm = to_binary(offset, 26)
        offs_25_16, offs_15_0 = imm[0:10], imm[10:26]
        opcode = OPCODES[op]
        return f"{opcode}{offs_15_0}{offs_25_16}"

    else:
        raise ValueError(f"Unknown instruction: {op}")


def main():
    """Main function to read assembly file and write hex file."""
    # 使用这个测试程序来验证CPU的功能
    # Use this test program to verify CPU functionality
    assembly_code = open("../program.asm", "r").read()

    output_filename = "program.hex"
    with open(output_filename, "w") as f:
        print(f"Assembling code into {output_filename}...")
        for line in assembly_code.split('\n'):
            line = line.strip()
            # 忽略注释和空行
            # Ignore comments and empty lines
            if not line or line.startswith('//'):
                continue
            try:
                # 移除行内注释
                # Remove inline comments
                line = line.split('//')[0].strip()
                binary_code = assemble_line(line)
                hex_code = f"{int(binary_code, 2):08x}"
                f.write(hex_code + '\n')
                print(f"  {line:<30} -> {hex_code}")
            except Exception as e:
                print(f"Error assembling line: '{line}'")
                print(f"  > {e}")
                return
        print("Assembly finished successfully.")


if __name__ == "__main__":
    main()
