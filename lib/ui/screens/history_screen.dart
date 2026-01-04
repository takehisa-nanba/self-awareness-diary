// lib/ui/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../domain/models/diary_record.dart';
import '../../domain/models/location_setting.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/write_provider.dart';
import '../../core/utils/color_helpers.dart'; // getMoodColor 関数を使用
import '../../services/location_service.dart';
import 'record_detail_screen.dart';

/// 過去の日記記録をカレンダー形式とリスト形式で表示する画面ウィジェット。
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  /// 年月ピッカーダイアログを表示し、ユーザーが特定の日付へ素早く移動できるようにします。
  Future<void> _showYearMonthPicker(
    BuildContext context,
    DateTime focusedDay,
    HistoryProvider provider,
  ) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: focusedDay,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(), // 未来の日付は選択不可
      initialDatePickerMode: DatePickerMode.year,
    );
    if (pickedDate != null) {
      provider.onDaySelected(pickedDate, pickedDate);
    }
  }

  /// 「過去を記録」ボタンが押されたときの処理
  Future<void> _onRecordPastPressed(BuildContext context) async {
    // 1. 日付を選択
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (!context.mounted || pickedDate == null) return;

    // 2. 時間を選択
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (!context.mounted || pickedTime == null) return;

    final finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // 3. 場所を選択（既存リスト＋新規検索）
    final pickedLocation = await _showLocationPickerDialog(context);
    if (!context.mounted || pickedLocation == null) return;

    if (pickedLocation.latitude == null || pickedLocation.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('選択または検索された場所には有効な緯度経度がありません。')),
      );
      return;
    }

    // 4. WriteProviderを初期化して記録画面へ遷移
    context.read<WriteProvider>().initForHistorical(
      finalDateTime,
      pickedLocation.label,
      pickedLocation.latitude!,
      pickedLocation.longitude!,
    );
    context.read<AppStateProvider>().setTab(AppTab.write);
  }

  /// 場所を選択または検索するためのダイアログを表示する
  Future<LocationSetting?> _showLocationPickerDialog(
    BuildContext context,
  ) async {
    final locationProvider = context.read<LocationProvider>();

    return showDialog<LocationSetting>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('記録する場所を選択'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text('新しい場所を住所で検索'),
                  onPressed: () async {
                    // dialogContextがmountedかチェック
                    final searchResult = await _showSearchDialog(dialogContext);
                    if (!dialogContext.mounted) return; // add mounted check
                    // 検索結果があればダイアログを閉じて返す
                    if (searchResult != null) {
                      Navigator.of(dialogContext).pop(searchResult);
                    }
                  },
                ),
                const Divider(),
                if (locationProvider.locations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('登録済みの場所はありません。', textAlign: TextAlign.center),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: locationProvider.locations.length,
                      itemBuilder: (context, index) {
                        final location = locationProvider.locations[index];
                        return ListTile(
                          title: Text(location.label),
                          subtitle: Text(location.address),
                          onTap: () {
                            Navigator.of(dialogContext).pop(location);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  /// 住所を検索するためのダイアログを表示する
  Future<LocationSetting?> _showSearchDialog(BuildContext context) async {
    final searchController = TextEditingController();
    return showDialog<LocationSetting>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('住所で検索'),
          content: TextField(
            controller: searchController,
            decoration: const InputDecoration(hintText: '住所や場所名を入力...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                final address = searchController.text;
                if (address.isEmpty) return;

                final location = await locationService.getLatLngFromAddress(
                  address,
                );
                if (!dialogContext.mounted) return; // add mounted check
                if (location != null) {
                  // 新しいLocationSettingオブジェクトを作成して返す
                  Navigator.of(dialogContext).pop(
                    LocationSetting()
                      ..label =
                          address // ラベルは検索された住所文字列
                      ..address = address
                      ..latitude = location.latitude
                      ..longitude = location.longitude,
                  );
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('場所が見つかりませんでした。')),
                  );
                }
              },
              child: const Text('検索'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistoryProvider>();

    return SingleChildScrollView(
      // 日本語: 画面の高さが足りない場合にスクロール可能にするために追加
      child: Column(
        children: [
          // 「過去を記録」ボタン
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('過去の日記を記録する'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
              onPressed: () => _onRecordPastPressed(context),
            ),
          ),
          const Divider(),

          /// 日記記録を表示するカレンダーウィジェット。
          TableCalendar(
            locale: Localizations.localeOf(context).toString(),
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: provider.focusedDay,
            selectedDayPredicate: (day) => isSameDay(provider.selectedDay, day),
            onDaySelected: provider.onDaySelected,
            eventLoader: (day) =>
                provider.getEventsForDay(day).isNotEmpty ? [true] : [],
            calendarFormat: provider.calendarFormat,
            onFormatChanged: (format) => provider.setCalendarFormat(format),
            onHeaderTapped: (date) =>
                _showYearMonthPicker(context, date, provider),
            daysOfWeekHeight: 30.0,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withAlpha((255 * 0.5).round()),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 16.0,
              ),
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
              formatButtonVisible: true,
              titleCentered: true,
            ),
          ),
          const Divider(),

          /// 選択された日の日記記録をリスト表示。
          provider.selectedDayRecords.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('この日の記録はありません。')),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
                                        Text(
                                          "${record.timeString} / ${record.weather ?? '天気情報なし'}",
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
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
                                    Text(
                                      record.polishingIcon,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
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
        ],
      ),
    );
  }
}
