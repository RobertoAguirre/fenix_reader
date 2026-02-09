/// Mensaje diario (push) para el calendario
class DailyMessage {
  final DateTime date;
  final String title;
  final String message;

  const DailyMessage({
    required this.date,
    required this.title,
    required this.message,
  });
}
