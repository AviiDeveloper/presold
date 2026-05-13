const path = require("node:path");

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  // Pin tracing root to this package so Next ignores the home-dir lockfile
  // it would otherwise pick up.
  outputFileTracingRoot: path.join(__dirname),
};

module.exports = nextConfig;
