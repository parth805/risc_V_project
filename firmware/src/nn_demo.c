/**
 * ============================================================================
 * @file nn_demo.c
 * @brief End-to-End Multi-Layer Neural Network Inference on RISC-V AI SoC
 * ============================================================================
 */

#include "../include/ai_accelerator.h"

/* SRAM Target Memory Locations for Logging & Signatures */
#define RESULTS_SRAM_BASE   (0x00001000UL)
#define SIGNATURE_ADDR      (0x000010FCUL)
#define SIGNATURE_SUCCESS   (0xCAFEBABEUL)

/* ========================================================================= */
/* 2-Layer Quantized Neural Network Weights & Test Vectors                   */
/* Input: 1x8 -> Hidden: 1x8 (ReLU) -> Output: 1x4 (Classification Logits)   */
/* ========================================================================= */

/* Input Feature Vector (1x8) */
static const int8_t input_features[8] = {
    12, -8, 25, 4, -15, 30, -5, 18
};

/* Layer 1 Weights (8x8) */
static const int8_t layer1_weights[8 * 8] = {
     2, -3,  4,  1, -2,  3, -1,  2,
    -1,  4, -2,  3,  1, -4,  2, -3,
     3, -1,  2, -4,  3,  1, -2,  4,
    -2,  3, -1,  2, -4,  2,  3, -1,
     1, -2,  3, -1,  2, -3,  4,  1,
    -3,  2, -4,  3, -1,  4, -2,  3,
     4, -1,  2, -3,  1, -2,  3, -4,
    -2,  3, -1,  4, -3,  1,  2, -2
};

/* Layer 1 Bias (8 elements) */
static const int32_t layer1_bias[8] = {
    10, -5, 20, 15, -10, 5, 0, 12
};

/* Layer 2 Weights (8x4) */
static const int8_t layer2_weights[8 * 4] = {
     3, -2,  4,  1,
    -1,  4, -2,  3,
     2, -3,  1,  4,
    -4,  2,  3, -1,
     1, -1,  2, -3,
     3,  2, -4,  1,
    -2,  4,  1, -2,
     4, -3,  2,  1
};

/* Layer 2 Bias (4 elements) */
static const int32_t layer2_bias[4] = {
    5, -12, 18, 2
};

/* ========================================================================= */
/* Main Inference Demo Function                                              */
/* ========================================================================= */
int main(void) {
    /* 1. Initialize AI Accelerator */
    ai_accel_init();

    /* 2. Layer 1 Execution: Hidden = ReLU(Input * W1 + b1) */
    int32_t hidden_layer_output[8];
    int8_t  hidden_layer_quant[8];

    ai_nn_linear_layer(
        input_features,
        layer1_weights,
        layer1_bias,
        hidden_layer_output,
        1, 8, 8,
        true /* Enable ReLU */
    );

    /* Quantize Hidden activations back to INT8 for next layer input */
    for (int i = 0; i < 8; i++) {
        int32_t val = hidden_layer_output[i] >> 2; /* Scale by 4 */
        if (val > 127)  val = 127;
        if (val < -128) val = -128;
        hidden_layer_quant[i] = (int8_t)val;
    }

    /* 3. Layer 2 Execution: Logits = Hidden * W2 + b2 */
    int32_t output_logits[4];
    ai_nn_linear_layer(
        hidden_layer_quant,
        layer2_weights,
        layer2_bias,
        output_logits,
        1, 8, 4,
        false /* Linear output for logits */
    );

    /* 4. Find Predicted Class (Argmax of Logits) */
    int     predicted_class = 0;
    int32_t max_score       = output_logits[0];
    for (int c = 1; c < 4; c++) {
        if (output_logits[c] > max_score) {
            max_score       = output_logits[c];
            predicted_class = c;
        }
    }

    /* 5. Save Results to SRAM for Host / Testbench Verification */
    volatile int32_t *sram_out = (volatile int32_t *)RESULTS_SRAM_BASE;
    
    /* Save Hidden Activations */
    for (int i = 0; i < 8; i++) {
        sram_out[i] = hidden_layer_output[i];
    }
    
    /* Save Output Logits */
    for (int i = 0; i < 4; i++) {
        sram_out[8 + i] = output_logits[i];
    }
    
    /* Save Predicted Class */
    sram_out[12] = (int32_t)predicted_class;

    /* 6. Write Success Signature to 0x0000_10FC */
    *(volatile uint32_t *)SIGNATURE_ADDR = SIGNATURE_SUCCESS;

    return 0;
}
