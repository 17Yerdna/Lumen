// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $BibleVersesTable extends BibleVerses
    with TableInfo<$BibleVersesTable, BibleVerse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BibleVersesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canonOrderMeta = const VerificationMeta(
    'canonOrder',
  );
  @override
  late final GeneratedColumn<int> canonOrder = GeneratedColumn<int>(
    'canon_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookCodeMeta = const VerificationMeta(
    'bookCode',
  );
  @override
  late final GeneratedColumn<String> bookCode = GeneratedColumn<String>(
    'book_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verseMeta = const VerificationMeta('verse');
  @override
  late final GeneratedColumn<int> verse = GeneratedColumn<int>(
    'verse',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endVerseMeta = const VerificationMeta(
    'endVerse',
  );
  @override
  late final GeneratedColumn<int> endVerse = GeneratedColumn<int>(
    'end_verse',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    canonOrder,
    bookCode,
    chapter,
    verse,
    endVerse,
    reference,
    body,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bible_verses';
  @override
  VerificationContext validateIntegrity(
    Insertable<BibleVerse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('canon_order')) {
      context.handle(
        _canonOrderMeta,
        canonOrder.isAcceptableOrUnknown(data['canon_order']!, _canonOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_canonOrderMeta);
    }
    if (data.containsKey('book_code')) {
      context.handle(
        _bookCodeMeta,
        bookCode.isAcceptableOrUnknown(data['book_code']!, _bookCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_bookCodeMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('verse')) {
      context.handle(
        _verseMeta,
        verse.isAcceptableOrUnknown(data['verse']!, _verseMeta),
      );
    } else if (isInserting) {
      context.missing(_verseMeta);
    }
    if (data.containsKey('end_verse')) {
      context.handle(
        _endVerseMeta,
        endVerse.isAcceptableOrUnknown(data['end_verse']!, _endVerseMeta),
      );
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    } else if (isInserting) {
      context.missing(_referenceMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BibleVerse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BibleVerse(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      canonOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}canon_order'],
      )!,
      bookCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_code'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      )!,
      verse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}verse'],
      )!,
      endVerse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_verse'],
      ),
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
    );
  }

  @override
  $BibleVersesTable createAlias(String alias) {
    return $BibleVersesTable(attachedDatabase, alias);
  }
}

class BibleVerse extends DataClass implements Insertable<BibleVerse> {
  final String id;
  final int canonOrder;
  final String bookCode;
  final int chapter;
  final int verse;
  final int? endVerse;
  final String reference;
  final String body;
  const BibleVerse({
    required this.id,
    required this.canonOrder,
    required this.bookCode,
    required this.chapter,
    required this.verse,
    this.endVerse,
    required this.reference,
    required this.body,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['canon_order'] = Variable<int>(canonOrder);
    map['book_code'] = Variable<String>(bookCode);
    map['chapter'] = Variable<int>(chapter);
    map['verse'] = Variable<int>(verse);
    if (!nullToAbsent || endVerse != null) {
      map['end_verse'] = Variable<int>(endVerse);
    }
    map['reference'] = Variable<String>(reference);
    map['body'] = Variable<String>(body);
    return map;
  }

  BibleVersesCompanion toCompanion(bool nullToAbsent) {
    return BibleVersesCompanion(
      id: Value(id),
      canonOrder: Value(canonOrder),
      bookCode: Value(bookCode),
      chapter: Value(chapter),
      verse: Value(verse),
      endVerse: endVerse == null && nullToAbsent
          ? const Value.absent()
          : Value(endVerse),
      reference: Value(reference),
      body: Value(body),
    );
  }

  factory BibleVerse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BibleVerse(
      id: serializer.fromJson<String>(json['id']),
      canonOrder: serializer.fromJson<int>(json['canonOrder']),
      bookCode: serializer.fromJson<String>(json['bookCode']),
      chapter: serializer.fromJson<int>(json['chapter']),
      verse: serializer.fromJson<int>(json['verse']),
      endVerse: serializer.fromJson<int?>(json['endVerse']),
      reference: serializer.fromJson<String>(json['reference']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'canonOrder': serializer.toJson<int>(canonOrder),
      'bookCode': serializer.toJson<String>(bookCode),
      'chapter': serializer.toJson<int>(chapter),
      'verse': serializer.toJson<int>(verse),
      'endVerse': serializer.toJson<int?>(endVerse),
      'reference': serializer.toJson<String>(reference),
      'body': serializer.toJson<String>(body),
    };
  }

  BibleVerse copyWith({
    String? id,
    int? canonOrder,
    String? bookCode,
    int? chapter,
    int? verse,
    Value<int?> endVerse = const Value.absent(),
    String? reference,
    String? body,
  }) => BibleVerse(
    id: id ?? this.id,
    canonOrder: canonOrder ?? this.canonOrder,
    bookCode: bookCode ?? this.bookCode,
    chapter: chapter ?? this.chapter,
    verse: verse ?? this.verse,
    endVerse: endVerse.present ? endVerse.value : this.endVerse,
    reference: reference ?? this.reference,
    body: body ?? this.body,
  );
  BibleVerse copyWithCompanion(BibleVersesCompanion data) {
    return BibleVerse(
      id: data.id.present ? data.id.value : this.id,
      canonOrder: data.canonOrder.present
          ? data.canonOrder.value
          : this.canonOrder,
      bookCode: data.bookCode.present ? data.bookCode.value : this.bookCode,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      verse: data.verse.present ? data.verse.value : this.verse,
      endVerse: data.endVerse.present ? data.endVerse.value : this.endVerse,
      reference: data.reference.present ? data.reference.value : this.reference,
      body: data.body.present ? data.body.value : this.body,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BibleVerse(')
          ..write('id: $id, ')
          ..write('canonOrder: $canonOrder, ')
          ..write('bookCode: $bookCode, ')
          ..write('chapter: $chapter, ')
          ..write('verse: $verse, ')
          ..write('endVerse: $endVerse, ')
          ..write('reference: $reference, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    canonOrder,
    bookCode,
    chapter,
    verse,
    endVerse,
    reference,
    body,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BibleVerse &&
          other.id == this.id &&
          other.canonOrder == this.canonOrder &&
          other.bookCode == this.bookCode &&
          other.chapter == this.chapter &&
          other.verse == this.verse &&
          other.endVerse == this.endVerse &&
          other.reference == this.reference &&
          other.body == this.body);
}

class BibleVersesCompanion extends UpdateCompanion<BibleVerse> {
  final Value<String> id;
  final Value<int> canonOrder;
  final Value<String> bookCode;
  final Value<int> chapter;
  final Value<int> verse;
  final Value<int?> endVerse;
  final Value<String> reference;
  final Value<String> body;
  final Value<int> rowid;
  const BibleVersesCompanion({
    this.id = const Value.absent(),
    this.canonOrder = const Value.absent(),
    this.bookCode = const Value.absent(),
    this.chapter = const Value.absent(),
    this.verse = const Value.absent(),
    this.endVerse = const Value.absent(),
    this.reference = const Value.absent(),
    this.body = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BibleVersesCompanion.insert({
    required String id,
    required int canonOrder,
    required String bookCode,
    required int chapter,
    required int verse,
    this.endVerse = const Value.absent(),
    required String reference,
    required String body,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       canonOrder = Value(canonOrder),
       bookCode = Value(bookCode),
       chapter = Value(chapter),
       verse = Value(verse),
       reference = Value(reference),
       body = Value(body);
  static Insertable<BibleVerse> custom({
    Expression<String>? id,
    Expression<int>? canonOrder,
    Expression<String>? bookCode,
    Expression<int>? chapter,
    Expression<int>? verse,
    Expression<int>? endVerse,
    Expression<String>? reference,
    Expression<String>? body,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (canonOrder != null) 'canon_order': canonOrder,
      if (bookCode != null) 'book_code': bookCode,
      if (chapter != null) 'chapter': chapter,
      if (verse != null) 'verse': verse,
      if (endVerse != null) 'end_verse': endVerse,
      if (reference != null) 'reference': reference,
      if (body != null) 'body': body,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BibleVersesCompanion copyWith({
    Value<String>? id,
    Value<int>? canonOrder,
    Value<String>? bookCode,
    Value<int>? chapter,
    Value<int>? verse,
    Value<int?>? endVerse,
    Value<String>? reference,
    Value<String>? body,
    Value<int>? rowid,
  }) {
    return BibleVersesCompanion(
      id: id ?? this.id,
      canonOrder: canonOrder ?? this.canonOrder,
      bookCode: bookCode ?? this.bookCode,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      endVerse: endVerse ?? this.endVerse,
      reference: reference ?? this.reference,
      body: body ?? this.body,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (canonOrder.present) {
      map['canon_order'] = Variable<int>(canonOrder.value);
    }
    if (bookCode.present) {
      map['book_code'] = Variable<String>(bookCode.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (verse.present) {
      map['verse'] = Variable<int>(verse.value);
    }
    if (endVerse.present) {
      map['end_verse'] = Variable<int>(endVerse.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BibleVersesCompanion(')
          ..write('id: $id, ')
          ..write('canonOrder: $canonOrder, ')
          ..write('bookCode: $bookCode, ')
          ..write('chapter: $chapter, ')
          ..write('verse: $verse, ')
          ..write('endVerse: $endVerse, ')
          ..write('reference: $reference, ')
          ..write('body: $body, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
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

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
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
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
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

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
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
    return (StringBuffer('AppSettingsCompanion(')
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
  late final $BibleVersesTable bibleVerses = $BibleVersesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    bibleVerses,
    appSettings,
  ];
}

typedef $$BibleVersesTableCreateCompanionBuilder =
    BibleVersesCompanion Function({
      required String id,
      required int canonOrder,
      required String bookCode,
      required int chapter,
      required int verse,
      Value<int?> endVerse,
      required String reference,
      required String body,
      Value<int> rowid,
    });
typedef $$BibleVersesTableUpdateCompanionBuilder =
    BibleVersesCompanion Function({
      Value<String> id,
      Value<int> canonOrder,
      Value<String> bookCode,
      Value<int> chapter,
      Value<int> verse,
      Value<int?> endVerse,
      Value<String> reference,
      Value<String> body,
      Value<int> rowid,
    });

class $$BibleVersesTableFilterComposer
    extends Composer<_$AppDatabase, $BibleVersesTable> {
  $$BibleVersesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get canonOrder => $composableBuilder(
    column: $table.canonOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookCode => $composableBuilder(
    column: $table.bookCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get verse => $composableBuilder(
    column: $table.verse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endVerse => $composableBuilder(
    column: $table.endVerse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BibleVersesTableOrderingComposer
    extends Composer<_$AppDatabase, $BibleVersesTable> {
  $$BibleVersesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get canonOrder => $composableBuilder(
    column: $table.canonOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookCode => $composableBuilder(
    column: $table.bookCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get verse => $composableBuilder(
    column: $table.verse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endVerse => $composableBuilder(
    column: $table.endVerse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BibleVersesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BibleVersesTable> {
  $$BibleVersesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get canonOrder => $composableBuilder(
    column: $table.canonOrder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bookCode =>
      $composableBuilder(column: $table.bookCode, builder: (column) => column);

  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<int> get verse =>
      $composableBuilder(column: $table.verse, builder: (column) => column);

  GeneratedColumn<int> get endVerse =>
      $composableBuilder(column: $table.endVerse, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);
}

class $$BibleVersesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BibleVersesTable,
          BibleVerse,
          $$BibleVersesTableFilterComposer,
          $$BibleVersesTableOrderingComposer,
          $$BibleVersesTableAnnotationComposer,
          $$BibleVersesTableCreateCompanionBuilder,
          $$BibleVersesTableUpdateCompanionBuilder,
          (
            BibleVerse,
            BaseReferences<_$AppDatabase, $BibleVersesTable, BibleVerse>,
          ),
          BibleVerse,
          PrefetchHooks Function()
        > {
  $$BibleVersesTableTableManager(_$AppDatabase db, $BibleVersesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BibleVersesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BibleVersesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BibleVersesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> canonOrder = const Value.absent(),
                Value<String> bookCode = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<int> verse = const Value.absent(),
                Value<int?> endVerse = const Value.absent(),
                Value<String> reference = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BibleVersesCompanion(
                id: id,
                canonOrder: canonOrder,
                bookCode: bookCode,
                chapter: chapter,
                verse: verse,
                endVerse: endVerse,
                reference: reference,
                body: body,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int canonOrder,
                required String bookCode,
                required int chapter,
                required int verse,
                Value<int?> endVerse = const Value.absent(),
                required String reference,
                required String body,
                Value<int> rowid = const Value.absent(),
              }) => BibleVersesCompanion.insert(
                id: id,
                canonOrder: canonOrder,
                bookCode: bookCode,
                chapter: chapter,
                verse: verse,
                endVerse: endVerse,
                reference: reference,
                body: body,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BibleVersesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BibleVersesTable,
      BibleVerse,
      $$BibleVersesTableFilterComposer,
      $$BibleVersesTableOrderingComposer,
      $$BibleVersesTableAnnotationComposer,
      $$BibleVersesTableCreateCompanionBuilder,
      $$BibleVersesTableUpdateCompanionBuilder,
      (
        BibleVerse,
        BaseReferences<_$AppDatabase, $BibleVersesTable, BibleVerse>,
      ),
      BibleVerse,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
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

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BibleVersesTableTableManager get bibleVerses =>
      $$BibleVersesTableTableManager(_db, _db.bibleVerses);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
