export const outlinedStyles = (isDarkMode: boolean) => ({
  green: 'border-2 border-b-0 border-[#58a700]',
  blue: 'border-2 border-b-0 border-[#1899d6]',
  red: 'border-2 border-b-0 border-[#ea2b2b]',
  white: `border-2 border-b-0 ${isDarkMode ? 'border-[#37464f]' : 'border-[#e5e5e5]'}`
})

export const wrapperStyles = (isDarkMode: boolean) => ({
  green: 'bg-[#58cc02] shadow-duolingoGreen',
  blue: 'bg-[#49c0f8] shadow-duolingoBlue',
  red: 'bg-[#ff4b4b] shadow-duolingoRed',
  white: `${isDarkMode ? 'bg-[#131f24] shadow-duolingoWhiteDark' : 'bg-[#ffffff] shadow-duolingoWhiteLight'}`
})

export const wrapperDisabledStyles = (isDarkMode: boolean) =>
  `${isDarkMode ? 'bg-[#37464f] shadow-duolingoDisabledDark' : 'bg-[#e5e5e5] shadow-duolingoDisabledLight'}`
export const wrapperSelectedStyles = (isDarkMode: boolean) =>
  isDarkMode
    ? 'bg-[#202f36] border-[#3f85a7] shadow-duolingoSelectedDark'
    : 'bg-[#ddf4ff] border-[#84d8ff] shadow-duolingoSelectedLight'

export const textStyles = (isDarkMode: boolean) => ({
  green: 'text-white',
  red: 'text-white',
  white: `${isDarkMode ? 'text-[#f1f7fb]' : 'text-[#4b4b4b]'}`,
  blue: 'text-[#131f64]'
})

export const textDisabledStyles = (isDarkMode: boolean) =>
  `${isDarkMode ? 'text-[#52656d]' : 'text-[#afafaf]'}`
export const textSelectedStyles = 'text-[#1899d6]'

export const sizeStyles = {
  small: {
    wrapper: 'rounded-[16px]',
    text: 'text-[15px] leading-[1.2] tracking-[0.8px]'
  },
  large: { wrapper: 'rounded-[12px]', text: 'text-[19px] leading-[1.4]' }
}

export const fontFamilyStyles = {
  small: { fontFamily: 'DINNextRoundedLTW01-Bold' },
  large: { fontFamily: 'DINNextRoundedLTW01-Regular' }
}
