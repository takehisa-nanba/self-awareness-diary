// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// isar, main.dart, models/record.dart は Core に移動したため削除

import '../core/history_core.dart'; // ★★★ Core をインポート ★★★
import '../models/record.dart'; // Record モデルは UI で使用するため残す
import '../widgets/app_shell.dart';
import 'history_detail_screen.dart'; 

// TableCalendarの isSameDay を利用できるようにする
import 'package:table_calendar/table_calendar.dart' show isSameDay, CalendarBuilders, TableCalendar;


// ★★★ StatelessWidget に変更 ★★★
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HistoryCore>(
      create: (context) => HistoryCore(),
      child: Consumer<HistoryCore>(
        builder: (context, core, child) {
          // 選択された日の記録リストをフィルタリング (Core の状態を使用)
          final List<Record> selectedDayRecords = core.allRecords.where((record) {
            if (core.selectedDay == null) return true;
            return isSameDay(record.recordDate, core.selectedDay!);
          }).toList();

          return AppShell(
            child: Scaffold(
              appBar: AppBar(title: const Text('履歴を見る'), elevation: 1),
              body: Column(
                children: [
                  // 1. カレンダーウィジェット
                  TableCalendar(
                    locale: 'ja_JP',
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: core.focusedDay, // Core の状態を使用
                    calendarFormat: core.calendarFormat, // Core の状態を使用
                    selectedDayPredicate: (day) => isSameDay(core.selectedDay, day),

                    onDaySelected: core.selectDay, // Core のイベントハンドラを直接渡す

                    eventLoader: core.getRecordsForDay, // Core のロジックを直接渡す
                    
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        if (events.isNotEmpty) {
                          final recordList = events.cast<Record>();
                          final avgScore =
                              recordList.map((e) => e.moodScore).reduce((a, b) => a + b) /
                              recordList.length;
                          // Core のロジックを呼び出す
                          final markerColor = core.getScoreColor(avgScore.round()); 

                          return Positioned(
                            right: 1, bottom: 1,
                            child: Container(
                              width: 8.0, height: 8.0,
                              decoration: BoxDecoration(
                                color: markerColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                    ),

                    onFormatChanged: core.setCalendarFormat, // Core のイベントハンドラを直接渡す
                    onPageChanged: core.setFocusedDay, // Core のイベントハンドラを直接渡す
                  ),

                  const SizedBox(height: 8.0),

                  // 2. タイムライン表示エリア
                  Expanded(
                    child: selectedDayRecords.isEmpty
                        ? Center(
                            child: Text(
                              core.selectedDay != null && isSameDay(core.selectedDay!, DateTime.now())
                                  ? '今日の記録はありません'
                                  : (core.selectedDay != null
                                      ? '${core.selectedDay!.month}/${core.selectedDay!.day} の記録はありません'
                                      : '日付を選択してください'),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: selectedDayRecords.length,
                            itemBuilder: (context, index) {
                              final record = selectedDayRecords[index];

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: core.getScoreColor(record.moodScore), // Core のロジック
                                  child: Text(
                                    record.moodScore.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(record.eventText),
                                subtitle: Text(
                                  'タグ: ${record.moodTags.join(', ')} | ${record.weather} | ${record.location.split(',').first}',
                                ),
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => HistoryDetailScreen(record: record),
                                    ),
                                  );
                                  if (!context.mounted) return;
                                  // 詳細画面から戻ったら Core にデータ再取得を指示
                                  // context.read は、Consumer の外でも Core のメソッドを呼び出す安全な方法
                                  context.read<HistoryCore>().fetchRecords(); 
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        }, 
      ),
    );
  }
}
