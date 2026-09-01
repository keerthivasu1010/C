/**
 * @file sha256.h
 * @brief SHA-256 implementation per FIPS PUB 180-4.
 */

#ifndef SHA256_H
#define SHA256_H

#include <stddef.h>
#include <stdint.h>

#define SHA256_BLOCK_SIZE 32U   /* SHA-256 digest size in bytes */
#define SHA256_HEX_LEN     (SHA256_BLOCK_SIZE * 2U)
#define SHA256_HEX_BUF     (SHA256_HEX_LEN + 1U)

typedef struct
{
    uint8_t  data[64];
    uint32_t datalen;
    uint64_t bitlen;
    uint32_t state[8];
} SHA256_CTX;

void sha256_init(SHA256_CTX *ctx);
void sha256_update(SHA256_CTX *ctx, const uint8_t data[], size_t len);
void sha256_final(SHA256_CTX *ctx, uint8_t hash[]);

/**
 * @brief Compute the SHA-256 digest of a buffer and hex-encode it.
 * @return 0 on success, -1 on invalid arguments.
 */
int sha256_hash_buffer(const uint8_t *input, size_t len, char outHex[SHA256_HEX_BUF]);

/**
 * @brief Compute the SHA-256 digest of a NUL-terminated string and
 *        hex-encode it.
 * @return 0 on success, -1 on invalid arguments.
 */
int sha256_hash_string(const char *input, char outHex[SHA256_HEX_BUF]);

#endif /* SHA256_H */
