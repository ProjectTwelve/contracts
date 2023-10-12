module.exports = {
  // 128 character each line
  printWidth: 128,
  // use 2 Spaces for indentation
  tabWidth: 2,
  // don't use tab
  useTabs: false,
  // semicolon required at end of line
  semi: true,
  // use single quote
  singleQuote: true,
  // The object's key is quoted only when necessary
  quoteProps: 'as-needed',
  // comma is required at the end
  trailingComma: 'all',
  // spaces are required at the beginning and end of the curly brackets
  bracketSpacing: true,
  // Arrow functions, when there is only one parameter, also need parentheses
  arrowParens: 'always',
  // The scope of each file format is the entire contents of the file
  rangeStart: 0,
  rangeEnd: Infinity,
  // No need to write @prettier at the beginning of the file
  requirePragma: false,
  // No need to automatically insert @prettier at the beginning of the file
  insertPragma: false,
  // Use default wrapping standard
  proseWrap: 'preserve',
  // Decide whether to wrap html according to the display style
  htmlWhitespaceSensitivity: 'css',
  // Line breaks use lf
  endOfLine: 'lf',
  // Format embedded content
  embeddedLanguageFormatting: 'auto',
};
