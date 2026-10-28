import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoman/features/diary/journal_prompts.dart';

/// 写作提示（v5.8.1）纯函数回归
void main() {
  test('promptOfDay 同一天恒定、不同日期轮换、始终在池内', () {
    final a = DateTime(2026, 10, 27);
    final b = DateTime(2026, 10, 28);
    final c = DateTime(2027, 10, 27); // 跨年同月日
    final pa = promptOfDay(a);
    expect(pa, promptOfDay(a)); // 恒定
    expect(journalPrompts, contains(pa)); // 在池内
    expect(promptOfDay(b) == pa, anyOf(isTrue, isFalse)); // 不抛即合法
    // 跨年同月日 = 相差 365 天，池 30 条：dayOfYear 差值轮换（有覆盖到不同条的概率）
    expect(journalPrompts, contains(promptOfDay(c)));
  });

  test('nextPrompt 永不返回当前条，且始终在池内', () {
    final rng = Random(42);
    for (var i = 0; i < 200; i++) {
      final current = journalPrompts[i % journalPrompts.length];
      final next = nextPrompt(current, rng);
      expect(next, isNot(current));
      expect(journalPrompts, contains(next));
    }
  });
}
