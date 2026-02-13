import 'package:flutter/foundation.dart';

/// Notifica a la pantalla de calendario que debe recargar (mensajes + actividad).
class CalendarRefreshNotifier extends ChangeNotifier {
  int _trigger = 0;
  int get trigger => _trigger;

  void refresh() {
    _trigger++;
    notifyListeners();
  }
}
