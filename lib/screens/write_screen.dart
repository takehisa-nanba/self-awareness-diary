// lib/screens/write_screen.dart

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
        : const SizedBox(width: 56.0); // 戻るボタンがないステップ1でも、タイトルと位置を揃えるため同等の幅を確保

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
      preferredSize: const Size.fromHeight(40.0), // 高さを60.0に調整
      child: Container(
        color: Colors.transparent, 
        
        // ★★★ 修正1: 戻るボタンとタイトルをRowで並べ、全体のパディングを設定 ★★★
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // 左右パディング
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // 垂直方向の中央揃え
            children: [
              // 1. 戻るボタン/SizedBox (左端)
              backButton,
              
              // 2. スペース
              const SizedBox(width: 10.0),
              
              // 3. タイトルとステップ表示 (残りのスペースを占有)
              Expanded(
                child: Padding(
                   padding: const EdgeInsets.symmetric(vertical: 8.0), // 上下のパディングで高さを調整
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