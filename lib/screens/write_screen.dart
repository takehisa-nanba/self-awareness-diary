// lib/screens/write_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/write_core.dart';
import '../widgets/location_status_bar.dart';
import '../widgets/app_shell.dart';
import 'write_steps/step1_write.dart'; 
import 'write_steps/step2_write.dart'; 
import 'write_steps/step3_write.dart'; 

class WriteScreen extends StatelessWidget {
  const WriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    return ChangeNotifierProvider<WriteCore>(
      create: (context) => WriteCore(),
      child: Consumer<WriteCore>(
        builder: (context, core, child) {
          
          return AppShell(
            
            customHeader: _buildCustomStepHeader(context, core), 
            
            floatingActionButton: _buildFab(context, core),
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
                      onTap: core.retryLocationAndWeather, // ★ 追加: タップ時の再取得ロジックを渡す
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

  PreferredSizeWidget _buildCustomStepHeader(BuildContext context, WriteCore core) {
    // 戻るボタン
    Widget backButton = core.currentStepIndex > 1
        ? TextButton.icon(
            onPressed: core.previousStep,
            icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.black87),
            label: const Text('戻る', style: TextStyle(color: Colors.black87)),
          )
        // ★★★ 修正1: ステップ1の時は幅 0 のSizedBoxを返す（左寄せのため） ★★★
        : const SizedBox.shrink(); 

    // タイトルとステップ表示 (Columnで縦にまとめる)
    Widget titleAndStep = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center, // 垂直方向の中央揃え
      children: [
        Text(
          core.currentStepTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 18.0, 
            height: 1.0, 
          ),
        ),
        Text(
          'ステップ${core.currentStepIndex}/${WriteCore.stepTitles.length}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.black54,
            fontSize: 12.0,
            height: 1.0, 
          ),
        ),
      ],
    );

    return PreferredSize(
      preferredSize: const Size.fromHeight(60.0), 
      child: Container(
        color: Colors.transparent, 
        
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // 左右パディング
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // 垂直方向の中央揃え
            children: [
              // 1. 戻るボタン/SizedBox (左端)
              backButton,
              
              // 2. スペース - 戻るボタンがあるときのみスペースを空ける
              // ★★★ 修正2: if を追加し、ステップ2, 3 のみスペースを空ける ★★★
              if (core.currentStepIndex > 1)
                const SizedBox(width: 10.0),
              
              // 3. タイトルとステップ表示 (残りのスペースを占有)
              Expanded(
                child: Padding(
                   padding: const EdgeInsets.symmetric(vertical: 4.0), 
                   child: titleAndStep,
                ),
              ),
            ],
          ),
        ),
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
    
    // ★ 修正1: ステップ2の時だけ、AI解析を考慮した非同期処理にする
    onPressed = isValid 
        ? () async {
            if (core.currentStepIndex == 2) {
              // ステップ2から3へ行く時、ローディングを挟む
              await core.nextStep(); 
            } else {
              core.nextStep();
            }
          }
        : null;
  } else {
    icon = Icons.save;
    label = '保存';
    onPressed = isValid && core.isLocationAndWeatherReady()
        ? () => _handleSaveEntry(context, core)
        : null;
  }

  return FloatingActionButton.extended(
    onPressed: core.isLoadingAi ? null : onPressed, // ★ 修正2: ロード中は無効化
    // ★ 修正3: ロード中は「次へ」の代わりにぐるぐるを表示
    label: core.isLoadingAi 
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Text(label),
    icon: core.isLoadingAi ? null : Icon(icon),
    backgroundColor: onPressed != null ? Colors.orange.shade800 : Colors.grey,
    );
  }

  Future<void> _handleSaveEntry(BuildContext context, WriteCore core) async {
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
    
    return Column(
      children: [
        
        Expanded(
          child: Padding(
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
    switch (index) {
      case 1:
        return Step1WriteScreen(
          selectedTags: core.selectedMoodTags,
          onTagSelected: core.toggleMoodTag,
        );
      case 2:
        return Step2WriteScreen(
          moodScore: core.moodScore.toDouble(), 
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