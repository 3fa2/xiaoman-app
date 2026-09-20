// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DiariesTable extends Diaries with TableInfo<$DiariesTable, DiariesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateDayMeta =
      const VerificationMeta('dateDay');
  @override
  late final GeneratedColumn<int> dateDay = GeneratedColumn<int>(
      'date_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _notebookIdMeta =
      const VerificationMeta('notebookId');
  @override
  late final GeneratedColumn<int> notebookId = GeneratedColumn<int>(
      'notebook_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _moodIdMeta = const VerificationMeta('moodId');
  @override
  late final GeneratedColumn<int> moodId = GeneratedColumn<int>(
      'mood_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        dateDay,
        title,
        content,
        tags,
        notebookId,
        moodId,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diaries';
  @override
  VerificationContext validateIntegrity(Insertable<DiariesRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date_day')) {
      context.handle(_dateDayMeta,
          dateDay.isAcceptableOrUnknown(data['date_day']!, _dateDayMeta));
    } else if (isInserting) {
      context.missing(_dateDayMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('notebook_id')) {
      context.handle(
          _notebookIdMeta,
          notebookId.isAcceptableOrUnknown(
              data['notebook_id']!, _notebookIdMeta));
    }
    if (data.containsKey('mood_id')) {
      context.handle(_moodIdMeta,
          moodId.isAcceptableOrUnknown(data['mood_id']!, _moodIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiariesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiariesRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      dateDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}date_day'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      notebookId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}notebook_id']),
      moodId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mood_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DiariesTable createAlias(String alias) {
    return $DiariesTable(attachedDatabase, alias);
  }
}

class DiariesRow extends DataClass implements Insertable<DiariesRow> {
  final int id;
  final int dateDay;
  final String title;
  final String content;
  final String tags;
  final int? notebookId;
  final int? moodId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DiariesRow(
      {required this.id,
      required this.dateDay,
      required this.title,
      required this.content,
      required this.tags,
      this.notebookId,
      this.moodId,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date_day'] = Variable<int>(dateDay);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    map['tags'] = Variable<String>(tags);
    if (!nullToAbsent || notebookId != null) {
      map['notebook_id'] = Variable<int>(notebookId);
    }
    if (!nullToAbsent || moodId != null) {
      map['mood_id'] = Variable<int>(moodId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DiariesCompanion toCompanion(bool nullToAbsent) {
    return DiariesCompanion(
      id: Value(id),
      dateDay: Value(dateDay),
      title: Value(title),
      content: Value(content),
      tags: Value(tags),
      notebookId: notebookId == null && nullToAbsent
          ? const Value.absent()
          : Value(notebookId),
      moodId:
          moodId == null && nullToAbsent ? const Value.absent() : Value(moodId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DiariesRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiariesRow(
      id: serializer.fromJson<int>(json['id']),
      dateDay: serializer.fromJson<int>(json['dateDay']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      tags: serializer.fromJson<String>(json['tags']),
      notebookId: serializer.fromJson<int?>(json['notebookId']),
      moodId: serializer.fromJson<int?>(json['moodId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dateDay': serializer.toJson<int>(dateDay),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'tags': serializer.toJson<String>(tags),
      'notebookId': serializer.toJson<int?>(notebookId),
      'moodId': serializer.toJson<int?>(moodId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DiariesRow copyWith(
          {int? id,
          int? dateDay,
          String? title,
          String? content,
          String? tags,
          Value<int?> notebookId = const Value.absent(),
          Value<int?> moodId = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      DiariesRow(
        id: id ?? this.id,
        dateDay: dateDay ?? this.dateDay,
        title: title ?? this.title,
        content: content ?? this.content,
        tags: tags ?? this.tags,
        notebookId: notebookId.present ? notebookId.value : this.notebookId,
        moodId: moodId.present ? moodId.value : this.moodId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DiariesRow copyWithCompanion(DiariesCompanion data) {
    return DiariesRow(
      id: data.id.present ? data.id.value : this.id,
      dateDay: data.dateDay.present ? data.dateDay.value : this.dateDay,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      tags: data.tags.present ? data.tags.value : this.tags,
      notebookId:
          data.notebookId.present ? data.notebookId.value : this.notebookId,
      moodId: data.moodId.present ? data.moodId.value : this.moodId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiariesRow(')
          ..write('id: $id, ')
          ..write('dateDay: $dateDay, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('tags: $tags, ')
          ..write('notebookId: $notebookId, ')
          ..write('moodId: $moodId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dateDay, title, content, tags, notebookId,
      moodId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiariesRow &&
          other.id == this.id &&
          other.dateDay == this.dateDay &&
          other.title == this.title &&
          other.content == this.content &&
          other.tags == this.tags &&
          other.notebookId == this.notebookId &&
          other.moodId == this.moodId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DiariesCompanion extends UpdateCompanion<DiariesRow> {
  final Value<int> id;
  final Value<int> dateDay;
  final Value<String> title;
  final Value<String> content;
  final Value<String> tags;
  final Value<int?> notebookId;
  final Value<int?> moodId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const DiariesCompanion({
    this.id = const Value.absent(),
    this.dateDay = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.tags = const Value.absent(),
    this.notebookId = const Value.absent(),
    this.moodId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DiariesCompanion.insert({
    this.id = const Value.absent(),
    required int dateDay,
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.tags = const Value.absent(),
    this.notebookId = const Value.absent(),
    this.moodId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : dateDay = Value(dateDay),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<DiariesRow> custom({
    Expression<int>? id,
    Expression<int>? dateDay,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? tags,
    Expression<int>? notebookId,
    Expression<int>? moodId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dateDay != null) 'date_day': dateDay,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (tags != null) 'tags': tags,
      if (notebookId != null) 'notebook_id': notebookId,
      if (moodId != null) 'mood_id': moodId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DiariesCompanion copyWith(
      {Value<int>? id,
      Value<int>? dateDay,
      Value<String>? title,
      Value<String>? content,
      Value<String>? tags,
      Value<int?>? notebookId,
      Value<int?>? moodId,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return DiariesCompanion(
      id: id ?? this.id,
      dateDay: dateDay ?? this.dateDay,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      notebookId: notebookId ?? this.notebookId,
      moodId: moodId ?? this.moodId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dateDay.present) {
      map['date_day'] = Variable<int>(dateDay.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (notebookId.present) {
      map['notebook_id'] = Variable<int>(notebookId.value);
    }
    if (moodId.present) {
      map['mood_id'] = Variable<int>(moodId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiariesCompanion(')
          ..write('id: $id, ')
          ..write('dateDay: $dateDay, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('tags: $tags, ')
          ..write('notebookId: $notebookId, ')
          ..write('moodId: $moodId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MoodsTable extends Moods with TableInfo<$MoodsTable, MoodsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _hueMeta = const VerificationMeta('hue');
  @override
  late final GeneratedColumn<double> hue = GeneratedColumn<double>(
      'hue', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _isPresetMeta =
      const VerificationMeta('isPreset');
  @override
  late final GeneratedColumn<bool> isPreset = GeneratedColumn<bool>(
      'is_preset', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_preset" IN (0, 1))'));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, hue, isPreset, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'moods';
  @override
  VerificationContext validateIntegrity(Insertable<MoodsRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('hue')) {
      context.handle(
          _hueMeta, hue.isAcceptableOrUnknown(data['hue']!, _hueMeta));
    } else if (isInserting) {
      context.missing(_hueMeta);
    }
    if (data.containsKey('is_preset')) {
      context.handle(_isPresetMeta,
          isPreset.isAcceptableOrUnknown(data['is_preset']!, _isPresetMeta));
    } else if (isInserting) {
      context.missing(_isPresetMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MoodsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MoodsRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      hue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}hue'])!,
      isPreset: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_preset'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $MoodsTable createAlias(String alias) {
    return $MoodsTable(attachedDatabase, alias);
  }
}

class MoodsRow extends DataClass implements Insertable<MoodsRow> {
  final int id;
  final String name;
  final double hue;
  final bool isPreset;
  final int sortOrder;
  const MoodsRow(
      {required this.id,
      required this.name,
      required this.hue,
      required this.isPreset,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['hue'] = Variable<double>(hue);
    map['is_preset'] = Variable<bool>(isPreset);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  MoodsCompanion toCompanion(bool nullToAbsent) {
    return MoodsCompanion(
      id: Value(id),
      name: Value(name),
      hue: Value(hue),
      isPreset: Value(isPreset),
      sortOrder: Value(sortOrder),
    );
  }

  factory MoodsRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MoodsRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      hue: serializer.fromJson<double>(json['hue']),
      isPreset: serializer.fromJson<bool>(json['isPreset']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'hue': serializer.toJson<double>(hue),
      'isPreset': serializer.toJson<bool>(isPreset),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  MoodsRow copyWith(
          {int? id,
          String? name,
          double? hue,
          bool? isPreset,
          int? sortOrder}) =>
      MoodsRow(
        id: id ?? this.id,
        name: name ?? this.name,
        hue: hue ?? this.hue,
        isPreset: isPreset ?? this.isPreset,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  MoodsRow copyWithCompanion(MoodsCompanion data) {
    return MoodsRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      hue: data.hue.present ? data.hue.value : this.hue,
      isPreset: data.isPreset.present ? data.isPreset.value : this.isPreset,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MoodsRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('hue: $hue, ')
          ..write('isPreset: $isPreset, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, hue, isPreset, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoodsRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.hue == this.hue &&
          other.isPreset == this.isPreset &&
          other.sortOrder == this.sortOrder);
}

class MoodsCompanion extends UpdateCompanion<MoodsRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> hue;
  final Value<bool> isPreset;
  final Value<int> sortOrder;
  const MoodsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.hue = const Value.absent(),
    this.isPreset = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  MoodsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double hue,
    required bool isPreset,
    required int sortOrder,
  })  : name = Value(name),
        hue = Value(hue),
        isPreset = Value(isPreset),
        sortOrder = Value(sortOrder);
  static Insertable<MoodsRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? hue,
    Expression<bool>? isPreset,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (hue != null) 'hue': hue,
      if (isPreset != null) 'is_preset': isPreset,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  MoodsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<double>? hue,
      Value<bool>? isPreset,
      Value<int>? sortOrder}) {
    return MoodsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      hue: hue ?? this.hue,
      isPreset: isPreset ?? this.isPreset,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (hue.present) {
      map['hue'] = Variable<double>(hue.value);
    }
    if (isPreset.present) {
      map['is_preset'] = Variable<bool>(isPreset.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoodsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('hue: $hue, ')
          ..write('isPreset: $isPreset, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $MediaItemsTable extends MediaItems
    with TableInfo<$MediaItemsTable, MediaItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _ownerTypeMeta =
      const VerificationMeta('ownerType');
  @override
  late final GeneratedColumn<int> ownerType = GeneratedColumn<int>(
      'owner_type', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<int> ownerId = GeneratedColumn<int>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<int> kind = GeneratedColumn<int>(
      'kind', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _coverPathMeta =
      const VerificationMeta('coverPath');
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
      'cover_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _videoPathMeta =
      const VerificationMeta('videoPath');
  @override
  late final GeneratedColumn<String> videoPath = GeneratedColumn<String>(
      'video_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _thumbPathMeta =
      const VerificationMeta('thumbPath');
  @override
  late final GeneratedColumn<String> thumbPath = GeneratedColumn<String>(
      'thumb_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
      'width', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
      'height', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        ownerType,
        ownerId,
        kind,
        coverPath,
        videoPath,
        thumbPath,
        sortOrder,
        width,
        height,
        durationMs,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_items';
  @override
  VerificationContext validateIntegrity(Insertable<MediaItemRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('owner_type')) {
      context.handle(_ownerTypeMeta,
          ownerType.isAcceptableOrUnknown(data['owner_type']!, _ownerTypeMeta));
    } else if (isInserting) {
      context.missing(_ownerTypeMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('cover_path')) {
      context.handle(_coverPathMeta,
          coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta));
    }
    if (data.containsKey('video_path')) {
      context.handle(_videoPathMeta,
          videoPath.isAcceptableOrUnknown(data['video_path']!, _videoPathMeta));
    }
    if (data.containsKey('thumb_path')) {
      context.handle(_thumbPathMeta,
          thumbPath.isAcceptableOrUnknown(data['thumb_path']!, _thumbPathMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
          _widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaItemRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      ownerType: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}owner_type'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}owner_id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kind'])!,
      coverPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_path']),
      videoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}video_path']),
      thumbPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumb_path']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      width: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}width']),
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height']),
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $MediaItemsTable createAlias(String alias) {
    return $MediaItemsTable(attachedDatabase, alias);
  }
}

class MediaItemRow extends DataClass implements Insertable<MediaItemRow> {
  final int id;
  final int ownerType;
  final int ownerId;
  final int kind;
  final String? coverPath;
  final String? videoPath;
  final String? thumbPath;
  final int sortOrder;
  final int? width;
  final int? height;
  final int? durationMs;
  final DateTime createdAt;
  const MediaItemRow(
      {required this.id,
      required this.ownerType,
      required this.ownerId,
      required this.kind,
      this.coverPath,
      this.videoPath,
      this.thumbPath,
      required this.sortOrder,
      this.width,
      this.height,
      this.durationMs,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['owner_type'] = Variable<int>(ownerType);
    map['owner_id'] = Variable<int>(ownerId);
    map['kind'] = Variable<int>(kind);
    if (!nullToAbsent || coverPath != null) {
      map['cover_path'] = Variable<String>(coverPath);
    }
    if (!nullToAbsent || videoPath != null) {
      map['video_path'] = Variable<String>(videoPath);
    }
    if (!nullToAbsent || thumbPath != null) {
      map['thumb_path'] = Variable<String>(thumbPath);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MediaItemsCompanion toCompanion(bool nullToAbsent) {
    return MediaItemsCompanion(
      id: Value(id),
      ownerType: Value(ownerType),
      ownerId: Value(ownerId),
      kind: Value(kind),
      coverPath: coverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPath),
      videoPath: videoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(videoPath),
      thumbPath: thumbPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbPath),
      sortOrder: Value(sortOrder),
      width:
          width == null && nullToAbsent ? const Value.absent() : Value(width),
      height:
          height == null && nullToAbsent ? const Value.absent() : Value(height),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      createdAt: Value(createdAt),
    );
  }

  factory MediaItemRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaItemRow(
      id: serializer.fromJson<int>(json['id']),
      ownerType: serializer.fromJson<int>(json['ownerType']),
      ownerId: serializer.fromJson<int>(json['ownerId']),
      kind: serializer.fromJson<int>(json['kind']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
      videoPath: serializer.fromJson<String?>(json['videoPath']),
      thumbPath: serializer.fromJson<String?>(json['thumbPath']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ownerType': serializer.toJson<int>(ownerType),
      'ownerId': serializer.toJson<int>(ownerId),
      'kind': serializer.toJson<int>(kind),
      'coverPath': serializer.toJson<String?>(coverPath),
      'videoPath': serializer.toJson<String?>(videoPath),
      'thumbPath': serializer.toJson<String?>(thumbPath),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'durationMs': serializer.toJson<int?>(durationMs),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MediaItemRow copyWith(
          {int? id,
          int? ownerType,
          int? ownerId,
          int? kind,
          Value<String?> coverPath = const Value.absent(),
          Value<String?> videoPath = const Value.absent(),
          Value<String?> thumbPath = const Value.absent(),
          int? sortOrder,
          Value<int?> width = const Value.absent(),
          Value<int?> height = const Value.absent(),
          Value<int?> durationMs = const Value.absent(),
          DateTime? createdAt}) =>
      MediaItemRow(
        id: id ?? this.id,
        ownerType: ownerType ?? this.ownerType,
        ownerId: ownerId ?? this.ownerId,
        kind: kind ?? this.kind,
        coverPath: coverPath.present ? coverPath.value : this.coverPath,
        videoPath: videoPath.present ? videoPath.value : this.videoPath,
        thumbPath: thumbPath.present ? thumbPath.value : this.thumbPath,
        sortOrder: sortOrder ?? this.sortOrder,
        width: width.present ? width.value : this.width,
        height: height.present ? height.value : this.height,
        durationMs: durationMs.present ? durationMs.value : this.durationMs,
        createdAt: createdAt ?? this.createdAt,
      );
  MediaItemRow copyWithCompanion(MediaItemsCompanion data) {
    return MediaItemRow(
      id: data.id.present ? data.id.value : this.id,
      ownerType: data.ownerType.present ? data.ownerType.value : this.ownerType,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      kind: data.kind.present ? data.kind.value : this.kind,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      videoPath: data.videoPath.present ? data.videoPath.value : this.videoPath,
      thumbPath: data.thumbPath.present ? data.thumbPath.value : this.thumbPath,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaItemRow(')
          ..write('id: $id, ')
          ..write('ownerType: $ownerType, ')
          ..write('ownerId: $ownerId, ')
          ..write('kind: $kind, ')
          ..write('coverPath: $coverPath, ')
          ..write('videoPath: $videoPath, ')
          ..write('thumbPath: $thumbPath, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('durationMs: $durationMs, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ownerType, ownerId, kind, coverPath,
      videoPath, thumbPath, sortOrder, width, height, durationMs, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaItemRow &&
          other.id == this.id &&
          other.ownerType == this.ownerType &&
          other.ownerId == this.ownerId &&
          other.kind == this.kind &&
          other.coverPath == this.coverPath &&
          other.videoPath == this.videoPath &&
          other.thumbPath == this.thumbPath &&
          other.sortOrder == this.sortOrder &&
          other.width == this.width &&
          other.height == this.height &&
          other.durationMs == this.durationMs &&
          other.createdAt == this.createdAt);
}

class MediaItemsCompanion extends UpdateCompanion<MediaItemRow> {
  final Value<int> id;
  final Value<int> ownerType;
  final Value<int> ownerId;
  final Value<int> kind;
  final Value<String?> coverPath;
  final Value<String?> videoPath;
  final Value<String?> thumbPath;
  final Value<int> sortOrder;
  final Value<int?> width;
  final Value<int?> height;
  final Value<int?> durationMs;
  final Value<DateTime> createdAt;
  const MediaItemsCompanion({
    this.id = const Value.absent(),
    this.ownerType = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.kind = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.videoPath = const Value.absent(),
    this.thumbPath = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MediaItemsCompanion.insert({
    this.id = const Value.absent(),
    required int ownerType,
    required int ownerId,
    required int kind,
    this.coverPath = const Value.absent(),
    this.videoPath = const Value.absent(),
    this.thumbPath = const Value.absent(),
    required int sortOrder,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.durationMs = const Value.absent(),
    required DateTime createdAt,
  })  : ownerType = Value(ownerType),
        ownerId = Value(ownerId),
        kind = Value(kind),
        sortOrder = Value(sortOrder),
        createdAt = Value(createdAt);
  static Insertable<MediaItemRow> custom({
    Expression<int>? id,
    Expression<int>? ownerType,
    Expression<int>? ownerId,
    Expression<int>? kind,
    Expression<String>? coverPath,
    Expression<String>? videoPath,
    Expression<String>? thumbPath,
    Expression<int>? sortOrder,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? durationMs,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerType != null) 'owner_type': ownerType,
      if (ownerId != null) 'owner_id': ownerId,
      if (kind != null) 'kind': kind,
      if (coverPath != null) 'cover_path': coverPath,
      if (videoPath != null) 'video_path': videoPath,
      if (thumbPath != null) 'thumb_path': thumbPath,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (durationMs != null) 'duration_ms': durationMs,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MediaItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? ownerType,
      Value<int>? ownerId,
      Value<int>? kind,
      Value<String?>? coverPath,
      Value<String?>? videoPath,
      Value<String?>? thumbPath,
      Value<int>? sortOrder,
      Value<int?>? width,
      Value<int?>? height,
      Value<int?>? durationMs,
      Value<DateTime>? createdAt}) {
    return MediaItemsCompanion(
      id: id ?? this.id,
      ownerType: ownerType ?? this.ownerType,
      ownerId: ownerId ?? this.ownerId,
      kind: kind ?? this.kind,
      coverPath: coverPath ?? this.coverPath,
      videoPath: videoPath ?? this.videoPath,
      thumbPath: thumbPath ?? this.thumbPath,
      sortOrder: sortOrder ?? this.sortOrder,
      width: width ?? this.width,
      height: height ?? this.height,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ownerType.present) {
      map['owner_type'] = Variable<int>(ownerType.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<int>(ownerId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(kind.value);
    }
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
    }
    if (videoPath.present) {
      map['video_path'] = Variable<String>(videoPath.value);
    }
    if (thumbPath.present) {
      map['thumb_path'] = Variable<String>(thumbPath.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaItemsCompanion(')
          ..write('id: $id, ')
          ..write('ownerType: $ownerType, ')
          ..write('ownerId: $ownerId, ')
          ..write('kind: $kind, ')
          ..write('coverPath: $coverPath, ')
          ..write('videoPath: $videoPath, ')
          ..write('thumbPath: $thumbPath, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('durationMs: $durationMs, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DiaryNotebooksTable extends DiaryNotebooks
    with TableInfo<$DiaryNotebooksTable, DiaryNotebookRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiaryNotebooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorIndexMeta =
      const VerificationMeta('colorIndex');
  @override
  late final GeneratedColumn<int> colorIndex = GeneratedColumn<int>(
      'color_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, colorIndex, sortOrder, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diary_notebooks';
  @override
  VerificationContext validateIntegrity(Insertable<DiaryNotebookRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_index')) {
      context.handle(
          _colorIndexMeta,
          colorIndex.isAcceptableOrUnknown(
              data['color_index']!, _colorIndexMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiaryNotebookRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiaryNotebookRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      colorIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color_index'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DiaryNotebooksTable createAlias(String alias) {
    return $DiaryNotebooksTable(attachedDatabase, alias);
  }
}

class DiaryNotebookRow extends DataClass
    implements Insertable<DiaryNotebookRow> {
  final int id;
  final String name;
  final int colorIndex;
  final int sortOrder;
  final DateTime createdAt;
  const DiaryNotebookRow(
      {required this.id,
      required this.name,
      required this.colorIndex,
      required this.sortOrder,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color_index'] = Variable<int>(colorIndex);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DiaryNotebooksCompanion toCompanion(bool nullToAbsent) {
    return DiaryNotebooksCompanion(
      id: Value(id),
      name: Value(name),
      colorIndex: Value(colorIndex),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory DiaryNotebookRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiaryNotebookRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorIndex: serializer.fromJson<int>(json['colorIndex']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'colorIndex': serializer.toJson<int>(colorIndex),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DiaryNotebookRow copyWith(
          {int? id,
          String? name,
          int? colorIndex,
          int? sortOrder,
          DateTime? createdAt}) =>
      DiaryNotebookRow(
        id: id ?? this.id,
        name: name ?? this.name,
        colorIndex: colorIndex ?? this.colorIndex,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
      );
  DiaryNotebookRow copyWithCompanion(DiaryNotebooksCompanion data) {
    return DiaryNotebookRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorIndex:
          data.colorIndex.present ? data.colorIndex.value : this.colorIndex,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiaryNotebookRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, colorIndex, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiaryNotebookRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorIndex == this.colorIndex &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class DiaryNotebooksCompanion extends UpdateCompanion<DiaryNotebookRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> colorIndex;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const DiaryNotebooksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DiaryNotebooksCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.colorIndex = const Value.absent(),
    required int sortOrder,
    required DateTime createdAt,
  })  : name = Value(name),
        sortOrder = Value(sortOrder),
        createdAt = Value(createdAt);
  static Insertable<DiaryNotebookRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? colorIndex,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorIndex != null) 'color_index': colorIndex,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DiaryNotebooksCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? colorIndex,
      Value<int>? sortOrder,
      Value<DateTime>? createdAt}) {
    return DiaryNotebooksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorIndex.present) {
      map['color_index'] = Variable<int>(colorIndex.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiaryNotebooksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $NotebooksTable extends Notebooks
    with TableInfo<$NotebooksTable, NotebookRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotebooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorIndexMeta =
      const VerificationMeta('colorIndex');
  @override
  late final GeneratedColumn<int> colorIndex = GeneratedColumn<int>(
      'color_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, colorIndex, sortOrder, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notebooks';
  @override
  VerificationContext validateIntegrity(Insertable<NotebookRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_index')) {
      context.handle(
          _colorIndexMeta,
          colorIndex.isAcceptableOrUnknown(
              data['color_index']!, _colorIndexMeta));
    } else if (isInserting) {
      context.missing(_colorIndexMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotebookRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotebookRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      colorIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color_index'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $NotebooksTable createAlias(String alias) {
    return $NotebooksTable(attachedDatabase, alias);
  }
}

class NotebookRow extends DataClass implements Insertable<NotebookRow> {
  final int id;
  final String name;
  final int colorIndex;
  final int sortOrder;
  final DateTime createdAt;
  const NotebookRow(
      {required this.id,
      required this.name,
      required this.colorIndex,
      required this.sortOrder,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color_index'] = Variable<int>(colorIndex);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  NotebooksCompanion toCompanion(bool nullToAbsent) {
    return NotebooksCompanion(
      id: Value(id),
      name: Value(name),
      colorIndex: Value(colorIndex),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory NotebookRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotebookRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorIndex: serializer.fromJson<int>(json['colorIndex']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'colorIndex': serializer.toJson<int>(colorIndex),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  NotebookRow copyWith(
          {int? id,
          String? name,
          int? colorIndex,
          int? sortOrder,
          DateTime? createdAt}) =>
      NotebookRow(
        id: id ?? this.id,
        name: name ?? this.name,
        colorIndex: colorIndex ?? this.colorIndex,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
      );
  NotebookRow copyWithCompanion(NotebooksCompanion data) {
    return NotebookRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorIndex:
          data.colorIndex.present ? data.colorIndex.value : this.colorIndex,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotebookRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, colorIndex, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotebookRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorIndex == this.colorIndex &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class NotebooksCompanion extends UpdateCompanion<NotebookRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> colorIndex;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const NotebooksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  NotebooksCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int colorIndex,
    required int sortOrder,
    required DateTime createdAt,
  })  : name = Value(name),
        colorIndex = Value(colorIndex),
        sortOrder = Value(sortOrder),
        createdAt = Value(createdAt);
  static Insertable<NotebookRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? colorIndex,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorIndex != null) 'color_index': colorIndex,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  NotebooksCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? colorIndex,
      Value<int>? sortOrder,
      Value<DateTime>? createdAt}) {
    return NotebooksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorIndex.present) {
      map['color_index'] = Variable<int>(colorIndex.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotebooksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, NoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _notebookIdMeta =
      const VerificationMeta('notebookId');
  @override
  late final GeneratedColumn<int> notebookId = GeneratedColumn<int>(
      'notebook_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
      'pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, notebookId, title, content, tags, pinned, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(Insertable<NoteRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('notebook_id')) {
      context.handle(
          _notebookIdMeta,
          notebookId.isAcceptableOrUnknown(
              data['notebook_id']!, _notebookIdMeta));
    } else if (isInserting) {
      context.missing(_notebookIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('pinned')) {
      context.handle(_pinnedMeta,
          pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      notebookId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}notebook_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      pinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pinned'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class NoteRow extends DataClass implements Insertable<NoteRow> {
  final int id;
  final int notebookId;
  final String title;
  final String content;
  final String tags;
  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;
  const NoteRow(
      {required this.id,
      required this.notebookId,
      required this.title,
      required this.content,
      required this.tags,
      required this.pinned,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['notebook_id'] = Variable<int>(notebookId);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    map['tags'] = Variable<String>(tags);
    map['pinned'] = Variable<bool>(pinned);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      notebookId: Value(notebookId),
      title: Value(title),
      content: Value(content),
      tags: Value(tags),
      pinned: Value(pinned),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory NoteRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteRow(
      id: serializer.fromJson<int>(json['id']),
      notebookId: serializer.fromJson<int>(json['notebookId']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      tags: serializer.fromJson<String>(json['tags']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'notebookId': serializer.toJson<int>(notebookId),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'tags': serializer.toJson<String>(tags),
      'pinned': serializer.toJson<bool>(pinned),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  NoteRow copyWith(
          {int? id,
          int? notebookId,
          String? title,
          String? content,
          String? tags,
          bool? pinned,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      NoteRow(
        id: id ?? this.id,
        notebookId: notebookId ?? this.notebookId,
        title: title ?? this.title,
        content: content ?? this.content,
        tags: tags ?? this.tags,
        pinned: pinned ?? this.pinned,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  NoteRow copyWithCompanion(NotesCompanion data) {
    return NoteRow(
      id: data.id.present ? data.id.value : this.id,
      notebookId:
          data.notebookId.present ? data.notebookId.value : this.notebookId,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      tags: data.tags.present ? data.tags.value : this.tags,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteRow(')
          ..write('id: $id, ')
          ..write('notebookId: $notebookId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('tags: $tags, ')
          ..write('pinned: $pinned, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, notebookId, title, content, tags, pinned, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteRow &&
          other.id == this.id &&
          other.notebookId == this.notebookId &&
          other.title == this.title &&
          other.content == this.content &&
          other.tags == this.tags &&
          other.pinned == this.pinned &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NotesCompanion extends UpdateCompanion<NoteRow> {
  final Value<int> id;
  final Value<int> notebookId;
  final Value<String> title;
  final Value<String> content;
  final Value<String> tags;
  final Value<bool> pinned;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.notebookId = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.tags = const Value.absent(),
    this.pinned = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  NotesCompanion.insert({
    this.id = const Value.absent(),
    required int notebookId,
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.tags = const Value.absent(),
    this.pinned = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : notebookId = Value(notebookId),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<NoteRow> custom({
    Expression<int>? id,
    Expression<int>? notebookId,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? tags,
    Expression<bool>? pinned,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (notebookId != null) 'notebook_id': notebookId,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (tags != null) 'tags': tags,
      if (pinned != null) 'pinned': pinned,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  NotesCompanion copyWith(
      {Value<int>? id,
      Value<int>? notebookId,
      Value<String>? title,
      Value<String>? content,
      Value<String>? tags,
      Value<bool>? pinned,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return NotesCompanion(
      id: id ?? this.id,
      notebookId: notebookId ?? this.notebookId,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      pinned: pinned ?? this.pinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (notebookId.present) {
      map['notebook_id'] = Variable<int>(notebookId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('notebookId: $notebookId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('tags: $tags, ')
          ..write('pinned: $pinned, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TodoItemsTable extends TodoItems
    with TableInfo<$TodoItemsTable, TodoItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodoItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<int> noteId = GeneratedColumn<int>(
      'note_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<bool> done = GeneratedColumn<bool>(
      'done', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("done" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, noteId, body, done, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todo_items';
  @override
  VerificationContext validateIntegrity(Insertable<TodoItemRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('note_id')) {
      context.handle(_noteIdMeta,
          noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta));
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('done')) {
      context.handle(
          _doneMeta, done.isAcceptableOrUnknown(data['done']!, _doneMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TodoItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TodoItemRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      noteId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}note_id'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      done: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}done'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $TodoItemsTable createAlias(String alias) {
    return $TodoItemsTable(attachedDatabase, alias);
  }
}

class TodoItemRow extends DataClass implements Insertable<TodoItemRow> {
  final int id;
  final int noteId;
  final String body;
  final bool done;
  final int sortOrder;
  const TodoItemRow(
      {required this.id,
      required this.noteId,
      required this.body,
      required this.done,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['note_id'] = Variable<int>(noteId);
    map['body'] = Variable<String>(body);
    map['done'] = Variable<bool>(done);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  TodoItemsCompanion toCompanion(bool nullToAbsent) {
    return TodoItemsCompanion(
      id: Value(id),
      noteId: Value(noteId),
      body: Value(body),
      done: Value(done),
      sortOrder: Value(sortOrder),
    );
  }

  factory TodoItemRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoItemRow(
      id: serializer.fromJson<int>(json['id']),
      noteId: serializer.fromJson<int>(json['noteId']),
      body: serializer.fromJson<String>(json['body']),
      done: serializer.fromJson<bool>(json['done']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'noteId': serializer.toJson<int>(noteId),
      'body': serializer.toJson<String>(body),
      'done': serializer.toJson<bool>(done),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  TodoItemRow copyWith(
          {int? id, int? noteId, String? body, bool? done, int? sortOrder}) =>
      TodoItemRow(
        id: id ?? this.id,
        noteId: noteId ?? this.noteId,
        body: body ?? this.body,
        done: done ?? this.done,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  TodoItemRow copyWithCompanion(TodoItemsCompanion data) {
    return TodoItemRow(
      id: data.id.present ? data.id.value : this.id,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      body: data.body.present ? data.body.value : this.body,
      done: data.done.present ? data.done.value : this.done,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TodoItemRow(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('body: $body, ')
          ..write('done: $done, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, noteId, body, done, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoItemRow &&
          other.id == this.id &&
          other.noteId == this.noteId &&
          other.body == this.body &&
          other.done == this.done &&
          other.sortOrder == this.sortOrder);
}

class TodoItemsCompanion extends UpdateCompanion<TodoItemRow> {
  final Value<int> id;
  final Value<int> noteId;
  final Value<String> body;
  final Value<bool> done;
  final Value<int> sortOrder;
  const TodoItemsCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.body = const Value.absent(),
    this.done = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  TodoItemsCompanion.insert({
    this.id = const Value.absent(),
    required int noteId,
    required String body,
    this.done = const Value.absent(),
    required int sortOrder,
  })  : noteId = Value(noteId),
        body = Value(body),
        sortOrder = Value(sortOrder);
  static Insertable<TodoItemRow> custom({
    Expression<int>? id,
    Expression<int>? noteId,
    Expression<String>? body,
    Expression<bool>? done,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (noteId != null) 'note_id': noteId,
      if (body != null) 'body': body,
      if (done != null) 'done': done,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  TodoItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? noteId,
      Value<String>? body,
      Value<bool>? done,
      Value<int>? sortOrder}) {
    return TodoItemsCompanion(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      body: body ?? this.body,
      done: done ?? this.done,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<int>(noteId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (done.present) {
      map['done'] = Variable<bool>(done.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodoItemsCompanion(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('body: $body, ')
          ..write('done: $done, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $ScheduleTemplatesTable extends ScheduleTemplates
    with TableInfo<$ScheduleTemplatesTable, ScheduleTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduleTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _colorIndexMeta =
      const VerificationMeta('colorIndex');
  @override
  late final GeneratedColumn<int> colorIndex = GeneratedColumn<int>(
      'color_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _rruleMeta = const VerificationMeta('rrule');
  @override
  late final GeneratedColumn<String> rrule = GeneratedColumn<String>(
      'rrule', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<int> startDate = GeneratedColumn<int>(
      'start_date', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<int> endDate = GeneratedColumn<int>(
      'end_date', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _exdatesMeta =
      const VerificationMeta('exdates');
  @override
  late final GeneratedColumn<String> exdates = GeneratedColumn<String>(
      'exdates', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _startMinutesMeta =
      const VerificationMeta('startMinutes');
  @override
  late final GeneratedColumn<int> startMinutes = GeneratedColumn<int>(
      'start_minutes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _durationMinutesMeta =
      const VerificationMeta('durationMinutes');
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
      'duration_minutes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _remindMinutesBeforeMeta =
      const VerificationMeta('remindMinutesBefore');
  @override
  late final GeneratedColumn<int> remindMinutesBefore = GeneratedColumn<int>(
      'remind_minutes_before', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _enabledMeta =
      const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
      'enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        description,
        colorIndex,
        rrule,
        startDate,
        endDate,
        exdates,
        startMinutes,
        durationMinutes,
        remindMinutesBefore,
        enabled,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedule_templates';
  @override
  VerificationContext validateIntegrity(
      Insertable<ScheduleTemplateRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('color_index')) {
      context.handle(
          _colorIndexMeta,
          colorIndex.isAcceptableOrUnknown(
              data['color_index']!, _colorIndexMeta));
    }
    if (data.containsKey('rrule')) {
      context.handle(
          _rruleMeta, rrule.isAcceptableOrUnknown(data['rrule']!, _rruleMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('exdates')) {
      context.handle(_exdatesMeta,
          exdates.isAcceptableOrUnknown(data['exdates']!, _exdatesMeta));
    }
    if (data.containsKey('start_minutes')) {
      context.handle(
          _startMinutesMeta,
          startMinutes.isAcceptableOrUnknown(
              data['start_minutes']!, _startMinutesMeta));
    } else if (isInserting) {
      context.missing(_startMinutesMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
          _durationMinutesMeta,
          durationMinutes.isAcceptableOrUnknown(
              data['duration_minutes']!, _durationMinutesMeta));
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    if (data.containsKey('remind_minutes_before')) {
      context.handle(
          _remindMinutesBeforeMeta,
          remindMinutesBefore.isAcceptableOrUnknown(
              data['remind_minutes_before']!, _remindMinutesBeforeMeta));
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta,
          enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduleTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduleTemplateRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      colorIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color_index'])!,
      rrule: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rrule']),
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_date']),
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_date']),
      exdates: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exdates'])!,
      startMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_minutes'])!,
      durationMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_minutes'])!,
      remindMinutesBefore: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}remind_minutes_before'])!,
      enabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ScheduleTemplatesTable createAlias(String alias) {
    return $ScheduleTemplatesTable(attachedDatabase, alias);
  }
}

class ScheduleTemplateRow extends DataClass
    implements Insertable<ScheduleTemplateRow> {
  final int id;
  final String title;
  final String description;
  final int colorIndex;
  final String? rrule;
  final int? startDate;
  final int? endDate;
  final String exdates;
  final int startMinutes;
  final int durationMinutes;
  final int remindMinutesBefore;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ScheduleTemplateRow(
      {required this.id,
      required this.title,
      required this.description,
      required this.colorIndex,
      this.rrule,
      this.startDate,
      this.endDate,
      required this.exdates,
      required this.startMinutes,
      required this.durationMinutes,
      required this.remindMinutesBefore,
      required this.enabled,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['color_index'] = Variable<int>(colorIndex);
    if (!nullToAbsent || rrule != null) {
      map['rrule'] = Variable<String>(rrule);
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<int>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<int>(endDate);
    }
    map['exdates'] = Variable<String>(exdates);
    map['start_minutes'] = Variable<int>(startMinutes);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['remind_minutes_before'] = Variable<int>(remindMinutesBefore);
    map['enabled'] = Variable<bool>(enabled);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ScheduleTemplatesCompanion toCompanion(bool nullToAbsent) {
    return ScheduleTemplatesCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      colorIndex: Value(colorIndex),
      rrule:
          rrule == null && nullToAbsent ? const Value.absent() : Value(rrule),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      exdates: Value(exdates),
      startMinutes: Value(startMinutes),
      durationMinutes: Value(durationMinutes),
      remindMinutesBefore: Value(remindMinutesBefore),
      enabled: Value(enabled),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ScheduleTemplateRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduleTemplateRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      colorIndex: serializer.fromJson<int>(json['colorIndex']),
      rrule: serializer.fromJson<String?>(json['rrule']),
      startDate: serializer.fromJson<int?>(json['startDate']),
      endDate: serializer.fromJson<int?>(json['endDate']),
      exdates: serializer.fromJson<String>(json['exdates']),
      startMinutes: serializer.fromJson<int>(json['startMinutes']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      remindMinutesBefore:
          serializer.fromJson<int>(json['remindMinutesBefore']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'colorIndex': serializer.toJson<int>(colorIndex),
      'rrule': serializer.toJson<String?>(rrule),
      'startDate': serializer.toJson<int?>(startDate),
      'endDate': serializer.toJson<int?>(endDate),
      'exdates': serializer.toJson<String>(exdates),
      'startMinutes': serializer.toJson<int>(startMinutes),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'remindMinutesBefore': serializer.toJson<int>(remindMinutesBefore),
      'enabled': serializer.toJson<bool>(enabled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ScheduleTemplateRow copyWith(
          {int? id,
          String? title,
          String? description,
          int? colorIndex,
          Value<String?> rrule = const Value.absent(),
          Value<int?> startDate = const Value.absent(),
          Value<int?> endDate = const Value.absent(),
          String? exdates,
          int? startMinutes,
          int? durationMinutes,
          int? remindMinutesBefore,
          bool? enabled,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      ScheduleTemplateRow(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        colorIndex: colorIndex ?? this.colorIndex,
        rrule: rrule.present ? rrule.value : this.rrule,
        startDate: startDate.present ? startDate.value : this.startDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        exdates: exdates ?? this.exdates,
        startMinutes: startMinutes ?? this.startMinutes,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        remindMinutesBefore: remindMinutesBefore ?? this.remindMinutesBefore,
        enabled: enabled ?? this.enabled,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ScheduleTemplateRow copyWithCompanion(ScheduleTemplatesCompanion data) {
    return ScheduleTemplateRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      colorIndex:
          data.colorIndex.present ? data.colorIndex.value : this.colorIndex,
      rrule: data.rrule.present ? data.rrule.value : this.rrule,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      exdates: data.exdates.present ? data.exdates.value : this.exdates,
      startMinutes: data.startMinutes.present
          ? data.startMinutes.value
          : this.startMinutes,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      remindMinutesBefore: data.remindMinutesBefore.present
          ? data.remindMinutesBefore.value
          : this.remindMinutesBefore,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleTemplateRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('rrule: $rrule, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('exdates: $exdates, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('remindMinutesBefore: $remindMinutesBefore, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      description,
      colorIndex,
      rrule,
      startDate,
      endDate,
      exdates,
      startMinutes,
      durationMinutes,
      remindMinutesBefore,
      enabled,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduleTemplateRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.colorIndex == this.colorIndex &&
          other.rrule == this.rrule &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.exdates == this.exdates &&
          other.startMinutes == this.startMinutes &&
          other.durationMinutes == this.durationMinutes &&
          other.remindMinutesBefore == this.remindMinutesBefore &&
          other.enabled == this.enabled &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ScheduleTemplatesCompanion extends UpdateCompanion<ScheduleTemplateRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> description;
  final Value<int> colorIndex;
  final Value<String?> rrule;
  final Value<int?> startDate;
  final Value<int?> endDate;
  final Value<String> exdates;
  final Value<int> startMinutes;
  final Value<int> durationMinutes;
  final Value<int> remindMinutesBefore;
  final Value<bool> enabled;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ScheduleTemplatesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.rrule = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.exdates = const Value.absent(),
    this.startMinutes = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.remindMinutesBefore = const Value.absent(),
    this.enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ScheduleTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.rrule = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.exdates = const Value.absent(),
    required int startMinutes,
    required int durationMinutes,
    this.remindMinutesBefore = const Value.absent(),
    this.enabled = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : title = Value(title),
        startMinutes = Value(startMinutes),
        durationMinutes = Value(durationMinutes),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ScheduleTemplateRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? colorIndex,
    Expression<String>? rrule,
    Expression<int>? startDate,
    Expression<int>? endDate,
    Expression<String>? exdates,
    Expression<int>? startMinutes,
    Expression<int>? durationMinutes,
    Expression<int>? remindMinutesBefore,
    Expression<bool>? enabled,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (colorIndex != null) 'color_index': colorIndex,
      if (rrule != null) 'rrule': rrule,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (exdates != null) 'exdates': exdates,
      if (startMinutes != null) 'start_minutes': startMinutes,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (remindMinutesBefore != null)
        'remind_minutes_before': remindMinutesBefore,
      if (enabled != null) 'enabled': enabled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ScheduleTemplatesCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String>? description,
      Value<int>? colorIndex,
      Value<String?>? rrule,
      Value<int?>? startDate,
      Value<int?>? endDate,
      Value<String>? exdates,
      Value<int>? startMinutes,
      Value<int>? durationMinutes,
      Value<int>? remindMinutesBefore,
      Value<bool>? enabled,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return ScheduleTemplatesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      colorIndex: colorIndex ?? this.colorIndex,
      rrule: rrule ?? this.rrule,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      exdates: exdates ?? this.exdates,
      startMinutes: startMinutes ?? this.startMinutes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      remindMinutesBefore: remindMinutesBefore ?? this.remindMinutesBefore,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (colorIndex.present) {
      map['color_index'] = Variable<int>(colorIndex.value);
    }
    if (rrule.present) {
      map['rrule'] = Variable<String>(rrule.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<int>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<int>(endDate.value);
    }
    if (exdates.present) {
      map['exdates'] = Variable<String>(exdates.value);
    }
    if (startMinutes.present) {
      map['start_minutes'] = Variable<int>(startMinutes.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (remindMinutesBefore.present) {
      map['remind_minutes_before'] = Variable<int>(remindMinutesBefore.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('rrule: $rrule, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('exdates: $exdates, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('remindMinutesBefore: $remindMinutesBefore, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ScheduleInstancesTable extends ScheduleInstances
    with TableInfo<$ScheduleInstancesTable, ScheduleInstanceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduleInstancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _templateIdMeta =
      const VerificationMeta('templateId');
  @override
  late final GeneratedColumn<int> templateId = GeneratedColumn<int>(
      'template_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _dateDayMeta =
      const VerificationMeta('dateDay');
  @override
  late final GeneratedColumn<int> dateDay = GeneratedColumn<int>(
      'date_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startMinutesMeta =
      const VerificationMeta('startMinutes');
  @override
  late final GeneratedColumn<int> startMinutes = GeneratedColumn<int>(
      'start_minutes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _durationMinutesMeta =
      const VerificationMeta('durationMinutes');
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
      'duration_minutes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _colorIndexMeta =
      const VerificationMeta('colorIndex');
  @override
  late final GeneratedColumn<int> colorIndex = GeneratedColumn<int>(
      'color_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
      'status', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _detachedMeta =
      const VerificationMeta('detached');
  @override
  late final GeneratedColumn<bool> detached = GeneratedColumn<bool>(
      'detached', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("detached" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _remindAtMeta =
      const VerificationMeta('remindAt');
  @override
  late final GeneratedColumn<DateTime> remindAt = GeneratedColumn<DateTime>(
      'remind_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _notifiedAtMeta =
      const VerificationMeta('notifiedAt');
  @override
  late final GeneratedColumn<DateTime> notifiedAt = GeneratedColumn<DateTime>(
      'notified_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        templateId,
        dateDay,
        startMinutes,
        durationMinutes,
        title,
        description,
        colorIndex,
        status,
        detached,
        remindAt,
        notifiedAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedule_instances';
  @override
  VerificationContext validateIntegrity(
      Insertable<ScheduleInstanceRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('template_id')) {
      context.handle(
          _templateIdMeta,
          templateId.isAcceptableOrUnknown(
              data['template_id']!, _templateIdMeta));
    }
    if (data.containsKey('date_day')) {
      context.handle(_dateDayMeta,
          dateDay.isAcceptableOrUnknown(data['date_day']!, _dateDayMeta));
    } else if (isInserting) {
      context.missing(_dateDayMeta);
    }
    if (data.containsKey('start_minutes')) {
      context.handle(
          _startMinutesMeta,
          startMinutes.isAcceptableOrUnknown(
              data['start_minutes']!, _startMinutesMeta));
    } else if (isInserting) {
      context.missing(_startMinutesMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
          _durationMinutesMeta,
          durationMinutes.isAcceptableOrUnknown(
              data['duration_minutes']!, _durationMinutesMeta));
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('color_index')) {
      context.handle(
          _colorIndexMeta,
          colorIndex.isAcceptableOrUnknown(
              data['color_index']!, _colorIndexMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('detached')) {
      context.handle(_detachedMeta,
          detached.isAcceptableOrUnknown(data['detached']!, _detachedMeta));
    }
    if (data.containsKey('remind_at')) {
      context.handle(_remindAtMeta,
          remindAt.isAcceptableOrUnknown(data['remind_at']!, _remindAtMeta));
    }
    if (data.containsKey('notified_at')) {
      context.handle(
          _notifiedAtMeta,
          notifiedAt.isAcceptableOrUnknown(
              data['notified_at']!, _notifiedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduleInstanceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduleInstanceRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      templateId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}template_id']),
      dateDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}date_day'])!,
      startMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_minutes'])!,
      durationMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_minutes'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      colorIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color_index'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!,
      detached: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}detached'])!,
      remindAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}remind_at']),
      notifiedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}notified_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ScheduleInstancesTable createAlias(String alias) {
    return $ScheduleInstancesTable(attachedDatabase, alias);
  }
}

class ScheduleInstanceRow extends DataClass
    implements Insertable<ScheduleInstanceRow> {
  final int id;
  final int? templateId;
  final int dateDay;
  final int startMinutes;
  final int durationMinutes;
  final String title;
  final String description;
  final int colorIndex;
  final int status;
  final bool detached;
  final DateTime? remindAt;
  final DateTime? notifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ScheduleInstanceRow(
      {required this.id,
      this.templateId,
      required this.dateDay,
      required this.startMinutes,
      required this.durationMinutes,
      required this.title,
      required this.description,
      required this.colorIndex,
      required this.status,
      required this.detached,
      this.remindAt,
      this.notifiedAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<int>(templateId);
    }
    map['date_day'] = Variable<int>(dateDay);
    map['start_minutes'] = Variable<int>(startMinutes);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['color_index'] = Variable<int>(colorIndex);
    map['status'] = Variable<int>(status);
    map['detached'] = Variable<bool>(detached);
    if (!nullToAbsent || remindAt != null) {
      map['remind_at'] = Variable<DateTime>(remindAt);
    }
    if (!nullToAbsent || notifiedAt != null) {
      map['notified_at'] = Variable<DateTime>(notifiedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ScheduleInstancesCompanion toCompanion(bool nullToAbsent) {
    return ScheduleInstancesCompanion(
      id: Value(id),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
      dateDay: Value(dateDay),
      startMinutes: Value(startMinutes),
      durationMinutes: Value(durationMinutes),
      title: Value(title),
      description: Value(description),
      colorIndex: Value(colorIndex),
      status: Value(status),
      detached: Value(detached),
      remindAt: remindAt == null && nullToAbsent
          ? const Value.absent()
          : Value(remindAt),
      notifiedAt: notifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(notifiedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ScheduleInstanceRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduleInstanceRow(
      id: serializer.fromJson<int>(json['id']),
      templateId: serializer.fromJson<int?>(json['templateId']),
      dateDay: serializer.fromJson<int>(json['dateDay']),
      startMinutes: serializer.fromJson<int>(json['startMinutes']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      colorIndex: serializer.fromJson<int>(json['colorIndex']),
      status: serializer.fromJson<int>(json['status']),
      detached: serializer.fromJson<bool>(json['detached']),
      remindAt: serializer.fromJson<DateTime?>(json['remindAt']),
      notifiedAt: serializer.fromJson<DateTime?>(json['notifiedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'templateId': serializer.toJson<int?>(templateId),
      'dateDay': serializer.toJson<int>(dateDay),
      'startMinutes': serializer.toJson<int>(startMinutes),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'colorIndex': serializer.toJson<int>(colorIndex),
      'status': serializer.toJson<int>(status),
      'detached': serializer.toJson<bool>(detached),
      'remindAt': serializer.toJson<DateTime?>(remindAt),
      'notifiedAt': serializer.toJson<DateTime?>(notifiedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ScheduleInstanceRow copyWith(
          {int? id,
          Value<int?> templateId = const Value.absent(),
          int? dateDay,
          int? startMinutes,
          int? durationMinutes,
          String? title,
          String? description,
          int? colorIndex,
          int? status,
          bool? detached,
          Value<DateTime?> remindAt = const Value.absent(),
          Value<DateTime?> notifiedAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      ScheduleInstanceRow(
        id: id ?? this.id,
        templateId: templateId.present ? templateId.value : this.templateId,
        dateDay: dateDay ?? this.dateDay,
        startMinutes: startMinutes ?? this.startMinutes,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        title: title ?? this.title,
        description: description ?? this.description,
        colorIndex: colorIndex ?? this.colorIndex,
        status: status ?? this.status,
        detached: detached ?? this.detached,
        remindAt: remindAt.present ? remindAt.value : this.remindAt,
        notifiedAt: notifiedAt.present ? notifiedAt.value : this.notifiedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ScheduleInstanceRow copyWithCompanion(ScheduleInstancesCompanion data) {
    return ScheduleInstanceRow(
      id: data.id.present ? data.id.value : this.id,
      templateId:
          data.templateId.present ? data.templateId.value : this.templateId,
      dateDay: data.dateDay.present ? data.dateDay.value : this.dateDay,
      startMinutes: data.startMinutes.present
          ? data.startMinutes.value
          : this.startMinutes,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      colorIndex:
          data.colorIndex.present ? data.colorIndex.value : this.colorIndex,
      status: data.status.present ? data.status.value : this.status,
      detached: data.detached.present ? data.detached.value : this.detached,
      remindAt: data.remindAt.present ? data.remindAt.value : this.remindAt,
      notifiedAt:
          data.notifiedAt.present ? data.notifiedAt.value : this.notifiedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleInstanceRow(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('dateDay: $dateDay, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('status: $status, ')
          ..write('detached: $detached, ')
          ..write('remindAt: $remindAt, ')
          ..write('notifiedAt: $notifiedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      templateId,
      dateDay,
      startMinutes,
      durationMinutes,
      title,
      description,
      colorIndex,
      status,
      detached,
      remindAt,
      notifiedAt,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduleInstanceRow &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.dateDay == this.dateDay &&
          other.startMinutes == this.startMinutes &&
          other.durationMinutes == this.durationMinutes &&
          other.title == this.title &&
          other.description == this.description &&
          other.colorIndex == this.colorIndex &&
          other.status == this.status &&
          other.detached == this.detached &&
          other.remindAt == this.remindAt &&
          other.notifiedAt == this.notifiedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ScheduleInstancesCompanion extends UpdateCompanion<ScheduleInstanceRow> {
  final Value<int> id;
  final Value<int?> templateId;
  final Value<int> dateDay;
  final Value<int> startMinutes;
  final Value<int> durationMinutes;
  final Value<String> title;
  final Value<String> description;
  final Value<int> colorIndex;
  final Value<int> status;
  final Value<bool> detached;
  final Value<DateTime?> remindAt;
  final Value<DateTime?> notifiedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ScheduleInstancesCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.dateDay = const Value.absent(),
    this.startMinutes = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.status = const Value.absent(),
    this.detached = const Value.absent(),
    this.remindAt = const Value.absent(),
    this.notifiedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ScheduleInstancesCompanion.insert({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    required int dateDay,
    required int startMinutes,
    required int durationMinutes,
    required String title,
    this.description = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.status = const Value.absent(),
    this.detached = const Value.absent(),
    this.remindAt = const Value.absent(),
    this.notifiedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : dateDay = Value(dateDay),
        startMinutes = Value(startMinutes),
        durationMinutes = Value(durationMinutes),
        title = Value(title),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ScheduleInstanceRow> custom({
    Expression<int>? id,
    Expression<int>? templateId,
    Expression<int>? dateDay,
    Expression<int>? startMinutes,
    Expression<int>? durationMinutes,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? colorIndex,
    Expression<int>? status,
    Expression<bool>? detached,
    Expression<DateTime>? remindAt,
    Expression<DateTime>? notifiedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (dateDay != null) 'date_day': dateDay,
      if (startMinutes != null) 'start_minutes': startMinutes,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (colorIndex != null) 'color_index': colorIndex,
      if (status != null) 'status': status,
      if (detached != null) 'detached': detached,
      if (remindAt != null) 'remind_at': remindAt,
      if (notifiedAt != null) 'notified_at': notifiedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ScheduleInstancesCompanion copyWith(
      {Value<int>? id,
      Value<int?>? templateId,
      Value<int>? dateDay,
      Value<int>? startMinutes,
      Value<int>? durationMinutes,
      Value<String>? title,
      Value<String>? description,
      Value<int>? colorIndex,
      Value<int>? status,
      Value<bool>? detached,
      Value<DateTime?>? remindAt,
      Value<DateTime?>? notifiedAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return ScheduleInstancesCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      dateDay: dateDay ?? this.dateDay,
      startMinutes: startMinutes ?? this.startMinutes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      title: title ?? this.title,
      description: description ?? this.description,
      colorIndex: colorIndex ?? this.colorIndex,
      status: status ?? this.status,
      detached: detached ?? this.detached,
      remindAt: remindAt ?? this.remindAt,
      notifiedAt: notifiedAt ?? this.notifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<int>(templateId.value);
    }
    if (dateDay.present) {
      map['date_day'] = Variable<int>(dateDay.value);
    }
    if (startMinutes.present) {
      map['start_minutes'] = Variable<int>(startMinutes.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (colorIndex.present) {
      map['color_index'] = Variable<int>(colorIndex.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (detached.present) {
      map['detached'] = Variable<bool>(detached.value);
    }
    if (remindAt.present) {
      map['remind_at'] = Variable<DateTime>(remindAt.value);
    }
    if (notifiedAt.present) {
      map['notified_at'] = Variable<DateTime>(notifiedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleInstancesCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('dateDay: $dateDay, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('status: $status, ')
          ..write('detached: $detached, ')
          ..write('remindAt: $remindAt, ')
          ..write('notifiedAt: $notifiedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DraftsTable extends Drafts with TableInfo<$DraftsTable, DraftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _ownerTypeMeta =
      const VerificationMeta('ownerType');
  @override
  late final GeneratedColumn<int> ownerType = GeneratedColumn<int>(
      'owner_type', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<int> ownerId = GeneratedColumn<int>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, ownerType, ownerId, payload, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drafts';
  @override
  VerificationContext validateIntegrity(Insertable<DraftRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('owner_type')) {
      context.handle(_ownerTypeMeta,
          ownerType.isAcceptableOrUnknown(data['owner_type']!, _ownerTypeMeta));
    } else if (isInserting) {
      context.missing(_ownerTypeMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DraftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DraftRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      ownerType: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}owner_type'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}owner_id'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DraftsTable createAlias(String alias) {
    return $DraftsTable(attachedDatabase, alias);
  }
}

class DraftRow extends DataClass implements Insertable<DraftRow> {
  final int id;
  final int ownerType;
  final int ownerId;
  final String payload;
  final DateTime updatedAt;
  const DraftRow(
      {required this.id,
      required this.ownerType,
      required this.ownerId,
      required this.payload,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['owner_type'] = Variable<int>(ownerType);
    map['owner_id'] = Variable<int>(ownerId);
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DraftsCompanion toCompanion(bool nullToAbsent) {
    return DraftsCompanion(
      id: Value(id),
      ownerType: Value(ownerType),
      ownerId: Value(ownerId),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
    );
  }

  factory DraftRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DraftRow(
      id: serializer.fromJson<int>(json['id']),
      ownerType: serializer.fromJson<int>(json['ownerType']),
      ownerId: serializer.fromJson<int>(json['ownerId']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ownerType': serializer.toJson<int>(ownerType),
      'ownerId': serializer.toJson<int>(ownerId),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DraftRow copyWith(
          {int? id,
          int? ownerType,
          int? ownerId,
          String? payload,
          DateTime? updatedAt}) =>
      DraftRow(
        id: id ?? this.id,
        ownerType: ownerType ?? this.ownerType,
        ownerId: ownerId ?? this.ownerId,
        payload: payload ?? this.payload,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DraftRow copyWithCompanion(DraftsCompanion data) {
    return DraftRow(
      id: data.id.present ? data.id.value : this.id,
      ownerType: data.ownerType.present ? data.ownerType.value : this.ownerType,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DraftRow(')
          ..write('id: $id, ')
          ..write('ownerType: $ownerType, ')
          ..write('ownerId: $ownerId, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ownerType, ownerId, payload, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DraftRow &&
          other.id == this.id &&
          other.ownerType == this.ownerType &&
          other.ownerId == this.ownerId &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt);
}

class DraftsCompanion extends UpdateCompanion<DraftRow> {
  final Value<int> id;
  final Value<int> ownerType;
  final Value<int> ownerId;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  const DraftsCompanion({
    this.id = const Value.absent(),
    this.ownerType = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DraftsCompanion.insert({
    this.id = const Value.absent(),
    required int ownerType,
    required int ownerId,
    required String payload,
    required DateTime updatedAt,
  })  : ownerType = Value(ownerType),
        ownerId = Value(ownerId),
        payload = Value(payload),
        updatedAt = Value(updatedAt);
  static Insertable<DraftRow> custom({
    Expression<int>? id,
    Expression<int>? ownerType,
    Expression<int>? ownerId,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerType != null) 'owner_type': ownerType,
      if (ownerId != null) 'owner_id': ownerId,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DraftsCompanion copyWith(
      {Value<int>? id,
      Value<int>? ownerType,
      Value<int>? ownerId,
      Value<String>? payload,
      Value<DateTime>? updatedAt}) {
    return DraftsCompanion(
      id: id ?? this.id,
      ownerType: ownerType ?? this.ownerType,
      ownerId: ownerId ?? this.ownerId,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ownerType.present) {
      map['owner_type'] = Variable<int>(ownerType.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<int>(ownerId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DraftsCompanion(')
          ..write('id: $id, ')
          ..write('ownerType: $ownerType, ')
          ..write('ownerId: $ownerId, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<SettingRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory SettingRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) => SettingRow(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DiariesTable diaries = $DiariesTable(this);
  late final $MoodsTable moods = $MoodsTable(this);
  late final $MediaItemsTable mediaItems = $MediaItemsTable(this);
  late final $DiaryNotebooksTable diaryNotebooks = $DiaryNotebooksTable(this);
  late final $NotebooksTable notebooks = $NotebooksTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $TodoItemsTable todoItems = $TodoItemsTable(this);
  late final $ScheduleTemplatesTable scheduleTemplates =
      $ScheduleTemplatesTable(this);
  late final $ScheduleInstancesTable scheduleInstances =
      $ScheduleInstancesTable(this);
  late final $DraftsTable drafts = $DraftsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        diaries,
        moods,
        mediaItems,
        diaryNotebooks,
        notebooks,
        notes,
        todoItems,
        scheduleTemplates,
        scheduleInstances,
        drafts,
        settings
      ];
}

typedef $$DiariesTableCreateCompanionBuilder = DiariesCompanion Function({
  Value<int> id,
  required int dateDay,
  Value<String> title,
  Value<String> content,
  Value<String> tags,
  Value<int?> notebookId,
  Value<int?> moodId,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$DiariesTableUpdateCompanionBuilder = DiariesCompanion Function({
  Value<int> id,
  Value<int> dateDay,
  Value<String> title,
  Value<String> content,
  Value<String> tags,
  Value<int?> notebookId,
  Value<int?> moodId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$DiariesTableFilterComposer
    extends Composer<_$AppDatabase, $DiariesTable> {
  $$DiariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dateDay => $composableBuilder(
      column: $table.dateDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get notebookId => $composableBuilder(
      column: $table.notebookId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get moodId => $composableBuilder(
      column: $table.moodId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DiariesTableOrderingComposer
    extends Composer<_$AppDatabase, $DiariesTable> {
  $$DiariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dateDay => $composableBuilder(
      column: $table.dateDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get notebookId => $composableBuilder(
      column: $table.notebookId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get moodId => $composableBuilder(
      column: $table.moodId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DiariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiariesTable> {
  $$DiariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dateDay =>
      $composableBuilder(column: $table.dateDay, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<int> get notebookId => $composableBuilder(
      column: $table.notebookId, builder: (column) => column);

  GeneratedColumn<int> get moodId =>
      $composableBuilder(column: $table.moodId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DiariesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DiariesTable,
    DiariesRow,
    $$DiariesTableFilterComposer,
    $$DiariesTableOrderingComposer,
    $$DiariesTableAnnotationComposer,
    $$DiariesTableCreateCompanionBuilder,
    $$DiariesTableUpdateCompanionBuilder,
    (DiariesRow, BaseReferences<_$AppDatabase, $DiariesTable, DiariesRow>),
    DiariesRow,
    PrefetchHooks Function()> {
  $$DiariesTableTableManager(_$AppDatabase db, $DiariesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> dateDay = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<int?> notebookId = const Value.absent(),
            Value<int?> moodId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              DiariesCompanion(
            id: id,
            dateDay: dateDay,
            title: title,
            content: content,
            tags: tags,
            notebookId: notebookId,
            moodId: moodId,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int dateDay,
            Value<String> title = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<int?> notebookId = const Value.absent(),
            Value<int?> moodId = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              DiariesCompanion.insert(
            id: id,
            dateDay: dateDay,
            title: title,
            content: content,
            tags: tags,
            notebookId: notebookId,
            moodId: moodId,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$DiariesTable, DiariesRow>(table),
                    BaseReferences<_$AppDatabase, $DiariesTable, DiariesRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DiariesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DiariesTable,
    DiariesRow,
    $$DiariesTableFilterComposer,
    $$DiariesTableOrderingComposer,
    $$DiariesTableAnnotationComposer,
    $$DiariesTableCreateCompanionBuilder,
    $$DiariesTableUpdateCompanionBuilder,
    (DiariesRow, BaseReferences<_$AppDatabase, $DiariesTable, DiariesRow>),
    DiariesRow,
    PrefetchHooks Function()>;
typedef $$MoodsTableCreateCompanionBuilder = MoodsCompanion Function({
  Value<int> id,
  required String name,
  required double hue,
  required bool isPreset,
  required int sortOrder,
});
typedef $$MoodsTableUpdateCompanionBuilder = MoodsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<double> hue,
  Value<bool> isPreset,
  Value<int> sortOrder,
});

class $$MoodsTableFilterComposer extends Composer<_$AppDatabase, $MoodsTable> {
  $$MoodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get hue => $composableBuilder(
      column: $table.hue, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPreset => $composableBuilder(
      column: $table.isPreset, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$MoodsTableOrderingComposer
    extends Composer<_$AppDatabase, $MoodsTable> {
  $$MoodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get hue => $composableBuilder(
      column: $table.hue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPreset => $composableBuilder(
      column: $table.isPreset, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$MoodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MoodsTable> {
  $$MoodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get hue =>
      $composableBuilder(column: $table.hue, builder: (column) => column);

  GeneratedColumn<bool> get isPreset =>
      $composableBuilder(column: $table.isPreset, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$MoodsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MoodsTable,
    MoodsRow,
    $$MoodsTableFilterComposer,
    $$MoodsTableOrderingComposer,
    $$MoodsTableAnnotationComposer,
    $$MoodsTableCreateCompanionBuilder,
    $$MoodsTableUpdateCompanionBuilder,
    (MoodsRow, BaseReferences<_$AppDatabase, $MoodsTable, MoodsRow>),
    MoodsRow,
    PrefetchHooks Function()> {
  $$MoodsTableTableManager(_$AppDatabase db, $MoodsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> hue = const Value.absent(),
            Value<bool> isPreset = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
          }) =>
              MoodsCompanion(
            id: id,
            name: name,
            hue: hue,
            isPreset: isPreset,
            sortOrder: sortOrder,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required double hue,
            required bool isPreset,
            required int sortOrder,
          }) =>
              MoodsCompanion.insert(
            id: id,
            name: name,
            hue: hue,
            isPreset: isPreset,
            sortOrder: sortOrder,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$MoodsTable, MoodsRow>(table),
                    BaseReferences<_$AppDatabase, $MoodsTable, MoodsRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MoodsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MoodsTable,
    MoodsRow,
    $$MoodsTableFilterComposer,
    $$MoodsTableOrderingComposer,
    $$MoodsTableAnnotationComposer,
    $$MoodsTableCreateCompanionBuilder,
    $$MoodsTableUpdateCompanionBuilder,
    (MoodsRow, BaseReferences<_$AppDatabase, $MoodsTable, MoodsRow>),
    MoodsRow,
    PrefetchHooks Function()>;
typedef $$MediaItemsTableCreateCompanionBuilder = MediaItemsCompanion Function({
  Value<int> id,
  required int ownerType,
  required int ownerId,
  required int kind,
  Value<String?> coverPath,
  Value<String?> videoPath,
  Value<String?> thumbPath,
  required int sortOrder,
  Value<int?> width,
  Value<int?> height,
  Value<int?> durationMs,
  required DateTime createdAt,
});
typedef $$MediaItemsTableUpdateCompanionBuilder = MediaItemsCompanion Function({
  Value<int> id,
  Value<int> ownerType,
  Value<int> ownerId,
  Value<int> kind,
  Value<String?> coverPath,
  Value<String?> videoPath,
  Value<String?> thumbPath,
  Value<int> sortOrder,
  Value<int?> width,
  Value<int?> height,
  Value<int?> durationMs,
  Value<DateTime> createdAt,
});

class $$MediaItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ownerType => $composableBuilder(
      column: $table.ownerType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverPath => $composableBuilder(
      column: $table.coverPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get videoPath => $composableBuilder(
      column: $table.videoPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbPath => $composableBuilder(
      column: $table.thumbPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$MediaItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ownerType => $composableBuilder(
      column: $table.ownerType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverPath => $composableBuilder(
      column: $table.coverPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get videoPath => $composableBuilder(
      column: $table.videoPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbPath => $composableBuilder(
      column: $table.thumbPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$MediaItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get ownerType =>
      $composableBuilder(column: $table.ownerType, builder: (column) => column);

  GeneratedColumn<int> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumn<String> get videoPath =>
      $composableBuilder(column: $table.videoPath, builder: (column) => column);

  GeneratedColumn<String> get thumbPath =>
      $composableBuilder(column: $table.thumbPath, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MediaItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MediaItemsTable,
    MediaItemRow,
    $$MediaItemsTableFilterComposer,
    $$MediaItemsTableOrderingComposer,
    $$MediaItemsTableAnnotationComposer,
    $$MediaItemsTableCreateCompanionBuilder,
    $$MediaItemsTableUpdateCompanionBuilder,
    (
      MediaItemRow,
      BaseReferences<_$AppDatabase, $MediaItemsTable, MediaItemRow>
    ),
    MediaItemRow,
    PrefetchHooks Function()> {
  $$MediaItemsTableTableManager(_$AppDatabase db, $MediaItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> ownerType = const Value.absent(),
            Value<int> ownerId = const Value.absent(),
            Value<int> kind = const Value.absent(),
            Value<String?> coverPath = const Value.absent(),
            Value<String?> videoPath = const Value.absent(),
            Value<String?> thumbPath = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<int?> durationMs = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              MediaItemsCompanion(
            id: id,
            ownerType: ownerType,
            ownerId: ownerId,
            kind: kind,
            coverPath: coverPath,
            videoPath: videoPath,
            thumbPath: thumbPath,
            sortOrder: sortOrder,
            width: width,
            height: height,
            durationMs: durationMs,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int ownerType,
            required int ownerId,
            required int kind,
            Value<String?> coverPath = const Value.absent(),
            Value<String?> videoPath = const Value.absent(),
            Value<String?> thumbPath = const Value.absent(),
            required int sortOrder,
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<int?> durationMs = const Value.absent(),
            required DateTime createdAt,
          }) =>
              MediaItemsCompanion.insert(
            id: id,
            ownerType: ownerType,
            ownerId: ownerId,
            kind: kind,
            coverPath: coverPath,
            videoPath: videoPath,
            thumbPath: thumbPath,
            sortOrder: sortOrder,
            width: width,
            height: height,
            durationMs: durationMs,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$MediaItemsTable, MediaItemRow>(table),
                    BaseReferences<_$AppDatabase, $MediaItemsTable,
                        MediaItemRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MediaItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MediaItemsTable,
    MediaItemRow,
    $$MediaItemsTableFilterComposer,
    $$MediaItemsTableOrderingComposer,
    $$MediaItemsTableAnnotationComposer,
    $$MediaItemsTableCreateCompanionBuilder,
    $$MediaItemsTableUpdateCompanionBuilder,
    (
      MediaItemRow,
      BaseReferences<_$AppDatabase, $MediaItemsTable, MediaItemRow>
    ),
    MediaItemRow,
    PrefetchHooks Function()>;
typedef $$DiaryNotebooksTableCreateCompanionBuilder = DiaryNotebooksCompanion
    Function({
  Value<int> id,
  required String name,
  Value<int> colorIndex,
  required int sortOrder,
  required DateTime createdAt,
});
typedef $$DiaryNotebooksTableUpdateCompanionBuilder = DiaryNotebooksCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<int> colorIndex,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
});

class $$DiaryNotebooksTableFilterComposer
    extends Composer<_$AppDatabase, $DiaryNotebooksTable> {
  $$DiaryNotebooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get colorIndex => $composableBuilder(
      column: $table.colorIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$DiaryNotebooksTableOrderingComposer
    extends Composer<_$AppDatabase, $DiaryNotebooksTable> {
  $$DiaryNotebooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get colorIndex => $composableBuilder(
      column: $table.colorIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$DiaryNotebooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiaryNotebooksTable> {
  $$DiaryNotebooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get colorIndex => $composableBuilder(
      column: $table.colorIndex, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DiaryNotebooksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DiaryNotebooksTable,
    DiaryNotebookRow,
    $$DiaryNotebooksTableFilterComposer,
    $$DiaryNotebooksTableOrderingComposer,
    $$DiaryNotebooksTableAnnotationComposer,
    $$DiaryNotebooksTableCreateCompanionBuilder,
    $$DiaryNotebooksTableUpdateCompanionBuilder,
    (
      DiaryNotebookRow,
      BaseReferences<_$AppDatabase, $DiaryNotebooksTable, DiaryNotebookRow>
    ),
    DiaryNotebookRow,
    PrefetchHooks Function()> {
  $$DiaryNotebooksTableTableManager(
      _$AppDatabase db, $DiaryNotebooksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiaryNotebooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiaryNotebooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiaryNotebooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> colorIndex = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              DiaryNotebooksCompanion(
            id: id,
            name: name,
            colorIndex: colorIndex,
            sortOrder: sortOrder,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<int> colorIndex = const Value.absent(),
            required int sortOrder,
            required DateTime createdAt,
          }) =>
              DiaryNotebooksCompanion.insert(
            id: id,
            name: name,
            colorIndex: colorIndex,
            sortOrder: sortOrder,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$DiaryNotebooksTable, DiaryNotebookRow>(table),
                    BaseReferences<_$AppDatabase, $DiaryNotebooksTable,
                        DiaryNotebookRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DiaryNotebooksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DiaryNotebooksTable,
    DiaryNotebookRow,
    $$DiaryNotebooksTableFilterComposer,
    $$DiaryNotebooksTableOrderingComposer,
    $$DiaryNotebooksTableAnnotationComposer,
    $$DiaryNotebooksTableCreateCompanionBuilder,
    $$DiaryNotebooksTableUpdateCompanionBuilder,
    (
      DiaryNotebookRow,
      BaseReferences<_$AppDatabase, $DiaryNotebooksTable, DiaryNotebookRow>
    ),
    DiaryNotebookRow,
    PrefetchHooks Function()>;
typedef $$NotebooksTableCreateCompanionBuilder = NotebooksCompanion Function({
  Value<int> id,
  required String name,
  required int colorIndex,
  required int sortOrder,
  required DateTime createdAt,
});
typedef $$NotebooksTableUpdateCompanionBuilder = NotebooksCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> colorIndex,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
});

class $$NotebooksTableFilterComposer
    extends Composer<_$AppDatabase, $NotebooksTable> {
  $$NotebooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get colorIndex => $composableBuilder(
      column: $table.colorIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$NotebooksTableOrderingComposer
    extends Composer<_$AppDatabase, $NotebooksTable> {
  $$NotebooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get colorIndex => $composableBuilder(
      column: $table.colorIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$NotebooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotebooksTable> {
  $$NotebooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get colorIndex => $composableBuilder(
      column: $table.colorIndex, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$NotebooksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotebooksTable,
    NotebookRow,
    $$NotebooksTableFilterComposer,
    $$NotebooksTableOrderingComposer,
    $$NotebooksTableAnnotationComposer,
    $$NotebooksTableCreateCompanionBuilder,
    $$NotebooksTableUpdateCompanionBuilder,
    (NotebookRow, BaseReferences<_$AppDatabase, $NotebooksTable, NotebookRow>),
    NotebookRow,
    PrefetchHooks Function()> {
  $$NotebooksTableTableManager(_$AppDatabase db, $NotebooksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotebooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotebooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotebooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> colorIndex = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              NotebooksCompanion(
            id: id,
            name: name,
            colorIndex: colorIndex,
            sortOrder: sortOrder,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required int colorIndex,
            required int sortOrder,
            required DateTime createdAt,
          }) =>
              NotebooksCompanion.insert(
            id: id,
            name: name,
            colorIndex: colorIndex,
            sortOrder: sortOrder,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$NotebooksTable, NotebookRow>(table),
                    BaseReferences<_$AppDatabase, $NotebooksTable, NotebookRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NotebooksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NotebooksTable,
    NotebookRow,
    $$NotebooksTableFilterComposer,
    $$NotebooksTableOrderingComposer,
    $$NotebooksTableAnnotationComposer,
    $$NotebooksTableCreateCompanionBuilder,
    $$NotebooksTableUpdateCompanionBuilder,
    (NotebookRow, BaseReferences<_$AppDatabase, $NotebooksTable, NotebookRow>),
    NotebookRow,
    PrefetchHooks Function()>;
typedef $$NotesTableCreateCompanionBuilder = NotesCompanion Function({
  Value<int> id,
  required int notebookId,
  Value<String> title,
  Value<String> content,
  Value<String> tags,
  Value<bool> pinned,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$NotesTableUpdateCompanionBuilder = NotesCompanion Function({
  Value<int> id,
  Value<int> notebookId,
  Value<String> title,
  Value<String> content,
  Value<String> tags,
  Value<bool> pinned,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get notebookId => $composableBuilder(
      column: $table.notebookId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pinned => $composableBuilder(
      column: $table.pinned, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get notebookId => $composableBuilder(
      column: $table.notebookId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pinned => $composableBuilder(
      column: $table.pinned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get notebookId => $composableBuilder(
      column: $table.notebookId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$NotesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotesTable,
    NoteRow,
    $$NotesTableFilterComposer,
    $$NotesTableOrderingComposer,
    $$NotesTableAnnotationComposer,
    $$NotesTableCreateCompanionBuilder,
    $$NotesTableUpdateCompanionBuilder,
    (NoteRow, BaseReferences<_$AppDatabase, $NotesTable, NoteRow>),
    NoteRow,
    PrefetchHooks Function()> {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> notebookId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<bool> pinned = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              NotesCompanion(
            id: id,
            notebookId: notebookId,
            title: title,
            content: content,
            tags: tags,
            pinned: pinned,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int notebookId,
            Value<String> title = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<bool> pinned = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              NotesCompanion.insert(
            id: id,
            notebookId: notebookId,
            title: title,
            content: content,
            tags: tags,
            pinned: pinned,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$NotesTable, NoteRow>(table),
                    BaseReferences<_$AppDatabase, $NotesTable, NoteRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NotesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NotesTable,
    NoteRow,
    $$NotesTableFilterComposer,
    $$NotesTableOrderingComposer,
    $$NotesTableAnnotationComposer,
    $$NotesTableCreateCompanionBuilder,
    $$NotesTableUpdateCompanionBuilder,
    (NoteRow, BaseReferences<_$AppDatabase, $NotesTable, NoteRow>),
    NoteRow,
    PrefetchHooks Function()>;
typedef $$TodoItemsTableCreateCompanionBuilder = TodoItemsCompanion Function({
  Value<int> id,
  required int noteId,
  required String body,
  Value<bool> done,
  required int sortOrder,
});
typedef $$TodoItemsTableUpdateCompanionBuilder = TodoItemsCompanion Function({
  Value<int> id,
  Value<int> noteId,
  Value<String> body,
  Value<bool> done,
  Value<int> sortOrder,
});

class $$TodoItemsTableFilterComposer
    extends Composer<_$AppDatabase, $TodoItemsTable> {
  $$TodoItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get noteId => $composableBuilder(
      column: $table.noteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get done => $composableBuilder(
      column: $table.done, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$TodoItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $TodoItemsTable> {
  $$TodoItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get noteId => $composableBuilder(
      column: $table.noteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get done => $composableBuilder(
      column: $table.done, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$TodoItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TodoItemsTable> {
  $$TodoItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$TodoItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TodoItemsTable,
    TodoItemRow,
    $$TodoItemsTableFilterComposer,
    $$TodoItemsTableOrderingComposer,
    $$TodoItemsTableAnnotationComposer,
    $$TodoItemsTableCreateCompanionBuilder,
    $$TodoItemsTableUpdateCompanionBuilder,
    (TodoItemRow, BaseReferences<_$AppDatabase, $TodoItemsTable, TodoItemRow>),
    TodoItemRow,
    PrefetchHooks Function()> {
  $$TodoItemsTableTableManager(_$AppDatabase db, $TodoItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodoItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodoItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodoItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> noteId = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<bool> done = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
          }) =>
              TodoItemsCompanion(
            id: id,
            noteId: noteId,
            body: body,
            done: done,
            sortOrder: sortOrder,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int noteId,
            required String body,
            Value<bool> done = const Value.absent(),
            required int sortOrder,
          }) =>
              TodoItemsCompanion.insert(
            id: id,
            noteId: noteId,
            body: body,
            done: done,
            sortOrder: sortOrder,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$TodoItemsTable, TodoItemRow>(table),
                    BaseReferences<_$AppDatabase, $TodoItemsTable, TodoItemRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TodoItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TodoItemsTable,
    TodoItemRow,
    $$TodoItemsTableFilterComposer,
    $$TodoItemsTableOrderingComposer,
    $$TodoItemsTableAnnotationComposer,
    $$TodoItemsTableCreateCompanionBuilder,
    $$TodoItemsTableUpdateCompanionBuilder,
    (TodoItemRow, BaseReferences<_$AppDatabase, $TodoItemsTable, TodoItemRow>),
    TodoItemRow,
    PrefetchHooks Function()>;
typedef $$ScheduleTemplatesTableCreateCompanionBuilder
    = ScheduleTemplatesCompanion Function({
  Value<int> id,
  required String title,
  Value<String> description,
  Value<int> colorIndex,
  Value<String?> rrule,
  Value<int?> startDate,
  Value<int?> endDate,
  Value<String> exdates,
  required int startMinutes,
  required int durationMinutes,
  Value<int> remindMinutesBefore,
  Value<bool> enabled,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$ScheduleTemplatesTableUpdateCompanionBuilder
    = ScheduleTemplatesCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> description,
  Value<int> colorIndex,
  Value<String?> rrule,
  Value<int?> startDate,
  Value<int?> endDate,
  Value<String> exdates,
  Value<int> startMinutes,
  Value<int> durationMinutes,
  Value<int> remindMinutesBefore,
  Value<bool> enabled,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$ScheduleTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduleTemplatesTable> {
  $$ScheduleTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get colorIndex => $composableBuilder(
      column: $table.colorIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rrule => $composableBuilder(
      column: $table.rrule, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exdates => $composableBuilder(
      column: $table.exdates, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startMinutes => $composableBuilder(
      column: $table.startMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get remindMinutesBefore => $composableBuilder(
      column: $table.remindMinutesBefore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ScheduleTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduleTemplatesTable> {
  $$ScheduleTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get colorIndex => $composableBuilder(
      column: $table.colorIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rrule => $composableBuilder(
      column: $table.rrule, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exdates => $composableBuilder(
      column: $table.exdates, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startMinutes => $composableBuilder(
      column: $table.startMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get remindMinutesBefore => $composableBuilder(
      column: $table.remindMinutesBefore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ScheduleTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduleTemplatesTable> {
  $$ScheduleTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get colorIndex => $composableBuilder(
      column: $table.colorIndex, builder: (column) => column);

  GeneratedColumn<String> get rrule =>
      $composableBuilder(column: $table.rrule, builder: (column) => column);

  GeneratedColumn<int> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get exdates =>
      $composableBuilder(column: $table.exdates, builder: (column) => column);

  GeneratedColumn<int> get startMinutes => $composableBuilder(
      column: $table.startMinutes, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes, builder: (column) => column);

  GeneratedColumn<int> get remindMinutesBefore => $composableBuilder(
      column: $table.remindMinutesBefore, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ScheduleTemplatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ScheduleTemplatesTable,
    ScheduleTemplateRow,
    $$ScheduleTemplatesTableFilterComposer,
    $$ScheduleTemplatesTableOrderingComposer,
    $$ScheduleTemplatesTableAnnotationComposer,
    $$ScheduleTemplatesTableCreateCompanionBuilder,
    $$ScheduleTemplatesTableUpdateCompanionBuilder,
    (
      ScheduleTemplateRow,
      BaseReferences<_$AppDatabase, $ScheduleTemplatesTable,
          ScheduleTemplateRow>
    ),
    ScheduleTemplateRow,
    PrefetchHooks Function()> {
  $$ScheduleTemplatesTableTableManager(
      _$AppDatabase db, $ScheduleTemplatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduleTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduleTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScheduleTemplatesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<int> colorIndex = const Value.absent(),
            Value<String?> rrule = const Value.absent(),
            Value<int?> startDate = const Value.absent(),
            Value<int?> endDate = const Value.absent(),
            Value<String> exdates = const Value.absent(),
            Value<int> startMinutes = const Value.absent(),
            Value<int> durationMinutes = const Value.absent(),
            Value<int> remindMinutesBefore = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ScheduleTemplatesCompanion(
            id: id,
            title: title,
            description: description,
            colorIndex: colorIndex,
            rrule: rrule,
            startDate: startDate,
            endDate: endDate,
            exdates: exdates,
            startMinutes: startMinutes,
            durationMinutes: durationMinutes,
            remindMinutesBefore: remindMinutesBefore,
            enabled: enabled,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            Value<String> description = const Value.absent(),
            Value<int> colorIndex = const Value.absent(),
            Value<String?> rrule = const Value.absent(),
            Value<int?> startDate = const Value.absent(),
            Value<int?> endDate = const Value.absent(),
            Value<String> exdates = const Value.absent(),
            required int startMinutes,
            required int durationMinutes,
            Value<int> remindMinutesBefore = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              ScheduleTemplatesCompanion.insert(
            id: id,
            title: title,
            description: description,
            colorIndex: colorIndex,
            rrule: rrule,
            startDate: startDate,
            endDate: endDate,
            exdates: exdates,
            startMinutes: startMinutes,
            durationMinutes: durationMinutes,
            remindMinutesBefore: remindMinutesBefore,
            enabled: enabled,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ScheduleTemplatesTable, ScheduleTemplateRow>(
                        table),
                    BaseReferences<_$AppDatabase, $ScheduleTemplatesTable,
                        ScheduleTemplateRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ScheduleTemplatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ScheduleTemplatesTable,
    ScheduleTemplateRow,
    $$ScheduleTemplatesTableFilterComposer,
    $$ScheduleTemplatesTableOrderingComposer,
    $$ScheduleTemplatesTableAnnotationComposer,
    $$ScheduleTemplatesTableCreateCompanionBuilder,
    $$ScheduleTemplatesTableUpdateCompanionBuilder,
    (
      ScheduleTemplateRow,
      BaseReferences<_$AppDatabase, $ScheduleTemplatesTable,
          ScheduleTemplateRow>
    ),
    ScheduleTemplateRow,
    PrefetchHooks Function()>;
typedef $$ScheduleInstancesTableCreateCompanionBuilder
    = ScheduleInstancesCompanion Function({
  Value<int> id,
  Value<int?> templateId,
  required int dateDay,
  required int startMinutes,
  required int durationMinutes,
  required String title,
  Value<String> description,
  Value<int> colorIndex,
  Value<int> status,
  Value<bool> detached,
  Value<DateTime?> remindAt,
  Value<DateTime?> notifiedAt,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$ScheduleInstancesTableUpdateCompanionBuilder
    = ScheduleInstancesCompanion Function({
  Value<int> id,
  Value<int?> templateId,
  Value<int> dateDay,
  Value<int> startMinutes,
  Value<int> durationMinutes,
  Value<String> title,
  Value<String> description,
  Value<int> colorIndex,
  Value<int> status,
  Value<bool> detached,
  Value<DateTime?> remindAt,
  Value<DateTime?> notifiedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$ScheduleInstancesTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduleInstancesTable> {
  $$ScheduleInstancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get templateId => $composableBuilder(
      column: $table.templateId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dateDay => $composableBuilder(
      column: $table.dateDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startMinutes => $composableBuilder(
      column: $table.startMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get colorIndex => $composableBuilder(
      column: $table.colorIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get detached => $composableBuilder(
      column: $table.detached, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get remindAt => $composableBuilder(
      column: $table.remindAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get notifiedAt => $composableBuilder(
      column: $table.notifiedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ScheduleInstancesTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduleInstancesTable> {
  $$ScheduleInstancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get templateId => $composableBuilder(
      column: $table.templateId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dateDay => $composableBuilder(
      column: $table.dateDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startMinutes => $composableBuilder(
      column: $table.startMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get colorIndex => $composableBuilder(
      column: $table.colorIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get detached => $composableBuilder(
      column: $table.detached, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get remindAt => $composableBuilder(
      column: $table.remindAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get notifiedAt => $composableBuilder(
      column: $table.notifiedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ScheduleInstancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduleInstancesTable> {
  $$ScheduleInstancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get templateId => $composableBuilder(
      column: $table.templateId, builder: (column) => column);

  GeneratedColumn<int> get dateDay =>
      $composableBuilder(column: $table.dateDay, builder: (column) => column);

  GeneratedColumn<int> get startMinutes => $composableBuilder(
      column: $table.startMinutes, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get colorIndex => $composableBuilder(
      column: $table.colorIndex, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get detached =>
      $composableBuilder(column: $table.detached, builder: (column) => column);

  GeneratedColumn<DateTime> get remindAt =>
      $composableBuilder(column: $table.remindAt, builder: (column) => column);

  GeneratedColumn<DateTime> get notifiedAt => $composableBuilder(
      column: $table.notifiedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ScheduleInstancesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ScheduleInstancesTable,
    ScheduleInstanceRow,
    $$ScheduleInstancesTableFilterComposer,
    $$ScheduleInstancesTableOrderingComposer,
    $$ScheduleInstancesTableAnnotationComposer,
    $$ScheduleInstancesTableCreateCompanionBuilder,
    $$ScheduleInstancesTableUpdateCompanionBuilder,
    (
      ScheduleInstanceRow,
      BaseReferences<_$AppDatabase, $ScheduleInstancesTable,
          ScheduleInstanceRow>
    ),
    ScheduleInstanceRow,
    PrefetchHooks Function()> {
  $$ScheduleInstancesTableTableManager(
      _$AppDatabase db, $ScheduleInstancesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduleInstancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduleInstancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScheduleInstancesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> templateId = const Value.absent(),
            Value<int> dateDay = const Value.absent(),
            Value<int> startMinutes = const Value.absent(),
            Value<int> durationMinutes = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<int> colorIndex = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<bool> detached = const Value.absent(),
            Value<DateTime?> remindAt = const Value.absent(),
            Value<DateTime?> notifiedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ScheduleInstancesCompanion(
            id: id,
            templateId: templateId,
            dateDay: dateDay,
            startMinutes: startMinutes,
            durationMinutes: durationMinutes,
            title: title,
            description: description,
            colorIndex: colorIndex,
            status: status,
            detached: detached,
            remindAt: remindAt,
            notifiedAt: notifiedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> templateId = const Value.absent(),
            required int dateDay,
            required int startMinutes,
            required int durationMinutes,
            required String title,
            Value<String> description = const Value.absent(),
            Value<int> colorIndex = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<bool> detached = const Value.absent(),
            Value<DateTime?> remindAt = const Value.absent(),
            Value<DateTime?> notifiedAt = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              ScheduleInstancesCompanion.insert(
            id: id,
            templateId: templateId,
            dateDay: dateDay,
            startMinutes: startMinutes,
            durationMinutes: durationMinutes,
            title: title,
            description: description,
            colorIndex: colorIndex,
            status: status,
            detached: detached,
            remindAt: remindAt,
            notifiedAt: notifiedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ScheduleInstancesTable, ScheduleInstanceRow>(
                        table),
                    BaseReferences<_$AppDatabase, $ScheduleInstancesTable,
                        ScheduleInstanceRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ScheduleInstancesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ScheduleInstancesTable,
    ScheduleInstanceRow,
    $$ScheduleInstancesTableFilterComposer,
    $$ScheduleInstancesTableOrderingComposer,
    $$ScheduleInstancesTableAnnotationComposer,
    $$ScheduleInstancesTableCreateCompanionBuilder,
    $$ScheduleInstancesTableUpdateCompanionBuilder,
    (
      ScheduleInstanceRow,
      BaseReferences<_$AppDatabase, $ScheduleInstancesTable,
          ScheduleInstanceRow>
    ),
    ScheduleInstanceRow,
    PrefetchHooks Function()>;
typedef $$DraftsTableCreateCompanionBuilder = DraftsCompanion Function({
  Value<int> id,
  required int ownerType,
  required int ownerId,
  required String payload,
  required DateTime updatedAt,
});
typedef $$DraftsTableUpdateCompanionBuilder = DraftsCompanion Function({
  Value<int> id,
  Value<int> ownerType,
  Value<int> ownerId,
  Value<String> payload,
  Value<DateTime> updatedAt,
});

class $$DraftsTableFilterComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ownerType => $composableBuilder(
      column: $table.ownerType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ownerType => $composableBuilder(
      column: $table.ownerType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get ownerType =>
      $composableBuilder(column: $table.ownerType, builder: (column) => column);

  GeneratedColumn<int> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DraftsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DraftsTable,
    DraftRow,
    $$DraftsTableFilterComposer,
    $$DraftsTableOrderingComposer,
    $$DraftsTableAnnotationComposer,
    $$DraftsTableCreateCompanionBuilder,
    $$DraftsTableUpdateCompanionBuilder,
    (DraftRow, BaseReferences<_$AppDatabase, $DraftsTable, DraftRow>),
    DraftRow,
    PrefetchHooks Function()> {
  $$DraftsTableTableManager(_$AppDatabase db, $DraftsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> ownerType = const Value.absent(),
            Value<int> ownerId = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              DraftsCompanion(
            id: id,
            ownerType: ownerType,
            ownerId: ownerId,
            payload: payload,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int ownerType,
            required int ownerId,
            required String payload,
            required DateTime updatedAt,
          }) =>
              DraftsCompanion.insert(
            id: id,
            ownerType: ownerType,
            ownerId: ownerId,
            payload: payload,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$DraftsTable, DraftRow>(table),
                    BaseReferences<_$AppDatabase, $DraftsTable, DraftRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DraftsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DraftsTable,
    DraftRow,
    $$DraftsTableFilterComposer,
    $$DraftsTableOrderingComposer,
    $$DraftsTableAnnotationComposer,
    $$DraftsTableCreateCompanionBuilder,
    $$DraftsTableUpdateCompanionBuilder,
    (DraftRow, BaseReferences<_$AppDatabase, $DraftsTable, DraftRow>),
    DraftRow,
    PrefetchHooks Function()>;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    SettingRow,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
    SettingRow,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SettingsTable, SettingRow>(table),
                    BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTable,
    SettingRow,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
    SettingRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DiariesTableTableManager get diaries =>
      $$DiariesTableTableManager(_db, _db.diaries);
  $$MoodsTableTableManager get moods =>
      $$MoodsTableTableManager(_db, _db.moods);
  $$MediaItemsTableTableManager get mediaItems =>
      $$MediaItemsTableTableManager(_db, _db.mediaItems);
  $$DiaryNotebooksTableTableManager get diaryNotebooks =>
      $$DiaryNotebooksTableTableManager(_db, _db.diaryNotebooks);
  $$NotebooksTableTableManager get notebooks =>
      $$NotebooksTableTableManager(_db, _db.notebooks);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$TodoItemsTableTableManager get todoItems =>
      $$TodoItemsTableTableManager(_db, _db.todoItems);
  $$ScheduleTemplatesTableTableManager get scheduleTemplates =>
      $$ScheduleTemplatesTableTableManager(_db, _db.scheduleTemplates);
  $$ScheduleInstancesTableTableManager get scheduleInstances =>
      $$ScheduleInstancesTableTableManager(_db, _db.scheduleInstances);
  $$DraftsTableTableManager get drafts =>
      $$DraftsTableTableManager(_db, _db.drafts);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
