const defaultTheme = require("tailwindcss/defaultTheme")

module.exports = {
  content: [
    "./app/views/**/*.{erb,html,rb}",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.{js,jsx,ts,tsx}"
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter", ...defaultTheme.fontFamily.sans]
      }
    }
  },
  plugins: []
}
