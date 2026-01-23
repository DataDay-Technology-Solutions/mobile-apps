import * as Sentry from "@sentry/nextjs"

Sentry.init({
  dsn: "https://ed456b17c19e780765317fe05f28687b@o4510757103599616.ingest.us.sentry.io/4510757112512512",

  // Performance Monitoring
  tracesSampleRate: 1.0, // Capture 100% of transactions for demo, reduce in production

  // Session Replay for debugging user issues
  replaysSessionSampleRate: 0.1, // 10% of sessions
  replaysOnErrorSampleRate: 1.0, // 100% of sessions with errors

  // Set environment
  environment: process.env.NODE_ENV,

  // Enable debug in development
  debug: process.env.NODE_ENV === "development",

  // Integrations
  integrations: [
    Sentry.replayIntegration({
      maskAllText: false,
      blockAllMedia: false,
    }),
    Sentry.browserTracingIntegration(),
  ],

  // Filter out noisy errors
  ignoreErrors: [
    // Browser extensions
    /extensions\//i,
    /^chrome:\/\//i,
    // Network errors that are expected
    "Network request failed",
    "Failed to fetch",
    "Load failed",
    // User-initiated navigation
    "AbortError",
  ],

  // Before sending error, add extra context
  beforeSend(event, hint) {
    // Add user context if available
    const user = typeof window !== "undefined"
      ? (window as unknown as { __user?: { id: string; email: string; role: string } }).__user
      : null

    if (user) {
      event.user = {
        id: user.id,
        email: user.email,
        role: user.role,
      }
    }

    // Log to console in development
    if (process.env.NODE_ENV === "development") {
      console.error("[Sentry Error]", hint.originalException || hint.syntheticException)
    }

    return event
  },
})
