class CalcSettings {
  var maxTransits = 0;
  var threads = 5;
  var reverse = false;
  var fullBalanced = false;
  var mirror = false;
  var onlyDifferentHexes = false;

  bool isDefault() {
    return maxTransits == 0 &&
        threads == 5 &&
        reverse == false &&
        fullBalanced == false &&
        mirror == false && onlyDifferentHexes == false;
  }

  void setDefault() {
    maxTransits = 0;
    threads = 5;
    reverse = false;
    fullBalanced = false;
    mirror = false;
    onlyDifferentHexes = false;
  }
}
