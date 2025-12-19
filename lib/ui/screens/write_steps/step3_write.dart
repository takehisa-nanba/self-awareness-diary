import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/write_provider.dart';

class Step3Write extends StatelessWidget {
  const Step3Write({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WriteProvider>();

    return Column(
      children: [
        if (provider.isGenerating) const CircularProgressIndicator()
        else Container(
          padding: const EdgeInsets.all(16),
          color: Colors.indigo.shade50,
          child: Text(provider.reflectionQuestion, style: const TextStyle(fontStyle: FontStyle.italic)),
        ),
        const SizedBox(height: 20),
        TextField(
          maxLines: 5,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '自分の答え...'),
          onChanged: (v) => provider.selfAnalysisText = v,
        ),
      ],
    );
  }
}