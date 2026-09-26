`ifndef ACCELERATOR_PKG_SV
`define ACCELERATOR_PKG_SV

package accelerator_pkg;

    // =========================================================================
    // Architectural Parameters
    // =========================================================================
    parameter int DATA_WIDTH    = 8;   // Signed INT8 inputs (Matrix A, Matrix B)
    parameter int ACC_WIDTH     = 32;  // Signed INT32 accumulation / output
    parameter int MATRIX_SIZE   = 4;   // 4x4 matrix dimensions (N=4)
    parameter int NUM_ELEMENTS  = MATRIX_SIZE * MATRIX_SIZE; // 16 elements total

    // =========================================================================
    // Controller FSM States
    // =========================================================================
    typedef enum logic [2:0] {
        STATE_IDLE      = 3'b000,
        STATE_LOAD      = 3'b001,
        STATE_COMPUTE   = 3'b010,
        STATE_ACTIVATE  = 3'b011,
        STATE_WRITEBACK = 3'b100,
        STATE_DONE      = 3'b101
    } state_t;

    // =========================================================================
    // Memory Map (RISC-V SoC Memory-Mapped CSR & Buffer Space @ 0x4000_0000)
    // =========================================================================
    localparam logic [31:0] REG_CTRL        = 32'h4000_0000; // Control Register (Bit 0: Start, Bit 1: Act_En)
    localparam logic [31:0] REG_STATUS      = 32'h4000_0004; // Status Register (Bit 0: Done, Bit 1: Busy, Bit 2: Error)
    localparam logic [31:0] REG_CFG_SIZE    = 32'h4000_0008; // Matrix Size Configuration (4)
    localparam logic [31:0] REG_CFG_K       = 32'h4000_000C; // Inner Dimension K (4)
    localparam logic [31:0] REG_ADDR_A      = 32'h4000_0010; // Pointer base address for Matrix A
    localparam logic [31:0] REG_ADDR_B      = 32'h4000_0014; // Pointer base address for Matrix B
    localparam logic [31:0] REG_ADDR_C      = 32'h4000_0018; // Pointer base address for Matrix C
    localparam logic [31:0] REG_CFG_ACT     = 32'h4000_001C; // Activation Config (0=Linear/Bypass, 1=ReLU)

    // Memory-Mapped Direct Matrix A Input Registers (4 rows: 4 bytes each = 1 word per row)
    localparam logic [31:0] REG_MAT_A_0     = 32'h4000_0100; // Row 0: {A[0][3], A[0][2], A[0][1], A[0][0]}
    localparam logic [31:0] REG_MAT_A_1     = 32'h4000_0104; // Row 1: {A[1][3], A[1][2], A[1][1], A[1][0]}
    localparam logic [31:0] REG_MAT_A_2     = 32'h4000_0108; // Row 2: {A[2][3], A[2][2], A[2][1], A[2][0]}
    localparam logic [31:0] REG_MAT_A_3     = 32'h4000_010C; // Row 3: {A[3][3], A[3][2], A[3][1], A[3][0]}

    // Memory-Mapped Direct Matrix B Input Registers (4 rows: 4 bytes each = 1 word per row)
    localparam logic [31:0] REG_MAT_B_0     = 32'h4000_0200; // Row 0: {B[0][3], B[0][2], B[0][1], B[0][0]}
    localparam logic [31:0] REG_MAT_B_1     = 32'h4000_0204; // Row 1: {B[1][3], B[1][2], B[1][1], B[1][0]}
    localparam logic [31:0] REG_MAT_B_2     = 32'h4000_0208; // Row 2: {B[2][3], B[2][2], B[2][1], B[2][0]}
    localparam logic [31:0] REG_MAT_B_3     = 32'h4000_020C; // Row 3: {B[3][3], B[3][2], B[3][1], B[3][0]}

    // Memory-Mapped Direct Matrix C Output Registers (16 words: C[0][0] to C[3][3])
    localparam logic [31:0] REG_MAT_C_BASE  = 32'h4000_0300; // C[i][j] at 0x4000_0300 + (i*4 + j)*4

    // Bit definitions within registers
    localparam int CTRL_START_BIT       = 0; // Write 1 to start computation
    localparam int CTRL_ACT_EN_BIT      = 1; // Write 1 to enable activation via CTRL reg
    localparam int STATUS_DONE_BIT      = 0; // Read 1 when matrix multiplication complete
    localparam int STATUS_BUSY_BIT      = 1; // Read 1 during processing
    localparam int STATUS_ERROR_BIT     = 2; // Read 1 if illegal state/configuration
    localparam int CFG_ACT_RELU_BIT     = 0; // 0: Linear/Bypass, 1: ReLU

endpackage : accelerator_pkg

`endif // ACCELERATOR_PKG_SV
