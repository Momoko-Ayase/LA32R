// 1. 寄存器加载测试 (Register Loading Test)
lu12i.w  $r4, 0x12300      // r4 = 0x12300000
addi.w   $r4, $r4, 0x456    // r4 = 0x12300456
lu12i.w  $r5, 0x88800      // r5 = 0x88800000 (negative high part)
addi.w   $r5, $r5, -1       // r5 = 0x887FFFFF

// 2. 算术/逻辑运算测试 (Arithmetic/Logic Test)
add.w    $r6, $r4, $r5      // r6 = 0x12300456 + 0x887FFFFF = 0x9AB00455
sub.w    $r7, $r4, $r5      // r7 = 0x12300456 - 0x887FFFFF = 0x89B00457
slt      $r8, $r4, $r5      // r4 > r5 (signed), r8 = 0
sltu     $r9, $r4, $r5      // r4 < r5 (unsigned), r9 = 1
and      $r10, $r4, $r5     // r10 = 0x12300456 & 0x887FFFFF = 0x00300456
or       $r11, $r4, $r5     // r11 = 0x12300456 | 0x887FFFFF = 0x9A7FFFFF
nor      $r12, $r10, $r11   // r12 = ~(r10 | r11) = ~0x9A7FFFFF = 0x65800000

// 3. 内存访问测试 (Memory Access Test)
addi.w   $r1, $r0, 100      // r1 = 100 (Address base)
st.w     $r4, $r1, 0        // M[100] = r4 (0x12300456)
st.w     $r5, $r1, 4        // M[104] = r5 (0x887FFFFF)
ld.w     $r13, $r1, 0       // r13 = M[100]
ld.w     $r14, $r1, 4       // r14 = M[104]

// 4. 分支指令测试 (Branching Test)
// BEQ: r13 == r4 is true, should jump
beq      $r13, $r4, 8     // Branch to 'skip' label (PC+8)
addi.w   $r15, $r0, 1       // This should NOT be executed
// 'skip:' label is here
// BLT: r7 is negative, r6 is positive, r7 < r6 is true, should jump
blt      $r7, $r6, 8      // Branch to 'end' label (PC+8)
addi.w   $r16, $r0, 1       // This should NOT be executed

// 'end:' label is here
// 5. 无条件跳转: 创建一个无限循环来结束程序
// Unconditional Jump: Create an infinite loop to end the program
b        -4                 // Infinite loop: jump to itself