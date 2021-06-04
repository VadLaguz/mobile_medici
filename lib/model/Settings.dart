class CalcSettings {
  var maxTransits = 0;
  var threads = 5;
  var reverse = false;

  bool isDefault() {
    return maxTransits == 0 && threads == 5 && reverse == false;
  }

  void setDefault() {
    maxTransits = 0;
    threads = 5;
    reverse = false;
  }
}
