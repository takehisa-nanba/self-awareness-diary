// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/history_core.dart';
import '../models/record.dart';
import '../widgets/app_shell.dart';
import 'history_detail_screen.dart'; 
import 'package:table_calendar/table_calendar.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HistoryCore>(
      create: (context) => HistoryCore(),
      child: Consumer<HistoryCore>(
        builder: (context, core, child) {
          // 選択された日の記録リストをフィルタリング
          final List<Record> selectedDayRecords = core.allRecords.where((record) {
            if (core.selectedDay == null) return true;
            return isSameDay(record.recordDate, core.selectedDay!);
          }).toList();

          return AppShell(
            child: Scaffold(
              appBar: AppBar(
                title: const Text('履歴を見る'),
                elevation: 1,
              ),
              body: Column(
                children: [
                  // --- カレンダーエリア ---
                  Padding( 
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TableCalendar(
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'week',
                        CalendarFormat.week: '月表示へ',
                      },
                      calendarFormat: core.calendarFormat,
                      onFormatChanged: (format) {
                        core.toggleCalendarFormat();
                      },
                      daysOfWeekHeight: 20,
                      calendarStyle: const CalendarStyle(
                        cellMargin: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                        markerSize: 6.0,
                        todayDecoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Colors.indigo,
                          shape: BoxShape.circle,
                        ),
                      ),
                      locale: 'ja_JP',
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: core.focusedDay,
                      selectedDayPredicate: (day) => isSameDay(core.selectedDay, day),
                      eventLoader: core.getRecordsForDay, 
                      onDaySelected: core.selectDay,
                      onHeaderTapped: (focusedDay) {
                        core.selectSpecificDate(context);
                      },
                      onPageChanged: core.setFocusedDay,
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, day, events) {
                          if (events.isNotEmpty) {
                            final recordList = events.cast<Record>();
                            final avgScore =
                                recordList.map((e) => e.moodScore).reduce((a, b) => a + b) /
                                recordList.length;
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
                    ),
                  ),
                  const SizedBox(height: 8.0),

                  // --- 記録リストエリア ---
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
                              final time = '${record.recordDate.hour.toString().padLeft(2, '0')}:${record.recordDate.minute.toString().padLeft(2, '0')}';

                              // ★★★ 追加: 自己評価とAI評価のズレを計算 ★★★
                              final int userScorePercent = record.moodScore * 10;
                              final int aiScore = record.aiStabilityScore ?? 0;
                              final bool isGapLarge = record.aiStabilityScore != null && 
                                  (userScorePercent - aiScore).abs() >= 20;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: core.getScoreColor(record.moodScore),
                                  child: Text(
                                    record.moodScore.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      time,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        record.eventText,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'タグ: ${record.moodTags.join(', ')}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 12, color: Colors.grey.shade400),
                                        const SizedBox(width: 2),
                                        // ★ Null安全対策: weather と location に ?? を使用
                                        Text(
                                          '${record.location?.split(',').first ?? "不明"} | ${record.weather?.split('/').first ?? "不明"}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        const Spacer(),
                                        // ★ AI安定度バッジとズレ検知アイコン ★
                                        if (record.aiStabilityScore != null) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '安定度: ${record.aiStabilityScore}%',
                                              style: TextStyle(
                                                fontSize: 10, 
                                                color: Colors.blue.shade800, 
                                                fontWeight: FontWeight.bold
                                              ),
                                            ),
                                          ),
                                          if (isGapLarge)
                                            const Padding(
                                              padding: EdgeInsets.only(left: 4),
                                              child: Icon(
                                                Icons.psychology_alt, 
                                                size: 16, 
                                                color: Colors.orangeAccent
                                              ),
                                            ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => HistoryDetailScreen(record: record),
                                    ),
                                  );
                                  if (!context.mounted) return;
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