import 'package:drift/drift.dart';

import '../../domain/models/schedule.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/services/schedule_generator.dart';
import '../db/database.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  ScheduleRepositoryImpl(this._db);

  final AppDatabase _db;

  ScheduleInstance _map(ScheduleInstanceRow row) => ScheduleInstance(
        id: row.id,
        templateId: row.templateId,
        dateDay: row.dateDay,
        startMinutes: row.startMinutes,
        durationMinutes: row.durationMinutes,
        title: row.title,
        description: row.description,
        colorIndex: row.colorIndex,
        status: BlockStatus.values[row.status.clamp(0, 2)],
        detached: row.detached,
        remindAt: row.remindAt,
        notifiedAt: row.notifiedAt,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  ScheduleTemplate _mapTemplate(ScheduleTemplateRow row) => ScheduleTemplate(
        id: row.id,
        title: row.title,
        description: row.description,
        colorIndex: row.colorIndex,
        rrule: row.rrule,
        exdates: row.exdates,
        startMinutes: row.startMinutes,
        durationMinutes: row.durationMinutes,
        remindMinutesBefore: row.remindMinutesBefore,
        enabled: row.enabled,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  @override
  Stream<List<ScheduleInstance>> watchDay(int dateDay) {
    final q = _db.select(_db.scheduleInstances)
      ..where((i) => i.dateDay.equals(dateDay))
      ..orderBy([(i) => OrderingTerm.asc(i.startMinutes)]);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  @override
  Stream<List<ScheduleInstance>> watchRange(int fromDay, int toDay) {
    final q = _db.select(_db.scheduleInstances)
      ..where((i) => i.dateDay.isBetweenValues(fromDay, toDay))
      ..orderBy([(i) => OrderingTerm.asc(i.startMinutes)]);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  @override
  Future<ScheduleInstance?> getInstance(int id) async {
    final row = await (_db.select(_db.scheduleInstances)
          ..where((i) => i.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<int> saveInstance({
    required int? id,
    required int? templateId,
    required int dateDay,
    required int startMinutes,
    required int durationMinutes,
    required String title,
    required String description,
    required int colorIndex,
    required bool detachOnEdit,
    required int? remindMinutesBefore,
  }) async {
    final now = DateTime.now();
    // detach 语义：来自模板的实例被手动修改 → detached=true
    final detached = detachOnEdit && templateId != null;
    DateTime? remindAt;
    if (remindMinutesBefore != null && remindMinutesBefore > 0) {
      final day = DateDay.toDateTime(dateDay);
      final start = DateTime(day.year, day.month, day.day);
      remindAt =
          start.add(Duration(minutes: startMinutes - remindMinutesBefore));
    }
    if (id == null) {
      return _db.into(_db.scheduleInstances).insert(
            ScheduleInstancesCompanion.insert(
              templateId: Value(templateId),
              dateDay: dateDay,
              startMinutes: startMinutes,
              durationMinutes: durationMinutes,
              title: title,
              description: Value(description),
              colorIndex: Value(colorIndex),
              detached: Value(detached),
              remindAt: Value(remindAt),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
    await (_db.update(_db.scheduleInstances)..where((i) => i.id.equals(id)))
        .write(
      ScheduleInstancesCompanion(
        templateId: Value(templateId),
        dateDay: Value(dateDay),
        startMinutes: Value(startMinutes),
        durationMinutes: Value(durationMinutes),
        title: Value(title),
        description: Value(description),
        colorIndex: Value(colorIndex),
        detached: Value(detached),
        remindAt: Value(remindAt),
        updatedAt: Value(now),
      ),
    );
    return id;
  }

  @override
  Future<void> setStatus({required int id, required BlockStatus status}) =>
      (_db.update(_db.scheduleInstances)..where((i) => i.id.equals(id))).write(
        ScheduleInstancesCompanion(
          status: Value(status.index),
          updatedAt: Value(DateTime.now()),
        ),
      );

  @override
  Future<void> deleteInstance(int id) =>
      (_db.delete(_db.scheduleInstances)..where((i) => i.id.equals(id))).go();

  @override
  Future<void> skipTemplateOccurrence({
    required ScheduleTemplate template,
    required int dateDay,
  }) async {
    // EXDATE 语义：在模板层记例外（可撤销），删除该次实例行
    final set = template.exdates
        .split(',')
        .where((s) => s.isNotEmpty)
        .map(int.parse)
        .toSet();
    set.add(dateDay);
    final csv = set.join(',');
    await (_db.update(_db.scheduleTemplates)
          ..where((t) => t.id.equals(template.id)))
        .write(
      ScheduleTemplatesCompanion(
        exdates: Value(csv),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await (_db.delete(_db.scheduleInstances)
          ..where(
            (i) =>
                i.templateId.equals(template.id) & i.dateDay.equals(dateDay),
          ))
        .go();
  }

  @override
  Stream<List<ScheduleTemplate>> watchTemplates() {
    final q = _db.select(_db.scheduleTemplates)
      ..orderBy([(t) => OrderingTerm.asc(t.startMinutes)]);
    return q.watch().map((rows) => rows.map(_mapTemplate).toList());
  }

  @override
  Future<ScheduleTemplate?> getTemplate(int id) async {
    final row = await (_db.select(_db.scheduleTemplates)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _mapTemplate(row);
  }

  @override
  Future<int> saveTemplate(ScheduleTemplate t, {required bool isNew}) async {
    final now = DateTime.now();
    int id;
    if (isNew) {
      id = await _db.into(_db.scheduleTemplates).insert(
            ScheduleTemplatesCompanion.insert(
              title: t.title,
              description: Value(t.description),
              colorIndex: Value(t.colorIndex),
              rrule: Value(t.rrule),
              exdates: Value(t.exdates),
              startMinutes: t.startMinutes,
              durationMinutes: t.durationMinutes,
              remindMinutesBefore: Value(t.remindMinutesBefore),
              enabled: Value(t.enabled),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else {
      id = t.id;
      await (_db.update(_db.scheduleTemplates)
            ..where((x) => x.id.equals(id)))
          .write(
        ScheduleTemplatesCompanion(
          title: Value(t.title),
          description: Value(t.description),
          colorIndex: Value(t.colorIndex),
          rrule: Value(t.rrule),
          exdates: Value(t.exdates),
          startMinutes: Value(t.startMinutes),
          durationMinutes: Value(t.durationMinutes),
          remindMinutesBefore: Value(t.remindMinutesBefore),
          enabled: Value(t.enabled),
          updatedAt: Value(now),
        ),
      );
      // 模板更新：删除未来未 detach 且未开始的实例行，regenerate 按新规则重建
      final todayDay = DateDay.of(DateTime.now());
      final future = await (_db.select(_db.scheduleInstances)
            ..where((i) => i.templateId.equals(id)))
          .get();
      for (final row in future) {
        final inst = _map(row);
        if (ScheduleGenerator.shouldDropInstance(inst, todayDay)) {
          await deleteInstance(inst.id);
        }
      }
    }
    await regenerate();
    return id;
  }

  @override
  Future<void> deleteTemplate(int id) async {
    await (_db.delete(_db.scheduleTemplates)..where((t) => t.id.equals(id)))
        .go();
    // 该模板未来的 pending 实例一并清除（已 detach 保留）
    final todayDay = DateDay.of(DateTime.now());
    final rows = await (_db.select(_db.scheduleInstances)
          ..where((i) => i.templateId.equals(id)))
        .get();
    for (final row in rows) {
      final inst = _map(row);
      if (ScheduleGenerator.shouldDropInstance(inst, todayDay)) {
        await deleteInstance(inst.id);
      }
    }
  }

  @override
  Future<void> regenerate({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final todayDay = DateDay.of(current);
    final rangeStart = DateTime(current.year, current.month, current.day);
    final rangeEnd = rangeStart.add(
      const Duration(days: ScheduleGenerator.windowDays),
    );

    final templates =
        await (_db.select(_db.scheduleTemplates)
              ..where((t) => t.enabled.equals(true)))
            .get();
    final from = DateDay.of(rangeStart);
    final to = DateDay.of(rangeEnd);
    final existingRows = await (_db.select(_db.scheduleInstances)
          ..where((i) => i.dateDay.isBetweenValues(from, to)))
        .get();
    final existing = existingRows.map(_map).toList();

    final missing = ScheduleGenerator.missing(
      templates: templates.map(_mapTemplate).toList(),
      existing: existing,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );

    for (final n in missing) {
      await _db.into(_db.scheduleInstances).insert(
            ScheduleInstancesCompanion.insert(
              templateId: Value(n.templateId),
              dateDay: n.dateDay,
              startMinutes: n.startMinutes,
              durationMinutes: n.durationMinutes,
              title: n.title,
              description: Value(n.description),
              colorIndex: Value(n.colorIndex),
              createdAt: current,
              updatedAt: current,
            ),
          );
    }
    _lastRegeneratedDay = todayDay;
  }

  int? _lastRegeneratedDay;

  @override
  Future<void> markNotified(int instanceId) =>
      (_db.update(_db.scheduleInstances)..where((i) => i.id.equals(instanceId)))
          .write(
        ScheduleInstancesCompanion(
          notifiedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// 今天是否已生成过（App 启动 / 页面打开时判断，避免重复全量扫）
  @override
  bool get needsRegenerate {
    final todayDay = DateDay.of(DateTime.now());
    return _lastRegeneratedDay != todayDay;
  }
}

