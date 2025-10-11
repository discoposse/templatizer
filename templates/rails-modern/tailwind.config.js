// Tailwind CSS configuration template
// This file will be copied to config/tailwind.config.js

module.exports = {
    content: [
      "./app/views/**/*.{erb,haml,slim}",
      "./app/helpers/**/*.rb",
      "./app/assets/stylesheets/**/*.css",
      "./app/javascript/**/*.{js,ts}",
      "./app/components/**/*.{erb,rb}" // if you use ViewComponent/Phlex/etc.
    ],
    theme: {
      extend: {
        colors: {
          primary: {
            50: '#eff6ff',
            500: '#3b82f6',
            600: '#2563eb',
            700: '#1d4ed8',
          }
        }
      }
    },
    plugins: []
  }
