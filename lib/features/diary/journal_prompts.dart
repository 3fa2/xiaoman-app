/// 写作提示（v5.8.1，Day One 式 journaling prompts）：
/// 解决「打开编辑器不知道写什么」。内置提示池，按日期轮换，
/// 也可随机换一个。纯函数，可单测。
library;

import 'dart:math';

const journalPrompts = <String>[
  '今天最让我平静的一个瞬间',
  '今天有没有一件小事值得记住？',
  '此刻窗外是什么样子？',
  '今天我对自己说的一句话',
  '最近在重复做的一件事',
  '有什么想忘掉又忘不掉的？',
  '今天吃了什么，和谁一起？',
  '如果今天重来一次，我会……',
  '最近一次心动 / 感动的瞬间',
  '这周想完成但还没做的一件事',
  '今天学到了什么新东西',
  '此刻身体的感觉：累、松、还是紧？',
  '最近让我笑出来的一个瞬间',
  '有什么话想说但没说出口？',
  '写下今天遇到的一个陌生人',
  '最近在听什么，看什么，读什么？',
  '今天的天空/天气，配得上什么心情？',
  '十年后的我会怎么看今天？',
  '今天最想感谢的一个人',
  '如果现在必须出门，我会去哪？',
  '今天一个小小的决定',
  '最近让我放不下的一个念头',
  '写下一个想保住的具体细节：颜色、声音、气味',
  '今天哪里做得比昨天好一点点？',
  '最近一次独处时在想什么？',
  '有什么在悄悄变好？',
  '今天的一个"如果"：如果……就好了',
  '此刻最想抓住的一天/一小时',
  '最近一个反复出现的梦',
  '给今天的自己打个分，为什么？',
];

/// 当日提示（按年内天号轮换，同一天恒定）
String promptOfDay(DateTime date) {
  final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
  return journalPrompts[dayOfYear % journalPrompts.length];
}

/// 随机换一个（避开当前这条）
String nextPrompt(String current, [Random? random]) {
  if (journalPrompts.length <= 1) return current;
  final rng = random ?? Random();
  var candidate = journalPrompts[rng.nextInt(journalPrompts.length)];
  // 连抽防同条（最多 5 次，池 30 条撞一次概率 1/30）
  var tries = 0;
  while (candidate == current && tries < 5) {
    candidate = journalPrompts[rng.nextInt(journalPrompts.length)];
    tries++;
  }
  return candidate;
}
