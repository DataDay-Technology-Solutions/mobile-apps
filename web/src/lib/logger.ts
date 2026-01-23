import pino from 'pino'

// Create a logger instance
const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  transport: process.env.NODE_ENV === 'development'
    ? {
        target: 'pino-pretty',
        options: {
          colorize: true,
          translateTime: 'SYS:standard',
          ignore: 'pid,hostname',
        },
      }
    : undefined,
  base: {
    env: process.env.NODE_ENV,
  },
  formatters: {
    level: (label) => ({ level: label }),
  },
})

// Structured logging helpers
export const log = {
  // General logging
  info: (message: string, data?: Record<string, unknown>) =>
    logger.info({ ...data }, message),

  warn: (message: string, data?: Record<string, unknown>) =>
    logger.warn({ ...data }, message),

  error: (message: string, error?: Error | unknown, data?: Record<string, unknown>) => {
    const errorData = error instanceof Error
      ? { error: { message: error.message, stack: error.stack, name: error.name } }
      : { error }
    logger.error({ ...errorData, ...data }, message)
  },

  debug: (message: string, data?: Record<string, unknown>) =>
    logger.debug({ ...data }, message),

  // Auth-specific logging
  auth: {
    signIn: (userId: string, email: string) =>
      logger.info({ userId, email, action: 'sign_in' }, 'User signed in'),

    signOut: (userId: string) =>
      logger.info({ userId, action: 'sign_out' }, 'User signed out'),

    signUp: (userId: string, email: string, role: string) =>
      logger.info({ userId, email, role, action: 'sign_up' }, 'User signed up'),

    passwordReset: (email: string) =>
      logger.info({ email, action: 'password_reset' }, 'Password reset requested'),

    failed: (email: string, reason: string) =>
      logger.warn({ email, reason, action: 'auth_failed' }, 'Authentication failed'),
  },

  // Classroom-specific logging
  classroom: {
    created: (classroomId: string, teacherId: string, name: string) =>
      logger.info({ classroomId, teacherId, name, action: 'classroom_created' }, 'Classroom created'),

    studentAdded: (classroomId: string, studentId: string) =>
      logger.info({ classroomId, studentId, action: 'student_added' }, 'Student added to classroom'),

    parentJoined: (classroomId: string, parentId: string, code: string) =>
      logger.info({ classroomId, parentId, code, action: 'parent_joined' }, 'Parent joined classroom'),
  },

  // Message-specific logging
  message: {
    sent: (conversationId: string, senderId: string, recipientId: string) =>
      logger.info({ conversationId, senderId, recipientId, action: 'message_sent' }, 'Message sent'),

    read: (conversationId: string, userId: string) =>
      logger.info({ conversationId, userId, action: 'message_read' }, 'Message read'),
  },

  // Points-specific logging
  points: {
    awarded: (studentId: string, points: number, reason: string, awardedBy: string) =>
      logger.info({ studentId, points, reason, awardedBy, action: 'points_awarded' }, 'Points awarded'),

    deducted: (studentId: string, points: number, reason: string, deductedBy: string) =>
      logger.info({ studentId, points, reason, deductedBy, action: 'points_deducted' }, 'Points deducted'),
  },

  // Story-specific logging
  story: {
    created: (storyId: string, classroomId: string, authorId: string) =>
      logger.info({ storyId, classroomId, authorId, action: 'story_created' }, 'Story created'),

    liked: (storyId: string, userId: string) =>
      logger.info({ storyId, userId, action: 'story_liked' }, 'Story liked'),
  },

  // API-specific logging
  api: {
    request: (method: string, path: string, userId?: string) =>
      logger.info({ method, path, userId, action: 'api_request' }, `API ${method} ${path}`),

    response: (method: string, path: string, status: number, duration: number) =>
      logger.info({ method, path, status, duration, action: 'api_response' }, `API ${method} ${path} -> ${status}`),

    error: (method: string, path: string, error: Error | unknown, userId?: string) => {
      const errorData = error instanceof Error
        ? { message: error.message, stack: error.stack }
        : { error }
      logger.error({ method, path, userId, error: errorData, action: 'api_error' }, `API Error: ${method} ${path}`)
    },
  },

  // Database-specific logging
  db: {
    query: (table: string, operation: string, duration?: number) =>
      logger.debug({ table, operation, duration, action: 'db_query' }, `DB ${operation} on ${table}`),

    error: (table: string, operation: string, error: Error | unknown) => {
      const errorData = error instanceof Error
        ? { message: error.message, stack: error.stack }
        : { error }
      logger.error({ table, operation, error: errorData, action: 'db_error' }, `DB Error: ${operation} on ${table}`)
    },
  },

  // Performance logging
  perf: {
    slow: (operation: string, duration: number, threshold: number) =>
      logger.warn({ operation, duration, threshold, action: 'slow_operation' }, `Slow operation: ${operation} took ${duration}ms`),
  },
}

export default logger
