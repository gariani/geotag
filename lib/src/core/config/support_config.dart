/// Buy Me a Coffee URL.
/// Set via --dart-define=BUY_ME_A_COFFEE_URL=... when running/building,
/// or use scripts/local_run.sh (gitignored) to store your URL.
const String buyMeACoffeeUrl = String.fromEnvironment(
  'BUY_ME_A_COFFEE_URL',
  defaultValue: 'https://www.buymeacoffee.com/',
);
