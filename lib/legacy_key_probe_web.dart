import 'package:web/web.dart';

import 'plant_store.dart';

const String legacyBrowserStorageKey = 'flutter.$plantStorageKey';

bool? legacyBrowserKeyPresent() {
  return window.localStorage.getItem(legacyBrowserStorageKey) != null;
}
