// aimetrics_category_utils.dart, to categorise the labels into the 6 predefined broader ones

import '../utils/constants.dart';

String getBroaderCategory(String label) {
  if (standardCategories.contains(label)) {
    return label;
  }
  return 'Uncategorised';
}
