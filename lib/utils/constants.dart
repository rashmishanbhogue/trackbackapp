// constants.dart, contains:
// the 6 standard category labels that are always displayed in the aimetricsscreen
// timefilter constants

const List<String> standardCategories = [
  'Productive',
  'Maintenance',
  'Wellbeing',
  'Leisure',
  'Social',
  'Idle',
];

enum TimeFilter {
  all,
  day,
  week,
  month,
  year,
}
