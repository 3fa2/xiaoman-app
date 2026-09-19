import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// 首页白屏根因回归测试：DateFormat(zh_CN) 必须在 initializeDateFormatting
/// 之后使用（intl 默认只带 en_US 日期符号）。
void main() {
  test('未初始化时 DateFormat(zh_CN) 会抛 LocaleDataException（根因复现）', () {
    expect(
      () => DateFormat('M月d日 EEEE', 'zh_CN').format(DateTime(2026, 9, 19)),
      throwsException,
    );
  });

  test('initializeDateFormatting 后正常格式化（修复验证）', () async {
    await initializeDateFormatting('zh_CN');
    Intl.defaultLocale = 'zh_CN';
    final out =
        DateFormat('M月d日 EEEE', 'zh_CN').format(DateTime(2026, 9, 19));
    expect(out, contains('9月19日'));
    expect(out, contains('星期')); // EEEE 在 zh_CN 下是"星期六"
  });
}
