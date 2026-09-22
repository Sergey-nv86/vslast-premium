// Build metadata supplied at compile time.
//
// Production Web build passes:
// --dart-define=BUILD_ID=YYYYMMDD-HHMMSS
// --dart-define=BUILD_DATE=YYYY-MM-DD
// --dart-define=BUILD_TIME=HH:MM:SS
// --dart-define=BUILD_LABEL=YYYY-MM-DD HH:MM:SS

const String buildId = String.fromEnvironment('BUILD_ID', defaultValue: 'dev');

const String buildDate = String.fromEnvironment('BUILD_DATE', defaultValue: '');

const String buildTime = String.fromEnvironment('BUILD_TIME', defaultValue: '');

const String buildLabel = String.fromEnvironment(
  'BUILD_LABEL',
  defaultValue: 'dev',
);
