import 'dart:io';

bool showThreads() {
  return !Platform.isIOS;
}

bool ruLocale() {
  return true;
  //return Platform.localeName.contains("ru");
}