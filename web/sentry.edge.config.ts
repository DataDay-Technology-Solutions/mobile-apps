import * as Sentry from "@sentry/nextjs"

Sentry.init({
  dsn: "https://ed456b17c19e780765317fe05f28687b@o4510757103599616.ingest.us.sentry.io/4510757112512512",

  // Performance Monitoring
  tracesSampleRate: 1.0,

  // Set environment
  environment: process.env.NODE_ENV,

  // Enable debug in development
  debug: process.env.NODE_ENV === "development",
})
