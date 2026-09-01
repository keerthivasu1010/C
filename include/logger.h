/**
 * @file logger.h
 * @brief Thread-safe timestamped diagnostic logger interface.
 */

#ifndef LOGGER_H
#define LOGGER_H

typedef enum
{
    LOG_LEVEL_DEBUG = 0,
    LOG_LEVEL_INFO,
    LOG_LEVEL_WARN,
    LOG_LEVEL_ERROR,
    LOG_LEVEL_FATAL
} LogLevel;

/**
 * @brief Set the minimum level that will be emitted by logger_log().
 *        Values outside [LOG_LEVEL_DEBUG, LOG_LEVEL_FATAL] are ignored.
 */
void logger_set_level(LogLevel level);

/**
 * @brief Emit a printf-style diagnostic message if level is at or
 *        above the configured minimum level. Writes to stderr and
 *        mirrors to database/app.log. A NULL fmt is a no-op.
 */
void logger_log(LogLevel level, const char *fmt, ...);

/** Convenience wrappers around logger_log() for each level. */
#define LOG_DEBUG(...) logger_log(LOG_LEVEL_DEBUG, __VA_ARGS__)
#define LOG_INFO(...)  logger_log(LOG_LEVEL_INFO,  __VA_ARGS__)
#define LOG_WARN(...)  logger_log(LOG_LEVEL_WARN,  __VA_ARGS__)
#define LOG_ERROR(...) logger_log(LOG_LEVEL_ERROR, __VA_ARGS__)
#define LOG_FATAL(...) logger_log(LOG_LEVEL_FATAL, __VA_ARGS__)

#endif /* LOGGER_H */
