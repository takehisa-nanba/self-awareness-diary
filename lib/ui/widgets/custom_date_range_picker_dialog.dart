// lib/ui/widgets/custom_date_range_picker_dialog.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../domain/models/diary_record.dart';

/// ユーザーが日付範囲を選択するためのカスタムダイアログウィジェット。
///
/// `table_calendar` パッケージを使用して、カレンダー形式で日付選択機能を提供します。
class CustomDateRangePickerDialog extends StatefulWidget {
  /// ダイアログ表示時に初期選択される日付範囲。
  final DateTimeRange initialDateRange;

  /// カレンダーにイベントとして表示する日記レコードのリスト。
  final List<DiaryRecord> events;

  const CustomDateRangePickerDialog({
    super.key,
    required this.initialDateRange,
    required this.events,
  });

  @override
  State<CustomDateRangePickerDialog> createState() =>
      _CustomDateRangePickerDialogState();
}

/// [CustomDateRangePickerDialog] の状態を管理するクラス。
///
/// カレンダーの表示状態、選択された日付範囲、イベントの読み込みなどを制御します。
class _CustomDateRangePickerDialogState
    extends State<CustomDateRangePickerDialog> {
  late DateTime _focusedDay;
  late DateTime? _rangeStart;
  late DateTime? _rangeEnd;
  final RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;

  @override
  void initState() {
    super.initState();
    // 初期日付範囲をローカルタイムに変換して設定
    _focusedDay = widget.initialDateRange.start.toLocal();
    _rangeStart = widget.initialDateRange.start.toLocal();
    _rangeEnd = widget.initialDateRange.end.toLocal();
  }

  /// 特定の日に対応するイベント（日記レコード）のリストを返します。
  ///
  /// [day] イベントを取得する対象の日。
  List<DiaryRecord> _getEventsForDay(DateTime day) {
    // isSameDayはUTC/Localを考慮しないため、ここで日付を比較
    return widget.events.where((event) {
      final localEventDate = event.recordDate.toLocal();
      return localEventDate.year == day.year &&
          localEventDate.month == day.month &&
          localEventDate.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('期間を選択'),
      content: SizedBox(
        width: double.maxFinite,
        child: TableCalendar<DiaryRecord>(
          locale: 'ja_JP',
          firstDay: DateTime(2020, 1, 1),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          rangeStartDay: _rangeStart,
          rangeEndDay: _rangeEnd,
          rangeSelectionMode: _rangeSelectionMode,
          eventLoader: _getEventsForDay,
          calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(
              color: Theme.of(
                context,
              ).primaryColor.withAlpha((255 * 0.7).toInt()),
              shape: BoxShape.circle,
            ),
          ),
          onDaySelected: (selectedDay, focusedDay) {
            // selectedDayもローカルタイムに変換
            final localSelectedDay = selectedDay.toLocal();
            if (!isSameDay(_rangeStart, localSelectedDay)) {
              setState(() {
                _focusedDay = focusedDay.toLocal();
                if (_rangeStart == null || _rangeEnd != null) {
                  _rangeStart = localSelectedDay;
                  _rangeEnd = null;
                }
              });
            }
          },
          onRangeSelected: (start, end, focusedDay) {
            setState(() {
              _focusedDay = focusedDay.toLocal();
              _rangeStart = start?.toLocal();
              _rangeEnd = end?.toLocal();
            });
            // 1日だけ選択された場合
            if (end == null || isSameDay(start, end)) {
              _rangeEnd = _rangeStart;
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () {
            if (_rangeStart != null) {
              // 開始日をその日の00:00:00に正規化
              final normalizedStart = DateTime(
                _rangeStart!.year,
                _rangeStart!.month,
                _rangeStart!.day,
              );
              // 終了日をその日の23:59:59.999に正規化
              final normalizedEnd = DateTime(
                (_rangeEnd ?? _rangeStart!).year,
                (_rangeEnd ?? _rangeStart!).month,
                (_rangeEnd ?? _rangeStart!).day,
                23,
                59,
                59,
                999,
              );

              Navigator.of(
                context,
              ).pop(DateTimeRange(start: normalizedStart, end: normalizedEnd));
            }
          },
          child: const Text('決定'),
        ),
      ],
    );
  }
}
