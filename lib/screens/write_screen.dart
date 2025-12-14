// lib/screens/write_screen.dart (カスタムヘッダーの記述を削除した後の全文)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/write_core.dart';
import '../widgets/location_status_bar.dart';
import '../widgets/app_shell.dart'; 
import 'write_steps/step1_write.dart' show Step1WriteScreen; 
import 'write_steps/step2_write.dart' show Step2WriteScreen; 
import 'write_steps/step3_write.dart' show Step3WriteScreen; 

class WriteScreen extends StatelessWidget {
  const WriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    return ChangeNotifierProvider<WriteCore>(
      create: (context) => WriteCore(),
      child: Consumer<WriteCore>(
        builder: (context, core, child) {
          
          return AppShell(
            // ★★★ 修正1: customHeader: _buildCustomStepHeader(...) の記述を削除 ★★★
            // WriteScreen は AppShell にカスタムヘッダーを渡さなくなる
            
            floatingActionButton: _buildFab(context, core),
            // FABの位置は endFloat を維持
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            
            child: Column( 
              children: [
                Expanded(
                  child: WriteContent(core: core),
                ),
                // LocationStatusBar の配置は左下を維持
                Align(
                  alignment: Alignment.bottomLeft, 
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                    child: LocationStatusBar(
                      location: core.locationName,
                      weather: core.weather,
                    ),
                  ),
                ),
              ],
            ),
          );

        },
      ),
    );
  }

  // ★★★ 修正2: _buildCustomStepHeader メソッドは、今後の再利用のために残しておく ★★★
  PreferredSizeWidget _buildCustomStepHeader(BuildContext context, WriteCore core) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(40.0), 
      child: AppBar(
        toolbarHeight: 40.0,
        titleSpacing: 0.0, 
        title: SizedBox(
          height: 40.0, 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              Text(
                core.currentStepTitle, 
                style: Theme.of(context).textTheme.bodyLarge?.copyWith( 
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                  height: 1.0, 
                ),
              ),
              Text(
                'ステップ${core.currentStepIndex}/${WriteCore.stepTitles.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith( 
                  color: Colors.white70,
                  fontSize: 10.0,
                  height: 1.0, 
                ),
              ),
            ],
          ),
        ),
        automaticallyImplyLeading: false, 
        backgroundColor: Theme.of(context).colorScheme.primary, 
        elevation: 0, 
      ),
    );
  }

  Widget _buildFab(BuildContext context, WriteCore core) {
    final bool isValid = core.isStepValid();

    IconData icon;
    String label;
    VoidCallback? onPressed;

    if (core.currentStepIndex < 3) {
      icon = Icons.arrow_forward;
      label = '次へ';
      onPressed = isValid ? core.nextStep : null;
    } else {
      icon = Icons.save;
      label = '保存';
      onPressed = isValid && core.isLocationAndWeatherReady()
          ? () => _handleSaveEntry(context, core)
          : null;
    }

    return FloatingActionButton.extended(
      onPressed: onPressed,
      label: Text(label),
      icon: Icon(icon),
      backgroundColor: onPressed != null ? Colors.orange.shade800 : Colors.grey,
    );
  }

  Future<void> _handleSaveEntry(BuildContext context, WriteCore core) async {
    // ... (中略) ...
    if (!core.isLocationAndWeatherReady()) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('待機'),
          content: const Text(
              '位置情報／天気情報の取得中です。\nしばらく待ってから再度保存してください。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    await core.saveRecordOnly();
    core.resetEntry();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('記録を保存しました！')),
      );
    }
  }
}

class WriteContent extends StatelessWidget {
  final WriteCore core;
  
  const WriteContent({super.key, required this.core});
  
  @override
  Widget build(BuildContext context) {
    // 戻るボタンのための余白は維持
    const backButtonHeight = 56.0;

    return Column(
      children: [
        // 戻るボタン
        if (core.currentStepIndex > 1)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: core.previousStep,
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              label: const Text('戻る'),
            ),
          )
        else
          const SizedBox(height: backButtonHeight), // ステップ1のときも高さを確保

        Expanded(
          child: Padding(
            // パディングは削減した値を維持 (8.0)
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: _buildCurrentStep(context, core.currentStepIndex),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(BuildContext context, int index) {
    // ... (ステップウィジェットのロジックは維持) ...
    switch (index) {
      case 1:
        return Step1WriteScreen(
          selectedTags: core.selectedMoodTags,
          onTagSelected: core.toggleMoodTag,
        );
      case 2:
        return Step2WriteScreen(
          moodScore: core.moodScore, 
          eventController: core.eventController,
          onScoreChanged: (int score) {
            core.setMoodScore(score.toDouble());
          },
          onContentChanged: core.notifyUiUpdate, 
        );
      case 3:
        return Step3WriteScreen(
          languageController: core.detailController, 
          onPremiumTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('【導線】有料プラン画面への遷移ロジックを実装する必要があります')),
            );
          }, 
          locationString: core.locationName,
          weatherString: core.weather,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}