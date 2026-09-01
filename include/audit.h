/**
 * @file audit.h
 * @brief Append-only audit log writer interface.
 */

#ifndef AUDIT_H
#define AUDIT_H

/**
 * @brief Append a timestamped audit entry.
 *
 * @param username Acting username, or NULL to log as "SYSTEM".
 * @param event    Free-form event description, or NULL for empty.
 * @return 0 on success, -1 on failure.
 */
int audit_log(const char *username, const char *event);

#endif /* AUDIT_H */
