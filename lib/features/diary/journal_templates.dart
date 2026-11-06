/// 日记模板（v5.9.1，Day One templates 借鉴）：
/// 内置结构化模板，编辑器一键插入正文，占位符创建时解析。
/// 固定内置（零存储、零网络），后续可扩展用户自定义。

class JournalTemplate {
  final String name;
  final String body; // 支持 {{日期}} {{星期}} 占位符

  const JournalTemplate(this.name, this.body);
}

const journalTemplates = <JournalTemplate>[
  JournalTemplate(
    '每日回顾',
    '今天做了什么：\n\n\n'
        '学到 / 想到：\n\n\n'
        '明天想改进的一件小事：\n',
  ),
  JournalTemplate(
    '感恩记录',
    '今天感谢的三件事：\n'
        '1. \n'
        '2. \n'
        '3. \n\n'
        '其中最想展开写的一件：\n',
  ),
  JournalTemplate(
    '情绪拆解',
    '此刻的情绪：\n'
        '可能的来源：\n'
        '身体的感觉：\n'
        '想对自己说：\n',
  ),
  JournalTemplate(
    '小确幸清单',
    '今天的三个小确幸：\n'
        '- \n'
        '- \n'
        '- \n',
  ),
  JournalTemplate(
    '每周复盘',
    '本周做得最好的：\n'
        '本周想改进的：\n'
        '下周最重要的一件事：\n',
  ),
];

/// 解析占位符：{{日期}} → M月d日，{{星期}} → 星期X
String resolveTemplate(JournalTemplate t, DateTime now) {
  const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  return t.body
      .replaceAll('{{日期}}', '${now.month}月${now.day}日')
      .replaceAll('{{星期}}', '星期${weekdays[now.weekday - 1]}');
}
