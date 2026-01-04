// lib/ui/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/diagnosis_provider.dart'; // DiagnosisProviderをインポート
import '../../services/isar_service.dart'; // IsarServiceをインポート (findNearbyRecordsのため)
import 'developer_mode_screen.dart';
import 'location_edit_screen.dart';

/// アプリケーション全体の設定を管理する画面ウィジェット。
///
/// 一般設定、よく訪れる場所の登録と管理、開発者モードへのアクセス機能を提供します。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// `SettingsScreen` の状態を管理するクラス。
///
/// 入力フィールドのコントローラー、バージョンタップカウント、
/// および場所登録・編集に関するロジックを扱います。
class _SettingsScreenState extends State<SettingsScreen> {
  final _labelController = TextEditingController(); // 場所ラベル入力用のコントローラー
  final _addressController = TextEditingController(); // 住所入力用のコントローラー
  int _versionTapCount = 0; // 開発者モードを有効にするためのタップカウント

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>(); // 一般設定プロバイダー
    final locationProvider = context.watch<LocationProvider>(); // 場所設定プロバイダー
    final diagnosisProvider = context.watch<DiagnosisProvider>(); // DiagnosisProviderを追加

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- デバッグ用プラン設定セクション ---
          const Text(
            'デバッグ設定',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSubscriptionTierSelector(context, settingsProvider),
          const SizedBox(height: 32),

          // --- 一般設定セクション ---
          const Text(
            '一般設定',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildGeneralSettings(context, settingsProvider, diagnosisProvider), // diagnosisProviderを渡す

          const SizedBox(height: 32),

          // --- よく行く場所の登録セクション ---
          const Text(
            'よく行く場所の登録',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '登録した住所が自動的にラベル（自宅など）に変換されます。',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          _buildLocationForm(context, locationProvider), // 場所登録フォームUIの構築

          const SizedBox(height: 32),

          // --- 登録済み場所一覧セクション ---
          const Text(
            '登録済み一覧',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          _buildLocationList(context, locationProvider), // 登録場所リストUIの構築

          const SizedBox(height: 32),
          const Divider(),

          // --- バージョン情報セクション ---
          _buildVersionInfo(context), // バージョン情報UIの構築
          const SizedBox(height: 80), // FABとの重なりを避けるための余白
        ],
      ),
    );
  }

  /// 一般設定セクションのUIを構築するウィジェット。
  Widget _buildGeneralSettings(
    BuildContext context,
    SettingsProvider provider,
    DiagnosisProvider diagnosisProvider, // DiagnosisProviderを追加
  ) {
    return Column(
      children: [
        Card(
          elevation: 0,
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withAlpha((255 * 0.3).round()),
          child: SwitchListTile(
            title: const Text('「出来事」から書き始める'), // 設定項目タイトル
            subtitle: const Text(
              'オンにすると、日記を書き始める画面が「出来事の入力」からになります。',
            ), // 設定項目の説明
            value: provider.startFromStep2, // 現在の設定値
            onChanged: (value) {
              provider.setStartFromStep2(value);
            }, // 設定変更時の処理
            secondary: const Icon(Icons.edit_note), // 設定項目アイコン
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withAlpha((255 * 0.3).round()),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '性格診断ステータス:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.isDiagnosisComplete ? '完了済み' : '未完了',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: provider.isDiagnosisComplete
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (provider.isDiagnosisComplete) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await diagnosisProvider.resetUserProfile(); // DiagnosisProviderのresetUserProfileを呼び出す
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('性格診断ステータスをリセットしました。'),
                            ),
                          );
                        }
                      },

                      icon: const Icon(Icons.refresh),
                      label: const Text('性格診断をやり直す'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 場所登録フォームのUIを構築するウィジェット。
  Widget _buildLocationForm(BuildContext context, LocationProvider provider) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withAlpha((255 * 0.3).round()),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ラベル入力フィールド
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'ラベル',
                hintText: '例：自宅、職場',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // 住所入力フィールド
                Expanded(
                  child: TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: '住所',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 現在地を住所として自動入力するボタン
                IconButton.filledTonal(
                  onPressed: provider.isLoading
                      ? null // 位置情報取得中はボタンを無効化
                      : () async {
                          final addr = await provider
                              .getCurrentLocationAddress(); // 現在地住所を取得
                          if (addr != null) {
                            setState(
                              () => _addressController.text = addr,
                            ); // 取得した住所を入力フィールドに設定
                          }
                        },
                  icon: provider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ) // ローディングインジケータ
                      : const Icon(Icons.my_location), // 現在地アイコン
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 場所を登録するボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _onRegisterLocationPressed(context, provider), // ボタン押下時の処理
                icon: const Icon(Icons.add),
                label: const Text('登録する'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 登録済み場所一覧のUIを構築するウィジェット。
  Widget _buildLocationList(BuildContext context, LocationProvider provider) {
    if (provider.locations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            '登録された場所はありません',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ), // 登録場所がない場合のメッセージ
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.locations.length,
      itemBuilder: (context, index) {
        final loc = provider.locations[index];
        return ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.place, size: 20),
          ), // 場所アイコン
          title: Text(loc.label), // 場所のラベル
          subtitle: Text(
            loc.address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ), // 場所の住所
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LocationEditScreen(location: loc),
            ),
          ), // タップで編集画面へ遷移
        );
      },
    );
  }

  /// バージョン情報のUIを構築するウィジェット。
  ///
  /// バージョン表示部分を7回タップすると開発者モード画面へ遷移します。
  Widget _buildVersionInfo(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _versionTapCount++); // タップカウントをインクリメント
        if (_versionTapCount >= 7) {
          _versionTapCount = 0; // カウントをリセット
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const DeveloperModeScreen(),
            ),
          ); // 開発者モード画面へ遷移
        }
      },
      child: ListTile(
        title: Text('Version', style: Theme.of(context).textTheme.bodySmall),
        trailing: Text(
          '1.0.0-dev', // 必要に応じて実際のバージョンに置き換える
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  /// 場所登録ボタンが押されたときの処理。
  ///
  /// ラベルと住所のバリデーション、過去の記録更新の確認、場所の登録、
  /// およびUIのフィードバック（スナックバー）を行います。
  void _onRegisterLocationPressed(
    BuildContext context,
    LocationProvider provider,
  ) async {
    final label = _labelController.text;
    final address = _addressController.text;

    // 入力値のバリデーション
    if (label.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ラベルと住所の両方を入力してください。')));
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // 近くの記録があるか確認し、更新するかをユーザーに問い合わせる
    final lat = provider.lastLat;
    final lng = provider.lastLng;
    bool updatePast = false; // 過去の記録を更新するかのフラグ

    if (lat != null && lng != null) {
      final nearbyRecords = await isarService.findNearbyRecords(
        lat,
        lng,
      ); // 近くの記録を検索
      if (context.mounted && nearbyRecords.isNotEmpty) {
        final bool? confirmed = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('過去の日記の更新'),
            content: Text(
              '近くに${nearbyRecords.length}件の日記が見つかりました。場所を「$label」に更新しますか？',
            ),
            actions: [
              TextButton(
                onPressed: () => navigator.pop(false),
                child: const Text('いいえ'),
              ),
              ElevatedButton(
                onPressed: () => navigator.pop(true),
                child: const Text('はい、更新します'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          updatePast = true; // ユーザーが更新を承諾した場合
        }
      }
    }

    // 場所の登録と過去の記録の更新を実行
    await provider.addNewLocationAndUpdateRecords(
      label: label,
      address: address,
      lat: lat,
      lng: lng,
      updatePast: updatePast,
    );

    if (!context.mounted) return;
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(updatePast ? '場所を登録し、過去の記録も更新しました。' : '場所を登録しました。'),
      ),
    ); // 結果をスナックバーで通知

    _labelController.clear(); // 入力フィールドをクリア
    _addressController.clear();
  }

  /// デバッグ用にサブスクリプションティアを切り替えるウィジェット。
  Widget _buildSubscriptionTierSelector(
    BuildContext context,
    SettingsProvider provider,
  ) {
    return Card(
      elevation: 0,
      color: Colors.orange.withAlpha((255 * 0.3).round()),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '現在のプラン: ${provider.currentTier.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SegmentedButton<SubscriptionTier>(
              segments: const <ButtonSegment<SubscriptionTier>>[
                ButtonSegment(
                  value: SubscriptionTier.free,
                  label: Text('Free'),
                ),
                ButtonSegment(
                  value: SubscriptionTier.tier1,
                  label: Text('Tier1'),
                ),
                ButtonSegment(
                  value: SubscriptionTier.tier2,
                  label: Text('Tier2'),
                ),
              ],
              selected: {provider.currentTier},
              onSelectionChanged: (Set<SubscriptionTier> newSelection) {
                provider.setSubscriptionTier(newSelection.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}
