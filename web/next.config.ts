import type { NextConfig } from "next"
import { withSentryConfig } from "@sentry/nextjs"

const nextConfig: NextConfig = {
  // Sentry requires source maps
  productionBrowserSourceMaps: true,
}

// Sentry configuration options
const sentryWebpackPluginOptions = {
  // Organization and project from Sentry
  org: "dataday-technology-solutions",
  project: "javascript-nextjs",

  // Only upload source maps in production
  silent: process.env.NODE_ENV !== "production",

  // Upload source maps for better error tracking
  widenClientFileUpload: true,

  // Automatically tree-shake Sentry logger statements
  disableLogger: true,

  // Hide source maps from browser devtools in production
  hideSourceMaps: true,

  // Automatically instrument API routes
  automaticVercelMonitors: true,
}

export default withSentryConfig(nextConfig, sentryWebpackPluginOptions)
