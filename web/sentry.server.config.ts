import * as Sentry from "@sentry/nextjs"

Sentry.init({
  dsn: "https://ed456b17c19e780765317fe05f28687b@o4510757103599616.ingest.us.sentry.io/4510757112512512",

  // Performance Monitoring
  tracesSampleRate: 1.0, // Capture 100% of transactions for demo

  // Set environment
  environment: process.env.NODE_ENV,

  // Enable debug in development
  debug: process.env.NODE_ENV === "development",

  // Filter out noisy errors
  ignoreErrors: [
    "NEXT_NOT_FOUND",
    "NEXT_REDIRECT",
  ],

  // Before sending, add server context
  beforeSend(event) {
    // Add server info
    event.tags = {
      ...event.tags,
      runtime: "nodejs",
      nextjs: true,
    }

    return event
  },
})
