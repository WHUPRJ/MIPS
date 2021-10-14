`include "AXI.svh"

interface AXIRead_i;
  AXIReadAddr_t AXIReadAddr;
  AXIReadData_t AXIReadData;

  modport master(input AXIReadData, output AXIReadAddr);
  modport slave(input AXIReadAddr, output AXIReadData);
endinterface  //AXIRead
