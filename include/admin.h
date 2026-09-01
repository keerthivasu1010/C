/**
 * @file admin.h
 * @brief Administrator panel: default bootstrap account and the
 *        interactive admin menu (list users, freeze/unfreeze,
 *        clear login lockouts).
 */

#ifndef ADMIN_H
#define ADMIN_H

/**
 * @brief Ensure the default bootstrap administrator account exists,
 *        creating it (with DEFAULT_ADMIN_USERNAME / PASSWORD / PIN)
 *        if no admin account is present yet.
 * @return 0 on success (created or already present), -1 on failure.
 */
int admin_ensure_default_account(void);

/**
 * @brief Run the interactive administrator menu loop.
 * @param adminUsername Username of the logged-in administrator; a
 *                       NULL value is a no-op.
 */
void admin_run_panel(const char *adminUsername);

#endif /* ADMIN_H */
