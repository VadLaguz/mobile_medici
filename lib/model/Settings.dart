class CalcSettings {
  var maxTransits = 0;
  var threads = 5;

  bool isDefault() {
    return maxTransits == 0 && threads == 5;
  }

  void setDefault() {
    maxTransits = 0;
    threads = 5;
  }
}
