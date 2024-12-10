module Ex_MemToEx(input [3:0] SrcReg1, input [3:0] SrcReg2, input [3:0] write_register, input RegWrite, output SrcOut1, output SrcOut2);
    // Detect if EX-to-EX or MEM-to-EX forwarding needs to occur
    // For register 1
    assign SrcOut1 = (RegWrite) ? ((write_register == SrcReg1) ? '1 : '0) :'0;
    // For register 2
    assign SrcOut2 = (RegWrite) ? ((write_register == SrcReg2) ? '1 : '0) :'0;
endmodule

module MemToMem(input [3:0] SrcReg2, input [3:0] write_register, input MemtoReg, input MemWrite, output SrcOut2);
  // Detect if MEM-to-MEM forwarding needs to occur
  assign SrcOut2 = (MemtoReg && MemWrite && (write_register == SrcReg2)) ? '1 : '0;
  
endmodule