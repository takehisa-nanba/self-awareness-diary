// lib/ui/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../domain/models/diary_record.dart';
import '../../providers/history_provider.dart';
import '../../core/utils/color_helpers.dart'; // getMoodColor 関数を使用
import 'record_detail_screen.dart';

/// 過去の日記記録をカレンダー形式とリスト形式で表示する画面ウィジェット。
///
/// `table_calendar` を利用してカレンダー機能を提供し、
/// 選択された日付の日記記録を一覧表示します。
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  /// 年月ピッカーダイアログを表示し、ユーザーが特定の日付へ素早く移動できるようにします。
  ///
  /// [context] ビルドコンテキスト。
  /// [focusedDay] 現在フォーカスされている日付。
  /// [provider] [HistoryProvider] のインスタンス。
  Future<void> _showYearMonthPicker(
    BuildContext context,
    DateTime focusedDay,
    HistoryProvider provider,
  ) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: focusedDay,
      firstDate: DateTime(2024), // 選択可能な最初の日付
      lastDate: DateTime(2030), // 選択可能な最後の日付
      initialDatePickerMode: DatePickerMode.year, // 最初は年選択モードで表示
    );

    if (pickedDate != null) {
      // 選択された日付に基づいてカレンダーを更新
      provider.onDaySelected(pickedDate, pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistoryProvider>();

    return Column(
      children: [
        /// 日記記録を表示するカレンダーウィジェット。
        TableCalendar(
          locale: Localizations.localeOf(context).toString(), // 現在のロケールを使用
          firstDay: DateTime.utc(2024, 1, 1), // カレンダーの最初の表示可能日
          lastDay: DateTime.utc(2030, 12, 31), // カレンダーの最後の表示可能日
          focusedDay: provider.focusedDay, // 現在フォーカスされている日
          selectedDayPredicate: (day) =>
              isSameDay(provider.selectedDay, day), // 日が選択されているかどうかの判定
          onDaySelected: provider.onDaySelected, // 日が選択されたときのコールバック
          eventLoader: (day) => provider.getEventsForDay(day).isNotEmpty
              ? [true]
              : [], // イベントのローダー
          calendarFormat: provider.calendarFormat, // カレンダーの表示形式（月/週）
          onFormatChanged: (format) =>
              provider.setCalendarFormat(format), // 表示形式が変更されたときのコールバック
          onHeaderTapped: (date) => _showYearMonthPicker(
            context,
            date,
            provider,
          ), // ヘッダーがタップされたときのコールバック（年月ピッカー表示）
          daysOfWeekHeight: 30.0, // 曜日の表示高さ
          calendarStyle: CalendarStyle(
            /// 今日の日付のデコレーション。
            todayDecoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withAlpha((255 * 0.5).round()),
              shape: BoxShape.circle,
            ),

            /// 選択された日付のデコレーション。
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),

            /// 選択された日付のテキストスタイル。
            selectedTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 16.0,
            ),

            /// イベントがある日のマーカーデコレーション。
            markerDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),

          /// 利用可能なカレンダー表示形式。
          availableCalendarFormats: const {
            CalendarFormat.month: '月',
            CalendarFormat.week: '週',
          },

          /// カレンダーヘッダーのスタイル設定。
          headerStyle: const HeaderStyle(
            formatButtonVisible: true, // 形式変更ボタンの表示
            titleCentered: true, // タイトルの中央寄せ
          ),
        ),
        const Divider(),

        /// 選択された日の日記記録をリスト表示。
        Expanded(
          child: provider.selectedDayRecords.isEmpty
              ? const Center(child: Text('この日の記録はありません。')) // 記録がない場合のメッセージ
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: provider.selectedDayRecords.length,
                  itemBuilder: (context, index) {
                    final record = provider.selectedDayRecords[index];
                    final bool isSelfAnalysisEmpty =
                        record.selfAnalysis?.isEmpty ?? true;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 6.0,
                        horizontal: 8.0,
                      ),
                      elevation: isSelfAnalysisEmpty ? 1 : 2,
                      color: isSelfAnalysisEmpty
                          ? Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isSelfAnalysisEmpty
                            ? BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                                width: 1,
                              )
                            : BorderSide.none,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),

                        /// カードをタップすると詳細画面へ遷移。
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RecordDetailScreen(record: record),
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
                                  /// 気分スコアの円形アバター。
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: getMoodColor(
                                      record.moodScore,
                                    ),
                                    child: Text(
                                      '${record.moodScore}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        /// 出来事のテキスト。
                                        Text(
                                          record.eventText,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),

                                        /// 時刻と天気情報。
                                        Text(
                                          "${record.timeString} / ${record.weather ?? '天気情報なし'}",
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),

                                  /// 詳細画面への誘導アイコン。
                                  Icon(
                                    Icons.chevron_right,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4.0,
                                  top: 4.0,
                                ),
                                child: Row(
                                  children: [
                                    /// 自己分析の研磨度アイコン。
                                    Text(
                                      record.polishingIcon,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      /// 自己分析の研磨度メッセージまたはパーセンテージ。
                                      child: isSelfAnalysisEmpty
                                          ? Text(
                                              record.polishingMessage,
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                            )
                                          : Text(
                                              '研磨度: ${record.polishingLevel}%',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),

                              /// 記録された気分タグがあれば表示。
                              if (record.moodTags.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6.0,
                                  runSpacing: 4.0,
                                  children: record.moodTags
                                      .map(
                                        (tag) => Chip(
                                          label: Text(tag),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4.0,
                                          ),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          labelStyle: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                      .toList(),
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
