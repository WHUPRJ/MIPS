`ifndef AXI_SVH
`define AXI_SVH

typedef struct packed {
  logic [3:0] arid;  // Read address ID
  logic [31:0] araddr;  // Read address
  logic [3:0] arlen;  // Burst length
  logic [2:0] arsize;  // Burst size
  logic [1:0] arburst;  // Burst type
  logic [1:0] arlock;  // Lock type
  logic [3:0] arcache;  // Cache type
  logic [2:0] arprot;  // Protection type
  logic arvalid;  // Read address valid

  logic rready;  // Read ready
} AXIReadAddr_t;  // master

typedef struct packed {
  logic arready;  // Read address ready
  logic [3:0] rid;  // Read ID tag
  logic [31:0] rdata;  // Read data
  logic [1:0] rresp;  // Read response
  logic rlast;  // Read last
  logic rvalid;  // Read valid
} AXIReadData_t;  // slave

typedef struct packed {
  logic [3:0] awid;  // Write address ID
  logic [31:0] awaddr;  // Write address
  logic [3:0] awlen;  // Burst length
  logic [2:0] awsize;  // Burst size
  logic [1:0] awburst;  // Burst type
  logic [1:0] awlock;  // Lock type
  logic [3:0] awcache;  // Cache type
  logic [2:0] awprot;  // Protection type
  logic awvalid;  // Write address valid

  logic [3:0] wid;  // Write ID tag
  logic [31:0] wdata;  // Write data
  logic [3:0] wstrb;  // Write strobes
  logic wlast;  // Write last
  logic wvalid;  // Write valid

  logic bready;  // Response ready
} AXIWriteAddr_t;  // master

typedef struct packed {
  logic awready;  // Write address ready
  logic wready;   // Write ready

  logic [3:0] bid;  // Response ID
  logic [1:0] bresp;  // Write response
  logic bvalid;  // Write response valid
} AXIWriteData_t;  // slave

`endif
