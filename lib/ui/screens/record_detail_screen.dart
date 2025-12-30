// lib/ui/screens/record_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:myapp/providers/app_state_provider.dart';
import 'package:myapp/providers/location_provider.dart';
import 'package:myapp/providers/write_provider.dart';
import 'package:myapp/ui/widgets/app_shell.dart';
import 'package:provider/provider.dart';
import '../../domain/models/diary_record.dart';
import '../../providers/detail_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/gemini_service.dart';
import '../../services/isar_service.dart'; // isarService にアクセスするためにインポート

/// 個々の日記レコードの詳細を表示する画面ウィジェット。
///
/// [DiaryRecord] オブジェクトを受け取り、その詳細情報、自己分析、
/// AI分析結果などを表示します。
class RecordDetailScreen extends StatelessWidget {
  /// 表示する日記レコード。
  final DiaryRecord record;
  const RecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    /// [DetailProvider] を作成し、[RecordDetailScreen] のウィジェットツリーで利用可能にします。
    return ChangeNotifierProvider(
      create: (context) => DetailProvider(
        record,
        context.read<GeminiService>(),
        context.read<SettingsProvider>(),
      ),
      // AppShellで画面全体をラップし、統一されたヘッダーとナビゲーションを提供する
      child: AppShell(
        title: "記録の詳細", // 画面タイトル
        // 記録を編集するためのFloatingActionButton
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // WriteProviderを編集モードで初期化し、現在のレコードデータをセットする
            final writeProvider = context.read<WriteProvider>();
            writeProvider.initForEdit(record);
            // アプリのメインタブを「記録」画面に切り替える
            final appStateProvider = context.read<AppStateProvider>();
            appStateProvider.setTab(AppTab.write);
            // 現在の詳細画面をナビゲーションスタックから削除し、背後にあるRootScreen（のWriteScreen）を表示する
            Navigator.of(context).pop();
          },
          label: const Text('この記録を研磨する'), // ボタンのテキスト
          icon: const Icon(Icons.edit), // ボタンのアイコン
        ),
        // 画面の主要な内容
        child: const _DetailBody(),
      ),
    );
  }
}

/// 日記レコードの詳細コンテンツを構築するウィジェット。
///
/// 環境情報、出来事、気分タグ、自己分析、AI分析結果などを表示します。
class _DetailBody extends StatelessWidget {
  const _DetailBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DetailProvider>();
    final record = provider.record;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 環境情報（場所、天気、日時）を表示し、未登録の場合は場所登録ボタンを表示するセクション
          _buildEnvironmentInfo(context, provider),
          const SizedBox(height: 16),
          // 「起きたこと」セクションのタイトル
          const _SectionTitle("起きたこと"),
          const SizedBox(height: 8),
          // 記録された出来事のテキスト
          Text(record.eventText, style: const TextStyle(fontSize: 18)),
          // 記録された気分タグがあれば表示
          if (record.moodTags.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildMoodTags(record),
          ],
          const SizedBox(height: 32),
          // 自己分析セクション
          _buildSelfAnalysisSection(context, record),
          const SizedBox(height: 32),
          // 「AI分析結果」セクションのタイトル
          const _SectionTitle("AI分析結果"),
          const SizedBox(height: 12),
          // AI分析結果またはアップグレードのプレースホルダーを表示
          _buildAIAnalysisSection(context, provider),
        ],
      ),
    );
  }

  /// 環境情報（場所、天気、日時）を表示し、未登録の場合は場所登録ボタンを表示するウィジェット。
  Widget _buildEnvironmentInfo(
      BuildContext context, DetailProvider provider) {
    return FutureBuilder<bool>(
      future: provider.isLocationUnregistered(),
      builder: (context, snapshot) {
        final isUnregistered = snapshot.data ?? false;
        return Row(
          children: [
            Expanded(
              // 環境情報のテキスト表示
              child: Text(
                provider.environmentInfo,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            // 場所が未登録の場合に「場所を登録」ボタンを表示
            if (snapshot.connectionState == ConnectionState.done &&
                isUnregistered)
              TextButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => _LocationDialog(provider: provider),
                ),
                icon: const Icon(Icons.add_location_alt, size: 16),
                label: const Text("場所を登録", style: TextStyle(fontSize: 12)),
              )
            // 位置情報確認中はローディングインジケータを表示
            else if (snapshot.connectionState == ConnectionState.waiting)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        );
      },
    );
  }

  /// 記録された気分タグをChipとして表示するウィジェット。
  Widget _buildMoodTags(DiaryRecord record) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: record.moodTags
          .map((tag) => Chip(
                label: Text(tag),
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelStyle: const TextStyle(fontSize: 12),
              ))
          .toList(),
    );
  }

  /// 自己分析セクションを構築するウィジェット。
  ///
  /// 研磨度に応じたアイコンとパーセンテージ、自己分析テキストを表示します。
  Widget _buildSelfAnalysisSection(BuildContext context, DiaryRecord record) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // セクションタイトル
            const _SectionTitle("振り返り（セルフアナリシス）"),
            Row(
              children: [
                // 自己分析の研磨度に応じたアイコン
                Text(record.polishingIcon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
                // 研磨度が表示可能であればパーセンテージを表示
                if (record.polishingLevel > 0)
                  Text(
                    '研磨度: ${record.polishingLevel}%',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 自己分析の内容表示コンテナ
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Text(
            record.selfAnalysis?.isEmpty ?? true
                ? "この記録はまだ研磨されていません。"
                : record.selfAnalysis!,
            style: TextStyle(
              fontSize: 16,
              color: record.selfAnalysis?.isEmpty ?? true
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  /// AI分析結果またはアップグレードのプレースホルダーを表示するウィジェット。
  Widget _buildAIAnalysisSection(
      BuildContext context, DetailProvider provider) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        // サブスクリプションティアに応じてAI分析カードまたはアップグレードのプレースホルダーを表示
        if (settings.currentTier == SubscriptionTier.tier2) {
          return _AIAnalysisCard(provider: provider);
        } else {
          return const _UpgradePlaceholder();
        }
      },
    );
  }
}

/// 場所登録ダイアログウィジェット。
///
/// ユーザーが場所のラベルを入力し、過去の記録も更新するかを選択できるダイアログです。
class _LocationDialog extends StatefulWidget {
  final DetailProvider provider;
  const _LocationDialog({required this.provider});

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

/// `_LocationDialog` の状態を管理するクラス。
class _LocationDialogState extends State<_LocationDialog> {
  final _controller = TextEditingController(); // 場所ラベル入力用のコントローラー
  bool _updatePast = false; // 過去の記録を更新するかのチェックボックスの状態

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("この場所を登録"), // ダイアログのタイトル
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 場所ラベル入力フィールド
          TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: "場所の名前（例：自宅、職場）"),
            autofocus: true,
          ),
          const SizedBox(height: 10),
          // 過去の記録更新チェックボックス
          CheckboxListTile(
            title: const Text("過去の同じ場所の記録も書き換える", style: TextStyle(fontSize: 12)),
            value: _updatePast,
            onChanged: (val) => setState(() => _updatePast = val!),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // キャンセルボタン
          child: const Text("キャンセル"),
        ),
        ElevatedButton(
          onPressed: _onRegisterPressed, // 登録ボタン
          child: const Text("登録"),
        ),
      ],
    );
  }

  /// 場所登録ボタンが押された際の処理。
  ///
  /// ラベルが空でないことを確認後、場所を登録し、過去の類似記録の更新を促すダイアログを表示する。
  /// 最終的に、結果をスナックバーでユーザーに通知する。
  void _onRegisterPressed() async {
    final label = _controller.text;
    if (label.isEmpty) return; // ラベルが空の場合は何もしない

    final locationProvider = context.read<LocationProvider>();
    final historyProvider = context.read<HistoryProvider>();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final lat = widget.provider.record.latitude; // 現在の記録の緯度
    final lng = widget.provider.record.longitude; // 現在の記録の経度
    bool doUpdatePast = _updatePast; // 過去の記録を更新するかのフラグ

    // 過去の記録を更新するオプションが選択されており、緯度経度情報がある場合
    if (doUpdatePast && lat != null && lng != null) {
      // 近くの記録を検索
      final nearbyRecords = await isarService.findNearbyRecords(lat, lng);
      if (!mounted) return;
      if (nearbyRecords.isNotEmpty) {
        // 更新確認ダイアログを表示
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (_) =>
              _ConfirmDialog(count: nearbyRecords.length, label: label),
        );
        if (confirmed == false) doUpdatePast = false; // ユーザーがキャンセルした場合
      }
    }

    // LocationProviderを介して新しい場所を登録し、過去の関連レコードを更新する
    await locationProvider.addNewLocationAndUpdateRecords(
          label: label,
          address: widget.provider.record.location!,
          lat: lat,
          lng: lng,
          updatePast: doUpdatePast,
        );
    // 現在のレコードの場所名を更新
    await widget.provider.updateLocationName(label);
    // 履歴をリフレッシュ
    historyProvider.refreshHistory();

    navigator.pop(); // ダイアログを閉じる
    scaffoldMessenger
        .showSnackBar(SnackBar(content: Text('「$label」を登録しました'))); // 登録完了メッセージ
  }
}

/// 過去記録の一括更新確認ダイアログウィジェット。
///
/// ユーザーに対して、同じ場所の過去の記録を新しいラベルで一括更新するかどうかを確認します。
class _ConfirmDialog extends StatelessWidget {
  final int count; // 近くで見つかった記録の件数
  final String label; // 更新する場所の新しいラベル
  const _ConfirmDialog({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("過去記録の一括更新"), // ダイアログのタイトル
      content: Text("同じ場所の記録が $count 件見つかりました。\nこれらもすべて「$label」に変更しますか？"), // 確認メッセージ
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false), // キャンセルボタン
          child: const Text("いいえ"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true), // 更新するボタン
          child: const Text("はい、更新します"),
        ),
      ],
    );
  }
}

/// AI分析のアップグレードを促すプレースホルダーウィジェット。
///
/// AI分析機能が利用できない無料ユーザー向けに、アップグレードを推奨するUIを表示します。
class _UpgradePlaceholder extends StatelessWidget {
  const _UpgradePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context)
          .colorScheme
          .tertiaryContainer
          .withAlpha((255 * 0.5).toInt()),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // ロックアイコン
            Icon(
              Icons.lock_outline,
              size: 32,
              color: Theme.of(context).colorScheme.onTertiaryContainer,
            ),
            const SizedBox(height: 16),
            // タイトル
            Text(
              'AIによる高度な分析',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            // 説明文
            Text(
              'アップグレードすると、AIがあなたの記録を分析し、パーソナライズされた洞察を提供します。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
            ),
            const SizedBox(height: 24),
            // プラン確認ボタン
            FilledButton.tonal(
                onPressed: () {}, child: const Text('プランを確認する')),
          ],
        ),
      ),
    );
  }
}

/// 各セクションのタイトルを表示するための再利用可能なウィジェット。
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

/// AI分析結果カードウィジェット。
///
/// AIによる感情の安定度スコアと分析理由を表示します。
class _AIAnalysisCard extends StatelessWidget {
  final DetailProvider provider;
  const _AIAnalysisCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final record = provider.record; // 表示する日記レコード
    final color = provider.scoreColor; // スコアに応じた色

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).round()), // 背景色
        borderRadius: BorderRadius.circular(16), // 角丸
        border: Border.all(color: color.withAlpha((255 * 0.3).round())), // ボーダー
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("感情の安定度", style: TextStyle(fontWeight: FontWeight.bold)),
              // AIによる感情の安定度スコア
              Text(
                provider.hasAnalysis ? "${record.aiStabilityScore}%" : "--%",
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // AIによる分析理由
          Text(
            record.aiAnalysisReason ?? "分析データはありません",
            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
