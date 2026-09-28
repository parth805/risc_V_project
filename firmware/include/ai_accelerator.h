/**
 * ============================================================================
 * @file ai_accelerator.h
 * @brief C Hardware Abstraction Layer (HAL) Driver for RISC-V AI Accelerator
 * ============================================================================
 */

#ifndef AI_ACCELERATOR_H
#define AI_ACCELERATOR_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ========================================================================= */
/* MMIO Register Memory Map Base & Offsets                                    */
/* ========================================================================= */
#define AI_ACCEL_BASE_ADDR        (0x40000000UL)

#define AI_ACCEL_REG_CTRL         (*(volatile uint32_t *)(AI_ACCEL_BASE_ADDR + 0x0000))
#define AI_ACCEL_REG_STATUS       (*(volatile uint32_t *)(AI_ACCEL_BASE_ADDR + 0x0004))
#define AI_ACCEL_REG_CFG_SIZE     (*(volatile uint32_t *)(AI_ACCEL_BASE_ADDR + 0x0008))
#define AI_ACCEL_REG_CFG_K        (*(volatile uint32_t *)(AI_ACCEL_BASE_ADDR + 0x000C))
#define AI_ACCEL_REG_ADDR_A       (*(volatile uint32_t *)(AI_ACCEL_BASE_ADDR + 0x0010))
#define AI_ACCEL_REG_ADDR_B       (*(volatile uint32_t *)(AI_ACCEL_BASE_ADDR + 0x0014))
#define AI_ACCEL_REG_ADDR_C       (*(volatile uint32_t *)(AI_ACCEL_BASE_ADDR + 0x0018))
#define AI_ACCEL_REG_CFG_ACT      (*(volatile uint32_t *)(AI_ACCEL_BASE_ADDR + 0x001C))

/* Matrix Operand Buffer Windows (MMIO Streaming) */
#define AI_ACCEL_MAT_A_BASE       ((volatile uint32_t *)(AI_ACCEL_BASE_ADDR + 0x0100))
#define AI_ACCEL_MAT_B_BASE       ((volatile uint32_t *)(AI_ACCEL_BASE_ADDR + 0x0200))
#define AI_ACCEL_MAT_C_BASE       ((volatile int32_t  *)(AI_ACCEL_BASE_ADDR + 0x0300))

/* Control & Status Bitfields */
#define AI_ACCEL_CTRL_START       (1U << 0)
#define AI_ACCEL_CTRL_ACT_EN      (1U << 1)

#define AI_ACCEL_STATUS_DONE      (1U << 0)
#define AI_ACCEL_STATUS_BUSY      (1U << 1)
#define AI_ACCEL_STATUS_ERROR     (1U << 2)

#define AI_ACCEL_TILE_SIZE        (4)

/* ========================================================================= */
/* Low-Level Register Access Macros & Inline Functions                        */
/* ========================================================================= */

/**
 * @brief Initialize AI Accelerator Coprocessor
 */
static inline void ai_accel_init(void) {
    AI_ACCEL_REG_CTRL = 0x0;
    AI_ACCEL_REG_CFG_ACT = 0x0;
}

/**
 * @brief Configure Activation Function Mode
 * @param enable_relu true = ReLU active (max(0, x)), false = Linear bypass
 */
static inline void ai_accel_set_activation(bool enable_relu) {
    AI_ACCEL_REG_CFG_ACT = enable_relu ? 1U : 0U;
}

/**
 * @brief Pack four INT8 numbers into a single 32-bit MMIO word
 */
static inline uint32_t ai_pack_int8x4(int8_t b0, int8_t b1, int8_t b2, int8_t b3) {
    return (((uint32_t)(uint8_t)b0)       ) |
           (((uint32_t)(uint8_t)b1) << 8  ) |
           (((uint32_t)(uint8_t)b2) << 16 ) |
           (((uint32_t)(uint8_t)b3) << 24 );
}

/**
 * @brief Load a 4x4 signed INT8 Matrix A into the accelerator MMIO buffer
 */
static inline void ai_accel_load_matrix_a_4x4(const int8_t A[4][4]) {
    volatile uint32_t *mat_a_regs = AI_ACCEL_MAT_A_BASE;
    for (int r = 0; r < 4; r++) {
        mat_a_regs[r] = ai_pack_int8x4(A[r][0], A[r][1], A[r][2], A[r][3]);
    }
}

/**
 * @brief Load a 4x4 signed INT8 Matrix B into the accelerator MMIO buffer
 */
static inline void ai_accel_load_matrix_b_4x4(const int8_t B[4][4]) {
    volatile uint32_t *mat_b_regs = AI_ACCEL_MAT_B_BASE;
    for (int r = 0; r < 4; r++) {
        mat_b_regs[r] = ai_pack_int8x4(B[r][0], B[r][1], B[r][2], B[r][3]);
    }
}

/**
 * @brief Start the Accelerator Execution
 */
static inline void ai_accel_start(void) {
    AI_ACCEL_REG_CTRL = AI_ACCEL_CTRL_START;
}

/**
 * @brief Poll until the Accelerator completes matrix calculation (8 cycles)
 */
static inline void ai_accel_wait_done(void) {
    while (!(AI_ACCEL_REG_STATUS & AI_ACCEL_STATUS_DONE)) {
        /* Busy-wait poll loop (approx 1-2 CPU instructions) */
    }
}

/**
 * @brief Read back the 4x4 signed INT32 Matrix C from the accelerator
 */
static inline void ai_accel_read_matrix_c_4x4(int32_t C[4][4]) {
    volatile int32_t *mat_c_regs = AI_ACCEL_MAT_C_BASE;
    int idx = 0;
    for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 4; c++) {
            C[r][c] = mat_c_regs[idx++];
        }
    }
}

/* ========================================================================= */
/* High-Level AI / Neural Network API                                        */
/* ========================================================================= */

/**
 * @brief Single 4x4 Matrix Multiply with optional ReLU: C = Activation(A * B)
 */
void ai_accel_matmul_4x4(const int8_t A[4][4], 
                         const int8_t B[4][4], 
                         int32_t C[4][4], 
                         bool enable_relu);

/**
 * @brief High-Level Arbitrary-Dimension Tiled Neural Network Linear / Dense Layer
 * Computes: Output[M][N] = Activation(Input[M][K] * Weights[K][N] + Bias[N])
 * Automatically partitions large matrices into 4x4 hardware tiles!
 *
 * @param input       Pointer to Input Tensor (M x K, signed INT8)
 * @param weights     Pointer to Weight Tensor (K x N, signed INT8)
 * @param bias        Pointer to optional Bias Vector (N, signed INT32, NULL if unused)
 * @param output      Pointer to Output Tensor (M x N, signed INT32)
 * @param M           Batch dimension (e.g. 1 or 8)
 * @param K           Input feature dimension (e.g. 8 or 16)
 * @param N           Output neuron dimension (e.g. 4 or 8)
 * @param enable_relu Apply hardware ReLU activation
 */
void ai_nn_linear_layer(const int8_t *input,
                        const int8_t *weights,
                        const int32_t *bias,
                        int32_t *output,
                        int M, int K, int N,
                        bool enable_relu);

/**
 * @brief Software-Only Scalar CPU Matrix Multiplication (for Benchmark Comparison)
 */
void cpu_sw_matmul(const int8_t *A,
                   const int8_t *B,
                   int32_t *C,
                   int M, int K, int N,
                   bool enable_relu);

#ifdef __cplusplus
}
#endif

#endif /* AI_ACCELERATOR_H */
