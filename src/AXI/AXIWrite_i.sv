`include "AXI.svh"

interface AXIWrite_i;
  AXIWriteAddr_t AXIWriteAddr;
  AXIWriteData_t AXIWriteData;

  modport master(input AXIWriteData, output AXIWriteAddr);
  modport slave(input AXIWriteAddr, output AXIWriteData);
endinterface  //AXIWrite
