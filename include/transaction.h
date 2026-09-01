/**
 * @file transaction.h
 * @brief UPI-style fund transfer, history, and persistence records.
 */

#ifndef TRANSACTION_H
#define TRANSACTION_H

#include "bank.h"

#define MAX_TIMESTAMP_LEN     32
#define MAX_ENCRYPTED_HEX_LEN 256
#define MAX_HASH_HEX_LEN      65

/**
 * @brief A single persisted UPI transaction record.
 *
 * encryptedData holds the AES-128/ECB, PKCS#7-padded, hex-encoded
 * ciphertext of the canonical "sender|receiver|amount|timestamp"
 * payload. hash holds the hex-encoded SHA-256 integrity digest
 * computed over the same logical fields (see integrity.h).
 */
typedef struct
{
    char   sender[MAX_USERNAME_LEN];
    char   receiver[MAX_UPI_LEN];
    double amount;
    char   timestamp[MAX_TIMESTAMP_LEN];
    char   encryptedData[MAX_ENCRYPTED_HEX_LEN];
    char   hash[MAX_HASH_HEX_LEN];
} Transaction;

/**
 * @brief Validate the syntactic format of a UPI ID
 *        ("<handle>@<psp>"), e.g. "alice@digitalbank".
 * @return 1 if valid, 0 otherwise.
 */
int upi_is_valid_format(const char *upiId);

/**
 * @brief Transfer funds from a local user to a UPI ID.
 *
 * @param sender      Sender's username.
 * @param receiverUpi Receiver's UPI ID (may or may not be local).
 * @param amount      Amount to transfer; must be > 0.
 * @return 0 on success; -1 invalid arguments/self-transfer;
 *         -2 sender not found; -4 insufficient balance;
 *         -5 storage/crypto error; -6 malformed UPI ID.
 */
int transaction_transfer(const char *sender, const char *receiverUpi, double amount);

/**
 * @brief Print the transaction history involving a given user.
 * @return Number of matching transactions, or -1 on error.
 */
int transaction_show_history(const char *username);

#endif /* TRANSACTION_H */
