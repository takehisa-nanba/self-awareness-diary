import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/history_provider.dart';
import '../../core/utils/color_helpers.dart'; // color_helpers.dartをインポート
import 'record_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // 年月ピッカーを表示するメソッド
  Future<void> _showYearMonthPicker(BuildContext context, DateTime focusedDay, HistoryProvider provider) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: focusedDay,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year, // 初期表示を年選択にする
    );

    if (pickedDate != null) {
      provider.onDaySelected(pickedDate, pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistoryProvider>();

    return Column(
      children: [
        TableCalendar(
          locale: Localizations.localeOf(context).toString(),
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: provider.focusedDay,
          selectedDayPredicate: (day) => isSameDay(provider.selectedDay, day),
          onDaySelected: provider.onDaySelected,
          // ▼▼▼ 以下、まるっと変更 ▼▼▼
          eventLoader: (day) => provider.getEventsForDay(day).isNotEmpty ? [true] : [],
          calendarFormat: provider.calendarFormat,
          onFormatChanged: (format) => provider.setCalendarFormat(format),
          onHeaderTapped: (date) => _showYearMonthPicker(context, date, provider),
          daysOfWeekHeight: 30.0, // 曜日の高さを調整
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withAlpha((255 * 0.5).round()), shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
            selectedTextStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 16.0),
            // ドットマーカーの設定
            markerDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
          availableCalendarFormats: const {
            CalendarFormat.month: '月',
            CalendarFormat.week: '週',
          },
          headerStyle: const HeaderStyle( 
            formatButtonVisible: true, // フォーマットボタンを表示
            titleCentered: true,
          ),
          // ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
        ),
        const Divider(),
        Expanded(
          child: provider.selectedDayRecords.isEmpty
              ? const Center(child: Text('この日の記録はありません。'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: provider.selectedDayRecords.length,
                  itemBuilder: (context, index) {
                    final record = provider.selectedDayRecords[index];
                    final bool isSelfAnalysisEmpty = record.selfAnalysis?.isEmpty ?? true;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                      elevation: isSelfAnalysisEmpty ? 1 : 2,
                      color: isSelfAnalysisEmpty ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isSelfAnalysisEmpty 
                            ? BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1) 
                            : BorderSide.none,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecordDetailScreen(record: record),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: getMoodColor(record.moodScore), // グローバルな関数を使用
                                    child: Text(
                                      '${record.moodScore}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          record.eventText,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${record.timeString} / ${record.weather ?? '天気情報なし'}",
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ],
                              ),
                              if (record.moodTags.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6.0,
                                  runSpacing: 4.0,
                                  children: record.moodTags.map((tag) => Chip(
                                    label: Text(tag),
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    labelStyle: const TextStyle(fontSize: 12),
                                  )).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}