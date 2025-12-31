// lib/ui/screens/record_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:myapp/providers/analysis_provider.dart';
import 'package:myapp/providers/app_state_provider.dart';
import 'package:myapp/providers/location_provider.dart';
import 'package:myapp/providers/write_provider.dart';
import 'package:myapp/services/ad_service.dart';
import 'package:myapp/ui/widgets/app_shell.dart';
import 'package:provider/provider.dart';
import '../../domain/models/diary_record.dart';
import '../../providers/detail_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/gemini_service.dart';
import '../../services/isar_service.dart';

/// 個々の日記レコードの詳細を表示する画面ウィジェット。
///
/// [DiaryRecord] オブジェクトを受け取り、その詳細情報、自己分析、
/// AI分析結果などを表示します。
/// この画面では、[DetailProvider] を初期化し、UI全体の状態管理を行います。
/// また、画面全体の骨格として [AppShell] を使用します。
class RecordDetailScreen extends StatelessWidget {
  /// 表示する日記レコード。前の画面（例：履歴画面）から渡されます。
  final DiaryRecord record;

  /// コンストラクタ。必須パラメータとして [record] を受け取ります。
  const RecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    /// [ChangeNotifierProvider] を使用して、この画面のウィジェットツリー内でのみ有効な
    /// [DetailProvider] のインスタンスを生成します。
    /// これにより、画面が破棄される際にプロバイダーも自動的に破棄され、メモリリークを防ぎます。
    return ChangeNotifierProvider(
      create: (context) => DetailProvider(
        record,
        context.read<GeminiService>(), // 上位のProviderからGeminiServiceを読み込む
        context.read<SettingsProvider>(), // 上位のProviderからSettingsProviderを読み込む
      ),
      // AppShellで画面全体をラップし、統一されたヘッダーとナビゲーションを提供する
      child: AppShell(
        title: "記録の詳細", // AppBarに表示される画面タイトル
        // 記録を編集（研磨）するためのフローティングアクションボタン
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // WriteProviderを編集モードで初期化し、現在のレコードデータをセットする
            context.read<WriteProvider>().initForEdit(record);
            // アプリのメインタブを「記録」画面に切り替える
            context.read<AppStateProvider>().setTab(AppTab.write);
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

/// 日記レコードの詳細コンテンツを構築し、表示するメインウィジェット。
///
/// 環境情報、出来事、気分タグ、自己分析、AI分析結果など、
/// 記録の各要素をセクションごとに分けて表示します。
/// また、手動でのAI分析実行やそのためのボタン生成など、
/// この画面固有のビジネスロジックも内包します。
class _DetailBody extends StatelessWidget {
  const _DetailBody();

  @override
  Widget build(BuildContext context) {
    // DetailProviderを監視し、レコードのデータ変更時にUIを再描画する
    final provider = context.watch<DetailProvider>();
    final record = provider.record;

    // スクロール可能な画面を構築
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      // 各セクションを垂直に並べる
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 戻るボタン
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, size: 20),
              label: const Text('戻る', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
          // 環境情報セクションを構築するヘルパーメソッド
          _buildEnvironmentInfo(context, provider),
          const SizedBox(height: 16),
          // 出来事セクション
          const _SectionTitle("起きたこと"),
          const SizedBox(height: 8),
          Text(record.eventText, style: const TextStyle(fontSize: 18)),
          // 気分タグセクション
          if (record.moodTags.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildMoodTags(record),
          ],
          const SizedBox(height: 32),
          // 自己分析セクション
          _buildSelfAnalysisSection(context, record),
          const SizedBox(height: 32),
          // AI分析結果セクション
          const _SectionTitle("AI分析結果"),
          const SizedBox(height: 12),
          _buildAIAnalysisSection(context, provider),
        ],
      ),
    );
  }

  /// 手動でのAI分析を実行する共通ロジック。
  ///
  /// [SettingsProvider] で利用回数を確認し、実行可能であれば分析フローを開始します。
  /// 無料ユーザーの場合は、[AdService] を介してリワード広告を表示し、
  /// 視聴完了後に [AnalysisProvider] の `performManualAnalysis` を呼び出します。
  /// 有料ユーザーの場合は直接分析を実行します。
  /// 分析中はローディングダイアログを表示し、完了またはエラー時にスナックバーで結果を通知します。
  void _performManualAnalysis(BuildContext context) async {
    final settingsProvider = context.read<SettingsProvider>();
    final analysisProvider = context.read<AnalysisProvider>();
    final detailProvider = context.read<DetailProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (settingsProvider.canPerformManualAnalysis()) {
      final adService = AdService();
      final record = detailProvider.record;

      // 分析を実行するコアロジック
      Future<void> runAnalysis() async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(child: CircularProgressIndicator());
          },
        );

        try {
          final updatedRecord = await analysisProvider.performManualAnalysis(
            record,
          );
          detailProvider.updateRecord(updatedRecord);
          navigator.pop(); // ローディングダイアログを閉じる
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('AI分析が完了しました。')),
          );
        } catch (e) {
          navigator.pop(); // ローディングダイアログを閉じる
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('分析中にエラーが発生しました: $e')),
          );
        }
      }

      if (settingsProvider.currentTier == SubscriptionTier.free) {
        adService.showRewardedAd(runAnalysis);
      } else {
        await runAnalysis();
      }
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('AI分析の利用上限に達しました。')),
      );
    }
  }

  /// ユーザーのティアや状態に応じて適切な分析実行ボタンを構築する。
  ///
  /// [SettingsProvider] と [DetailProvider] の状態を監視し、
  /// 適切なボタンのテキスト、アイコン、アクションを決定します。
  Widget _buildAnalysisButton(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final detail = context.watch<DetailProvider>();

    String buttonText;
    IconData buttonIcon;

    switch (settings.currentTier) {
      case SubscriptionTier.tier2:
        buttonText = 'AI再分析を実行';
        buttonIcon = Icons.psychology_alt;
        break;
      case SubscriptionTier.tier1:
        buttonText = detail.hasAnalysis ? 'AI再分析' : 'AI分析を実行';
        buttonIcon = Icons.psychology;
        break;
      case SubscriptionTier.free:
        buttonText = detail.hasAnalysis ? '広告を見て再分析' : '広告を見てAI分析';
        buttonIcon = Icons.workspace_premium;
        break;
    }

    return ElevatedButton.icon(
      onPressed: () => _performManualAnalysis(context),
      icon: Icon(buttonIcon, size: 16),
      label: Text(buttonText),
    );
  }

  /// 環境情報（場所、天気、日時）セクションを構築する。
  ///
  /// [FutureBuilder] を使用して、場所が未登録かどうかの非同期チェックを行い、
  /// 結果に応じて「場所を登録」ボタンを表示します。
  Widget _buildEnvironmentInfo(BuildContext context, DetailProvider provider) {
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

  /// 記録された気分タグを [Chip] として表示するウィジェットを構築する。
  Widget _buildMoodTags(DiaryRecord record) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: record.moodTags
          .map(
            (tag) => Chip(
              label: Text(tag),
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              labelStyle: const TextStyle(fontSize: 12),
            ),
          )
          .toList(),
    );
  }

  /// 自己分析セクションを構築する。
  ///
  /// 自己分析が未記入の場合は、編集を促す視覚的なガイドを提供します。
  /// タップすることで編集画面（記録画面）に遷移します。
  Widget _buildSelfAnalysisSection(BuildContext context, DiaryRecord record) {
    bool isEmpty = record.selfAnalysis?.isEmpty ?? true;
    return InkWell(
      // タップで編集画面に遷移
      onTap: () {
        context.read<WriteProvider>().initForEdit(record);
        context.read<AppStateProvider>().setTab(AppTab.write);
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(12), // InkWellの波紋効果の範囲をコンテナに合わせる
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _SectionTitle("振り返り（セルフアナリシス）"),
              Row(
                children: [
                  Text(
                    record.polishingIcon,
                    style: TextStyle(fontSize: isEmpty ? 24 : 18),
                  ),
                  const SizedBox(width: 4),
                  if (record.polishingLevel > 0)
                    Text(
                      '研磨度: ${record.polishingLevel}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
              color: isEmpty
                  ? Theme.of(
                      context,
                    ).colorScheme.surfaceContainerLowest.withAlpha(150)
                  : Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              isEmpty ? record.polishingMessage : record.selfAnalysis!,
              style: TextStyle(
                fontSize: 16,
                color: isEmpty
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// AI分析結果セクションを構築する。
  ///
  /// 自己分析テキストが存在する場合にのみ、分析結果を表示する `_AIAnalysisCard` を表示します。
  /// それ以外の場合は、自己分析の入力を促すメッセージを表示します。
  Widget _buildAIAnalysisSection(
    BuildContext context,
    DetailProvider provider,
  ) {
    if (provider.record.selfAnalysis?.isNotEmpty ?? false) {
      return _AIAnalysisCard(
        provider: provider,
        settings: context.watch<SettingsProvider>(), // settingsを渡す
      );
    } else {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text('「振り返り」を記入すると、AI分析が利用できます。'),
          ),
        ),
      );
    }
  }
}

/// 場所登録ダイアログウィジェット。
///
/// ユーザーが場所のラベルを入力し、過去の記録も更新するかを選択できるダイアログです。
class _LocationDialog extends StatefulWidget {
  /// このダイアログが操作する日記レコードの詳細プロバイダー。
  final DetailProvider provider;

  /// コンストラクタ。必須パラメータとして [provider] を受け取ります。
  const _LocationDialog({required this.provider});

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

/// `_LocationDialog` の状態を管理するクラス。
class _LocationDialogState extends State<_LocationDialog> {
  final _controller = TextEditingController(); // 場所ラベル入力用
  bool _updatePast = false; // 過去の記録を更新するかのフラグ

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("この場所を登録"),
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
            title: const Text(
              "過去の同じ場所の記録も書き換える",
              style: TextStyle(fontSize: 12),
            ),
            value: _updatePast,
            onChanged: (val) => setState(() => _updatePast = val!),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("キャンセル"),
        ),
        ElevatedButton(onPressed: _onRegisterPressed, child: const Text("登録")),
      ],
    );
  }

  /// 「登録」ボタンが押された際の処理。
  ///
  /// ラベルが空でないことを確認後、場所を登録します。
  /// `_updatePast` が true の場合、近くの未登録レコードも検索し、
  /// ユーザーの確認のうえで一括更新します。
  /// 登録後、詳細画面を更新し、スナックバーで結果を通知します。
  void _onRegisterPressed() async {
    final label = _controller.text;
    if (label.isEmpty) return;

    final locationProvider = context.read<LocationProvider>();
    final historyProvider = context.read<HistoryProvider>();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final lat = widget.provider.record.latitude;
    final lng = widget.provider.record.longitude;
    bool doUpdatePast = _updatePast;

    if (doUpdatePast && lat != null && lng != null) {
      final nearbyRecords = await isarService.findNearbyRecords(lat, lng);
      if (!mounted) return;
      if (nearbyRecords.isNotEmpty) {
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (_) =>
              _ConfirmDialog(count: nearbyRecords.length, label: label),
        );
        if (confirmed == false) doUpdatePast = false;
      }
    }

    await locationProvider.addNewLocationAndUpdateRecords(
      label: label,
      address: widget.provider.record.location!,
      lat: lat,
      lng: lng,
      updatePast: doUpdatePast,
    );
    await widget.provider.updateLocationName(label);
    historyProvider.refreshHistory();

    navigator.pop();
    scaffoldMessenger.showSnackBar(SnackBar(content: Text('「$label」を登録しました')));
  }
}

/// 過去記録の一括更新を確認するためのダイアログウィジェット。
///
/// ユーザーに対して、同じ場所の過去の記録を新しいラベルで一括更新するかどうかを確認します。
class _ConfirmDialog extends StatelessWidget {
  final int count;
  final String label;
  const _ConfirmDialog({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("過去記録の一括更新"),
      content: Text("同じ場所の記録が $count 件見つかりました。\nこれらもすべて「$label」に変更しますか？"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("いいえ"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("はい、更新します"),
        ),
      ],
    );
  }
}

/// 各セクションのタイトルを表示するためのシンプルなウィジェット。
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
/// AIによる感情の安定度スコア、ユーザーの自己評価とのギャップ、
/// および分析理由を表示します。
/// また、ユーザーのティアに応じた手動再分析ボタンも提供します。
class _AIAnalysisCard extends StatelessWidget {
  final DetailProvider provider;
  final SettingsProvider settings; // SettingsProviderを追加
  const _AIAnalysisCard({
    required this.provider,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final record = provider.record;
    final hasAnalysis = provider.hasAnalysis;
    final scoreColor = provider.scoreColor;
    // moodScoreは0-100の範囲なので10倍してaiStabilityScoreと比較
    final scoreGap = hasAnalysis
        ? (record.aiStabilityScore! - (record.moodScore * 10)).abs()
        : null;

    return Card(
      elevation: 0,
      color: scoreColor.withAlpha(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scoreColor.withAlpha(77)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "AIによる感情の安定度",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  hasAnalysis ? "${record.aiStabilityScore}%" : "--%",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("自己評価とのギャップ", style: TextStyle(fontSize: 12)),
                if (scoreGap != null)
                  Text(
                    "$scoreGap%",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              record.aiAnalysisReason ?? "AIによる分析はまだ行われていません。",
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: (context.findAncestorWidgetOfExactType<_DetailBody>()!)
                  ._buildAnalysisButton(context),
            ),
          ],
        ),
      ),
    );
  }
}