/** @type {import('next').NextConfig} */
const nextConfig = {
  // Served by GitHub Pages as this repo's project site: syedarhamraza.github.io/one-dialer/. The folder is site/, not web/,
  // because Flutter reserves web/ for its own web platform.
  // Files in public/ are reached as /one-dialer/<file>; next/link adds the prefix itself.
  basePath: "/one-dialer",
  output: "export",
  images: { unoptimized: true },
  trailingSlash: true,
  outputFileTracingRoot: import.meta.dirname,
};

export default nextConfig;
