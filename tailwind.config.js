/** @type {import('tailwindcss').Config} */
module.exports = {
  // NOTE: Update this to include the paths to all of your component files.
  content: ['./app/**/*.{js,jsx,ts,tsx}', './components/**/*.{js,jsx,ts,tsx}'],
  presets: [require('nativewind/preset')],
  theme: {
    extend: {
      boxShadow: {
        duolingoGreen: '0 4px 0 #58a700',
        duolingoWhiteLight: '0 4px 0 #e5e5e5',
        duolingoWhiteDark: '0 4px 0 #37464f',
        duolingoBlue: '0 4px 0 #1899d6',
        duolingoRed: '0 4px 0 #ea2b2b',
        duolingoSelectedLight: '0 4px 0 #84d8ff',
        duolingoSelectedDark: '0 4px 0 #3f85a7',
        duolingoDisabledLight: '0 4px 0 #e5e5e5',
        duolingoDisabledDark: '0 4px 0 #37464f'
      },
      fontFamily: {}
    }
  },
  plugins: []
}
