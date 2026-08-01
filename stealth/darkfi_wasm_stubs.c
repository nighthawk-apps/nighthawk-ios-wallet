/*
 * darkfi_wasm_stubs.c
 * stealth
 *
 * WASM host function stubs required by libdarkfi_mobile_ffi.a
 * These are placeholder implementations for WASM runtime host functions
 * that the DarkFi SDK expects. In production, these will be backed by
 * the actual WASM runtime (wasmer/wasmtime).
 *
 * All functions return 0/success as no-ops until the full WASM runtime
 * is integrated.
 */

#include <stdint.h>
#include <stddef.h>

// ============================================================
// Database operations
// ============================================================

int32_t db_contains_key_(const uint8_t *key_ptr, uint32_t key_len) {
    (void)key_ptr; (void)key_len;
    return 0;
}

int32_t db_contains_key_local_(const uint8_t *key_ptr, uint32_t key_len) {
    (void)key_ptr; (void)key_len;
    return 0;
}

int32_t db_get_(const uint8_t *key_ptr, uint32_t key_len) {
    (void)key_ptr; (void)key_len;
    return -1; // not found
}

int32_t db_get_local_(const uint8_t *key_ptr, uint32_t key_len) {
    (void)key_ptr; (void)key_len;
    return -1;
}

int32_t db_set_(const uint8_t *key_ptr, uint32_t key_len,
                const uint8_t *val_ptr, uint32_t val_len) {
    (void)key_ptr; (void)key_len; (void)val_ptr; (void)val_len;
    return 0;
}

int32_t db_set_local_(const uint8_t *key_ptr, uint32_t key_len,
                      const uint8_t *val_ptr, uint32_t val_len) {
    (void)key_ptr; (void)key_len; (void)val_ptr; (void)val_len;
    return 0;
}

int32_t db_del_(const uint8_t *key_ptr, uint32_t key_len) {
    (void)key_ptr; (void)key_len;
    return 0;
}

int32_t db_del_local_(const uint8_t *key_ptr, uint32_t key_len) {
    (void)key_ptr; (void)key_len;
    return 0;
}

int32_t db_init_(const uint8_t *ptr, uint32_t len) {
    (void)ptr; (void)len;
    return 0;
}

int32_t db_lookup_(const uint8_t *ptr, uint32_t len) {
    (void)ptr; (void)len;
    return -1;
}

int32_t db_lookup_local_(const uint8_t *ptr, uint32_t len) {
    (void)ptr; (void)len;
    return -1;
}

// ============================================================
// Blockchain / transaction introspection
// ============================================================

int32_t get_block_target_(void) {
    return 0;
}

int32_t get_blockchain_time_(void) {
    return 0;
}

int32_t get_call_index_(void) {
    return 0;
}

int32_t get_last_block_height_(void) {
    return 0;
}

int32_t get_object_bytes_(const uint8_t *ptr, uint32_t len) {
    (void)ptr; (void)len;
    return -1;
}

int32_t get_object_size_(const uint8_t *ptr, uint32_t len) {
    (void)ptr; (void)len;
    return 0;
}

int32_t get_tx_(void) {
    return -1;
}

int32_t get_tx_hash_(void) {
    return -1;
}

int32_t get_tx_location_(void) {
    return -1;
}

int32_t get_verifying_block_height_(void) {
    return 0;
}

// ============================================================
// Merkle tree operations
// ============================================================

int32_t merkle_add_(const uint8_t *ptr, uint32_t len) {
    (void)ptr; (void)len;
    return 0;
}

int32_t merkle_add_local_(const uint8_t *ptr, uint32_t len) {
    (void)ptr; (void)len;
    return 0;
}

int32_t sparse_merkle_insert_batch_(const uint8_t *ptr, uint32_t len) {
    (void)ptr; (void)len;
    return 0;
}

// ============================================================
// Misc
// ============================================================

int32_t set_return_data_(const uint8_t *ptr, uint32_t len) {
    (void)ptr; (void)len;
    return 0;
}

int32_t zkas_db_set_(const uint8_t *ptr, uint32_t len) {
    (void)ptr; (void)len;
    return 0;
}
