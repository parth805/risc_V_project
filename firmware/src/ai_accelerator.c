/**
 * ============================================================================
 * @file ai_accelerator.c
 * @brief Implementation of C HAL and Neural Network Tiling Layer
 * ============================================================================
 */

#include "../include/ai_accelerator.h"

void ai_accel_matmul_4x4(const int8_t A[4][4], 
                         const int8_t B[4][4], 
                         int32_t C[4][4], 
                         bool enable_relu) {
    /* 1. Set Activation Mode */
    ai_accel_set_activation(enable_relu);

    /* 2. Load Matrix A and B into hardware MMIO registers */
    ai_accel_load_matrix_a_4x4(A);
    ai_accel_load_matrix_b_4x4(B);

    /* 3. Start Accelerator */
    ai_accel_start();

    /* 4. Wait for completion (8 clock cycles in hardware) */
    ai_accel_wait_done();

    /* 5. Read back final 4x4 output matrix */
    ai_accel_read_matrix_c_4x4(C);
}

void ai_nn_linear_layer(const int8_t *input,
                        const int8_t *weights,
                        const int32_t *bias,
                        int32_t *output,
                        int M, int K, int N,
                        bool enable_relu) {
    /* Temporary 4x4 buffers for sub-tile hardware execution */
    int8_t  tile_a[4][4];
    int8_t  tile_b[4][4];
    int32_t tile_c[4][4];

    /* Initialize Output Matrix to 0 or Bias */
    for (int i = 0; i < M; i++) {
        for (int j = 0; j < N; j++) {
            output[i * N + j] = (bias != 0) ? bias[j] : 0;
        }
    }

    /* Iterate over M, N, K in 4x4 tiles */
    for (int tm = 0; tm < M; tm += AI_ACCEL_TILE_SIZE) {
        for (int tn = 0; tn < N; tn += AI_ACCEL_TILE_SIZE) {
            
            /* Accumulator buffer for the current (tm, tn) 4x4 tile across K steps */
            int32_t acc_tile[4][4];
            for (int r = 0; r < 4; r++) {
                for (int c = 0; c < 4; c++) {
                    acc_tile[r][c] = 0;
                }
            }

            for (int tk = 0; tk < K; tk += AI_ACCEL_TILE_SIZE) {
                /* Load Sub-tile A from Input [M x K] */
                for (int r = 0; r < 4; r++) {
                    for (int c = 0; c < 4; c++) {
                        int row = tm + r;
                        int col = tk + c;
                        tile_a[r][c] = (row < M && col < K) ? input[row * K + col] : 0;
                    }
                }

                /* Load Sub-tile B from Weights [K x N] */
                for (int r = 0; r < 4; r++) {
                    for (int c = 0; c < 4; c++) {
                        int row = tk + r;
                        int col = tn + c;
                        tile_b[r][c] = (row < K && col < N) ? weights[row * N + col] : 0;
                    }
                }

                /* Execute 4x4 HW multiply in linear mode during intermediate K accumulation */
                ai_accel_matmul_4x4(tile_a, tile_b, tile_c, false);

                /* Accumulate hardware tile output into the tile accumulator */
                for (int r = 0; r < 4; r++) {
                    for (int c = 0; c < 4; c++) {
                        acc_tile[r][c] += tile_c[r][c];
                    }
                }
            }

            /* Add to output tensor and apply final ReLU activation if enabled */
            for (int r = 0; r < 4; r++) {
                for (int c = 0; c < 4; c++) {
                    int row = tm + r;
                    int col = tn + c;
                    if (row < M && col < N) {
                        int32_t val = output[row * N + col] + acc_tile[r][c];
                        if (enable_relu && val < 0) {
                            val = 0;
                        }
                        output[row * N + col] = val;
                    }
                }
            }
        }
    }
}

void cpu_sw_matmul(const int8_t *A,
                   const int8_t *B,
                   int32_t *C,
                   int M, int K, int N,
                   bool enable_relu) {
    for (int i = 0; i < M; i++) {
        for (int j = 0; j < N; j++) {
            int32_t sum = 0;
            for (int k = 0; k < K; k++) {
                sum += (int32_t)A[i * K + k] * (int32_t)B[k * N + j];
            }
            if (enable_relu && sum < 0) {
                sum = 0;
            }
            C[i * N + j] = sum;
        }
    }
}
