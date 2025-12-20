// lib/ui/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/history_provider.dart';
import 'record_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('履歴カレンダー')),
      body: Column(
        children: [
          // カレンダー部分
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: provider.focusedDay,
            selectedDayPredicate: (day) => isSameDay(provider.selectedDay, day),
            onDaySelected: provider.onDaySelected,
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
            ),
          ),
          const Divider(),
          // 選択された日のリスト部分
          Expanded(
            child: ListView.builder(
              itemCount: provider.selectedDayRecords.length,
              itemBuilder: (context, index) {
                final record = provider.selectedDayRecords[index];
                return ListTile(
                  title: Text(record.eventText),
                  subtitle: Text("${record.timeString} / ${record.weather ?? ''}"),
                  trailing: const Icon(Icons.chevron_right),
                  // ★ここで詳細画面へ遷移！
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecordDetailScreen(record: record),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}