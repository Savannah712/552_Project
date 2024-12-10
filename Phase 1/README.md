# Phase 1
## WISC-S24 ISA Specifications
1) **Compute Instructions**

    1.1) Saturating Arithmetic for add sub and pad sub (4 word add/sub)

    1.2) **XOR**  instruction
   
    1.3) Reduction (**RED**)
   
        Add top bytes and lower bytes
   
    1.4) Right Rotation (**ROR**)

        Take bytes off the LSB and append them to MSB
   
         Opcode Rd,Rs, imm → (imm is 4 bit)

    1.5) Logical Left Shift (**SLL**) and Arithmetic Right Shift (**SRA**)
   
3) **Memory Instructions**
   
    2.1) Load Word (**LW**) and Store Word (**SW**)
   
        The LSB is always zero, so it is omitted in the instruction

        Opcode Rt,Rs, offset
   
    2.2) Load Immediate Type: Load Lower Byte (**LLB**) and Load Higher Byte (**LHB**)
>[!Note]
>These two are not technically loading from memory but are grouped with memory instructions.
   
3) **Control Instructions/Signals**
   
    3.1) Branch (**B**)

        Conditionally jumps to the address obtained by: signed imm + (PC + 2)
   
    3.2) Branch Register (**BR**)

        Jumps to register
   
    3.3) **PCS**

        Saves the next PC into rd (PC + 2)

        PCS rd
   
    3.4) **HLT**

        Stops the advancement of PC

   
## Memory System   
1) **Single-cycle Instruction Memory**
2) **Data Memory**
>[!Note]
>Verilog modules are provided for both memories

## Implementation
1) **Design**

    1.1) **ALU Adder:** Carry lookahead adder (CLA)

    1.2) **Shifter:** Use 4:1 muxes, a variant of the design with 2:1 muxes in the lecture slides

    1.3) **Register File:** As specified in the homework

    1.4) **Reduction unit (RED):** Use a tree of 4-bit carry lookahead adders.

       At the first level of the reduction tree, sum<sub>ab</sub> = aaaaaaaa + bbbbbbbb
       needs an 8-bit adder to generate a 9-bit result, in which this 8-bit adder is
       constructed from two 4-bit CLAs. The same goes for sumcd = cccccccc + dddddddd.
       Then at the second level of the tree, the final result sumab + sumcd should
       perform 9-bit addition using three 4-bit CLAs.

>[!Important]
> These are required design specifications for specific modules

2) **Reset Sequence**

WISC-S24 has an active low reset input (rst_n). Instructions are executed when rst_n is high.  If rst_n goes low for one clock cycle, the contents of the state of the machine are reset and execution is restarted at address 0x0000.
   
4) **Flags**

    3.1) Zero (Z) Flag

         --> Set iff the output of the operation is zero.

    3.2) Overflow (V) Flag

         --> Set by the ADD and SUB instructions

         --> Set iff the operation results in an overflow.

    3.3) Sign (N) Flag

         --> Set iff the result of the ADD or SUB instruction is negative.

>[!Note]
>Only the arithmetic instructions (except PADDSB and RED) can change the three flags (Z, V, N).
>The logical instructions (XOR, SLL, SRA, ROR) change the Z FLAG, but they do not change the N or V flag.
   
## Interface
Your top level Verilog code should be in file named ***cpu.v***. It should have a simple 4-signal interface: ***clk***, ***rst_n***, ***hlt*** and ***pc[15:0]***.

| **Signal** | **Direction** | **Description** |
| ---------- | ------------- | --------------- |
| clk | in | System clock |
| rst_n | in | Active low reset |
| hlt | out | When your processor encounters the HLT instruction, it will assert this signal once it has finished processing the last instruction before the HLT |
| pc[15:0] | out | PC value over the course of the program execution |
