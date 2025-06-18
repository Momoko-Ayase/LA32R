# -*- coding: utf-8 -*-
import re

"""
LA32R 简易汇编器

功能:
- 将一种简化的LA32R汇编语言转换为32位十六进制机器码。
- 支持课程设计中定义的所有14条指令。
- 能够处理如 '$r4', '$r12' 这样的寄存器名称以及立即数（十进制或十六进制）。
- 输出 'program.hex' 文件，该文件格式适用于Verilog的 `$readmemh` 系统任务，可用于初始化指令存储器。

使用方法:
  python assembler.py <输入汇编文件名> [输出十六进制文件名]
  如果未指定输出文件名，则默认为 'program.hex'。

支持的指令格式:
- 3R类型: op rd, rj, rk (例如: add.w $r1, $r2, $r3)
- 2RI12类型: op rd, rj, imm12 (例如: addi.w $r1, $r2, 100)
- 1RI20类型: op rd, imm20 (例如: lu12i.w $r1, 0x12345)
- 2RI16类型: op rj, rd, offset16 (例如: beq $r1, $r2, label_offset)
- I26类型: op offset26 (例如: b label_offset)

修订历史:
- 修正了ADDI.W指令的编码，使其符合LA32R指令集架构（ISA）规范，
  正确使用操作码 000000 和func4字段 '1010'。
- 修正了3R类型指令的二进制字符串格式化问题，该问题曾导致
  操作码后的'0000'字段、func2、func5、寄存器rk, rj, rd的顺序和拼接混乱。
  确保了正确的字段顺序：opcode | 0000 | func2 | func5 | rk | rj | rd。
"""

# 定义指令的操作码 (opcode)
OPCODES = {
    # 3R型指令 (opcode: 000000)
    'add.w': '000000', 'sub.w': '000000', 'slt': '000000', 'sltu': '000000',
    'nor': '000000', 'and': '000000', 'or': '000000',
    # 2RI12型指令 (addi.w opcode: 000000; ld.w, st.w opcode: 001010)
    'addi.w': '000000', 'ld.w': '001010', 'st.w': '001010',
    # 1RI20型指令 (opcode: 000101)
    'lu12i.w': '000101',
    # 分支与跳转指令
    'b': '010100', 'beq': '010110', 'blt': '011000'
}

# 定义3R类型指令的功能码字段 (func2, func5)
FUNC_3R = {
    'add.w': ('01', '00000'), 'sub.w': ('01', '00010'), 'slt': ('01', '00100'),
    'sltu': ('01', '00101'), 'nor': ('01', '01000'), 'and': ('01', '01001'),
    'or': ('01', '01010')
}

# 定义部分2RI12类型指令的功能码字段 (instr[25:22])
FUNC_2RI12 = {
    'addi.w': '1010', # ADDI.W 特有的func4
    'ld.w': '0010',   # LD.W 特有的func4
    'st.w': '0110'    # ST.W 特有的func4
}


def to_binary(value, bits):
    """将一个整数转换为指定长度的二进制补码字符串。"""
    # 注意：此函数期望 'value' 是一个整数。
    # 如果 'value' 可能是一个表示数字的字符串（例如 "10" 或 "0xA"），
    # 调用者应在此函数被调用之前将其转换为整数。
    # 例如：imm = to_binary(int(parts[3], 0), 12)
    if value >= 0:
        # 对于非负数，直接转换为二进制并用0填充到指定位数
        return format(value, 'b').zfill(bits)
    else:
        # 对于负数，计算其二进制补码
        # (1 << bits) 表示 2^bits，加上负数后即为其补码的无符号表示
        return format((1 << bits) + value, 'b')


def parse_register(reg_str):
    """将寄存器字符串（如'$r5'）解析为5位二进制字符串。"""
    # 移除'$r'前缀，将剩余数字转换为整数，然后转为5位二进制
    return to_binary(int(reg_str.strip('$r')), 5)


def assemble_line(line):
    """将单行汇编代码转换为32位二进制字符串表示的机器码。"""
    line = line.lower().strip() # 转换为小写并移除首尾空格
    parts = re.split(r'[\s,]+', line) # 使用空格或逗号作为分隔符分割指令
    op = parts[0] # 第一个部分是操作码

    if op in FUNC_3R:  # 处理3R类型指令
        # 解析三个寄存器操作数
        rd, rj, rk = parse_register(parts[1]), parse_register(parts[2]), parse_register(parts[3])
        opcode = OPCODES[op]
        func2, func5 = FUNC_3R[op]
        # 3R类型指令格式: opcode | 0000 | func2 | func5 | rk | rj | rd
        # 此处修正了之前可能存在的硬编码或字段顺序错误问题。
        return f"{opcode}0000{func2}{func5}{rk}{rj}{rd}"

    elif op in ['addi.w', 'ld.w', 'st.w']:  # 处理 ADDI.W, LD.W, ST.W 等2RI12类型指令
        rd = parse_register(parts[1]) # 目标寄存器
        rj = parse_register(parts[2]) # 源寄存器
        imm = to_binary(int(parts[3], 0), 12) # 12位立即数，先转换为整数
        opcode = OPCODES[op]
        func4 = FUNC_2RI12[op] # 获取特定指令的func4字段
        # 2RI12类型指令格式: opcode | func4 | imm[11:0] | rj | rd
        return f"{opcode}{func4}{imm}{rj}{rd}"

    elif op == 'lu12i.w':  # 处理 LU12I.W (1RI20类型) 指令
        rd = parse_register(parts[1]) # 目标寄存器
        imm = to_binary(int(parts[2], 0), 20) # 20位立即数，先转换为整数
        opcode = OPCODES[op]
        # 1RI20类型指令格式: opcode | 0 | imm[19:0] | rd
        return f"{opcode}0{imm}{rd}"

    elif op in ['beq', 'blt']:  # 处理 BEQ, BLT (2RI16类型) 分支指令
        rj = parse_register(parts[1]) # 源寄存器1
        rd = parse_register(parts[2]) # 源寄存器2 (在beq/blt中，rd字段用作第二个源寄存器)
        # 偏移量是以字节为单位，但指令中存储的是字偏移，所以右移两位
        offset = int(parts[3], 0) >> 2
        imm = to_binary(offset, 16) # 16位立即数偏移
        opcode = OPCODES[op]
        # 2RI16类型指令格式: opcode | imm[15:0] | rj | rd
        return f"{opcode}{imm}{rj}{rd}"

    elif op == 'b':  # 处理 B (I26类型) 无条件跳转指令
        # 偏移量是以字节为单位，但指令中存储的是字偏移，所以右移两位
        offset = int(parts[1], 0) >> 2
        imm = to_binary(offset, 26) # 26位立即数偏移
        # 根据LA32R ISA，B指令的26位偏移量在指令码中的位置是不连续的
        # offs[25:16] (高10位) 位于指令码的 [9:0]
        # offs[15:0] (低16位) 位于指令码的 [25:10]
        offs_25_16 = imm[0:10]
        offs_15_0 = imm[10:26]
        opcode = OPCODES[op]
        # I26类型指令格式: opcode | offs[15:0] | offs[25:16]
        return f"{opcode}{offs_15_0}{offs_25_16}"

    else:
        # 如果操作码未知，则抛出错误
        raise ValueError(f"未知指令: {op}")


def main():
    """主函数：读取输入的汇编语言文件，将其汇编成十六进制机器码，并写入到输出文件。"""
    # 此处示例直接打开固定的 "program.asm" 文件进行处理
    # 实际应用中，可以修改为接收命令行参数来指定输入输出文件
    # 例如: python assembler.py input.asm output.hex
    try:
        with open("../program.asm", "r", encoding="utf-8") as asm_file:
            assembly_code = asm_file.read()
    except FileNotFoundError:
        print("错误：汇编文件 '../program.asm' 未找到。请确保文件路径正确。")
        return
    except Exception as e:
        print(f"读取汇编文件时发生错误：{e}")
        return

    output_filename = "program.hex" # 定义默认输出文件名
    with open(output_filename, "w", encoding="utf-8") as f:
        print(f"开始汇编代码到 {output_filename}...")
        line_num = 0
        for line in assembly_code.split('\n'):
            line_num += 1
            line = line.strip() # 移除当前行的首尾空白字符

            # 忽略空行和以 '//' 开头的注释行
            if not line or line.startswith('//'):
                continue

            try:
                # 移除行内注释 (即 '//' 及其之后的部分)
                line_content = line.split('//')[0].strip()
                if not line_content: # 如果移除行内注释后行为空，则跳过
                    continue

                binary_code = assemble_line(line_content) # 调用汇编函数处理单行指令
                hex_code = f"{int(binary_code, 2):08x}"   # 将32位二进制码转换为8位十六进制码
                f.write(hex_code + '\n')                  # 写入十六进制码到输出文件，并换行
                print(f"  行 {line_num:<3}: {line_content:<30} -> {hex_code}")
            except Exception as e:
                print(f"汇编错误，行 {line_num}: '{line}'")
                print(f"  错误信息: {e}")
                # 发生错误时可以选择停止汇编或继续处理下一行
                # 此处选择停止以防止产生不完整的机器码文件
                return
        print("汇编成功完成。")


if __name__ == "__main__":
    # 当脚本作为主程序执行时，调用main()函数
    main()
