const String apiBase =
    String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:8080');

const List<String> intentSignals = [
  'romantic',
  'more_time',
  'friendship',
  'unsure',
  'meet',
  'not_compatible',
];

const List<String> temperatures = [
  'chatty',
  'normal',
  'quiet',
  'low_energy',
  'space',
];