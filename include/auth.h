/**
 * @file auth.h
 * @brief Interactive user registration and login/authentication.
 */

#ifndef AUTH_H
#define AUTH_H

#include "bank.h"

/**
 * @brief Interactively register a new user, reading credentials from
 *        stdin, hashing and persisting the new account.
 * @return 0 on success, -1 on validation failure or storage error.
 */
int registration_register(void);

/**
 * @brief Interactively authenticate a user, reading credentials from
 *        stdin. Enforces frozen-account and brute-force lockout
 *        checks.
 *
 * @param outSession [out] Populated with the authenticated session
 *                   on success.
 * @return 0 on success, -1 on failure.
 */
int login_authenticate(Session *outSession);

#endif /* AUTH_H */
