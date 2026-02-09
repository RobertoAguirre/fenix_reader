import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/daily_message.dart';
import '../services/wordpress_service.dart';

/// Pantalla de calendario: mensajes diarios (push) por fecha.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;
  static const List<String> _weekdays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  final WordPressService _wpService = WordPressService();
  Map<DateTime, List<DailyMessage>> _messagesByDate = {};
  bool _loading = false;
  final TextEditingController _messagesSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _loadMessagesForMonth();
    _messagesSearchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _messagesSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadMessagesForMonth() async {
    if (!mounted) return;
    setState(() { _loading = true; });
    final from = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final to = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final list = await _wpService.getPushLog(from, to);
    final map = <DateTime, List<DailyMessage>>{};
    for (final m in list) {
      (map[m.date] ??= []).add(m);
    }
    if (!mounted) return;
    setState(() {
      _messagesByDate = map;
      _loading = false;
    });
  }

  int _daysInMonth(DateTime month) {
    return DateTime(month.year, month.month + 1, 0).day;
  }

  int _firstWeekday(DateTime month) {
    final w = DateTime(month.year, month.month, 1).weekday;
    return w - 1;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _daysInMonth(_focusedMonth);
    final firstWeekday = _firstWeekday(_focusedMonth);
    final today = DateTime.now();
    final monthName = _monthName(_focusedMonth.month);

    return Scaffold(
      backgroundColor: AppColors.origen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Calendario',
                style: AppTypography.kaushanTitle(
                  fontSize: 28,
                  color: AppColors.raizSagrada,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () async {
                    setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month - 1,
                      );
                    });
                    await _loadMessagesForMonth();
                  },
                  icon: Icon(
                    Icons.chevron_left,
                    color: AppColors.raizSagrada,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$monthName ${_focusedMonth.year}',
                  style: AppTypography.ralewayBold(
                    fontSize: 18,
                    color: AppColors.raizSagrada,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () async {
                    setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month + 1,
                      );
                    });
                    await _loadMessagesForMonth();
                  },
                  icon: Icon(
                    Icons.chevron_right,
                    color: AppColors.raizSagrada,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _weekdays
                    .map((d) => SizedBox(
                          width: 36,
                          child: Center(
                            child: Text(
                              d,
                              style: AppTypography.ralewayBold(
                                fontSize: 12,
                                color: AppColors.raizSagrada.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 260,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: 42,
                  itemBuilder: (context, index) {
                    final dayIndex = index - firstWeekday;
                    if (dayIndex < 1 || dayIndex > daysInMonth) {
                      return const SizedBox.shrink();
                    }
                    final day = dayIndex;
                    final dateKey = DateTime(_focusedMonth.year, _focusedMonth.month, day);
                    final messages = _messagesByDate[dateKey] ?? [];
                    final isToday = _focusedMonth.year == today.year &&
                        _focusedMonth.month == today.month &&
                        day == today.day;
                    return _DayCell(
                      day: day,
                      isToday: isToday,
                      hasMessage: messages.isNotEmpty,
                      messages: messages,
                      onTap: () => _showMessagesForDay(context, dateKey, messages),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Mensajes diarios',
                style: AppTypography.ralewayBold(
                  fontSize: 16,
                  color: AppColors.raizSagrada,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMessagesSearchBar(),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildMessagesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.raizSagrada.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: _messagesSearchController,
        decoration: InputDecoration(
          hintText: 'Buscar mensajes...',
          hintStyle: AppTypography.ralewayRegular(
            fontSize: 14,
            color: AppColors.raizSagrada.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.raizSagrada.withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: AppTypography.ralewayRegular(
          fontSize: 14,
          color: AppColors.raizSagrada,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  List<_MessageEntry> _getFlattenedMessages() {
    final list = <_MessageEntry>[];
    for (final e in _messagesByDate.entries) {
      for (final m in e.value) {
        list.add(_MessageEntry(date: e.key, message: m));
      }
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Widget _buildMessagesList() {
    final entries = _getFlattenedMessages();
    final query = _messagesSearchController.text.toLowerCase().trim();
    final filtered = query.isEmpty
        ? entries
        : entries.where((e) {
            final t = e.message.title.toLowerCase();
            final b = e.message.message.toLowerCase();
            return t.contains(query) || b.contains(query);
          }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          query.isEmpty
              ? 'No hay mensajes este mes'
              : 'Ningún mensaje coincide con la búsqueda',
          style: AppTypography.ralewayRegular(
            fontSize: 14,
            color: AppColors.raizSagrada.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final entry = filtered[index];
        final dateKey = entry.date;
        final messages = _messagesByDate[dateKey] ?? [];
        return _MessageListTile(
          date: dateKey,
          message: entry.message,
          monthName: _monthName(dateKey.month),
          onTap: () => _showMessagesForDay(context, dateKey, messages),
        );
      },
    );
  }

  String _monthName(int month) {
    const names = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return names[month - 1];
  }

  void _showMessagesForDay(BuildContext context, DateTime dateKey, List<DailyMessage> messages) {
    if (messages.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.origen,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${dateKey.day} ${_monthName(dateKey.month)} ${dateKey.year}',
                style: AppTypography.ralewayBold(
                  fontSize: 14,
                  color: AppColors.raizSagrada.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              ...messages.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (m.title.isNotEmpty)
                      Text(
                        m.title,
                        style: AppTypography.ralewayBold(
                          fontSize: 16,
                          color: AppColors.raizSagrada,
                        ),
                      ),
                    if (m.title.isNotEmpty) const SizedBox(height: 4),
                    if (m.message.isNotEmpty)
                      Text(
                        m.message,
                        style: AppTypography.ralewayRegular(
                          fontSize: 14,
                          color: AppColors.raizSagrada,
                        ),
                      ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageEntry {
  final DateTime date;
  final DailyMessage message;
  _MessageEntry({required this.date, required this.message});
}

class _MessageListTile extends StatelessWidget {
  final DateTime date;
  final DailyMessage message;
  final String monthName;
  final VoidCallback onTap;

  const _MessageListTile({
    required this.date,
    required this.message,
    required this.monthName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.raizSagrada.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${date.day} $monthName ${date.year}',
              style: AppTypography.ralewayRegular(
                fontSize: 12,
                color: AppColors.raizSagrada.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            if (message.title.isNotEmpty)
              Text(
                message.title,
                style: AppTypography.ralewayBold(
                  fontSize: 14,
                  color: AppColors.raizSagrada,
                ),
              ),
            if (message.title.isNotEmpty && message.message.isNotEmpty)
              const SizedBox(height: 2),
            if (message.message.isNotEmpty)
              Text(
                message.message,
                style: AppTypography.ralewayRegular(
                  fontSize: 13,
                  color: AppColors.raizSagrada.withValues(alpha: 0.85),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool hasMessage;
  final List<DailyMessage> messages;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.hasMessage,
    required this.messages,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isToday
              ? AppColors.ascenso.withValues(alpha: 0.3)
              : AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday
                ? AppColors.ascenso
                : hasMessage
                    ? AppColors.expansionAlquimica.withValues(alpha: 0.5)
                    : AppColors.raizSagrada.withValues(alpha: 0.15),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: AppTypography.ralewayRegular(
                fontSize: 14,
                color: AppColors.raizSagrada,
              ),
            ),
            if (hasMessage)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.expansionAlquimica,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
