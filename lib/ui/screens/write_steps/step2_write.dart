// lib/ui/screens/write_steps/step2_write.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/write_provider.dart';

class Step2Write extends StatelessWidget {
  const Step2Write({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WriteProvider>();

    return Column(
      children: [
        const Text('何がありましたか？', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(
          maxLines: 5,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '出来事を入力...'),
          onChanged: (v) => provider.eventText = v,
        ),
      ],
    );
  }
}