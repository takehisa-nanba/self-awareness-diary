// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDiaryRecordCollection on Isar {
  IsarCollection<DiaryRecord> get diaryRecords => this.collection();
}

const DiaryRecordSchema = CollectionSchema(
  name: r'DiaryRecord',
  id: 1446996613889110507,
  properties: {
    r'aiAnalysisReason': PropertySchema(
      id: 0,
      name: r'aiAnalysisReason',
      type: IsarType.string,
    ),
    r'aiStabilityScore': PropertySchema(
      id: 1,
      name: r'aiStabilityScore',
      type: IsarType.long,
    ),
    r'eventText': PropertySchema(
      id: 2,
      name: r'eventText',
      type: IsarType.string,
    ),
    r'isGapLarge': PropertySchema(
      id: 3,
      name: r'isGapLarge',
      type: IsarType.bool,
    ),
    r'location': PropertySchema(
      id: 4,
      name: r'location',
      type: IsarType.string,
    ),
    r'moodScore': PropertySchema(
      id: 5,
      name: r'moodScore',
      type: IsarType.long,
    ),
    r'moodTags': PropertySchema(
      id: 6,
      name: r'moodTags',
      type: IsarType.stringList,
    ),
    r'recordDate': PropertySchema(
      id: 7,
      name: r'recordDate',
      type: IsarType.dateTime,
    ),
    r'recordId': PropertySchema(
      id: 8,
      name: r'recordId',
      type: IsarType.string,
    ),
    r'selfAnalysis': PropertySchema(
      id: 9,
      name: r'selfAnalysis',
      type: IsarType.string,
    ),
    r'timeString': PropertySchema(
      id: 10,
      name: r'timeString',
      type: IsarType.string,
    ),
    r'weather': PropertySchema(
      id: 11,
      name: r'weather',
      type: IsarType.string,
    )
  },
  estimateSize: _diaryRecordEstimateSize,
  serialize: _diaryRecordSerialize,
  deserialize: _diaryRecordDeserialize,
  deserializeProp: _diaryRecordDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'recordId': IndexSchema(
      id: 907839981883940929,
      name: r'recordId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'recordId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _diaryRecordGetId,
  getLinks: _diaryRecordGetLinks,
  attach: _diaryRecordAttach,
  version: '3.1.0+1',
);

int _diaryRecordEstimateSize(
  DiaryRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.aiAnalysisReason;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.eventText.length * 3;
  {
    final value = object.location;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.moodTags.length * 3;
  {
    for (var i = 0; i < object.moodTags.length; i++) {
      final value = object.moodTags[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.recordId.length * 3;
  {
    final value = object.selfAnalysis;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.timeString.length * 3;
  {
    final value = object.weather;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _diaryRecordSerialize(
  DiaryRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.aiAnalysisReason);
  writer.writeLong(offsets[1], object.aiStabilityScore);
  writer.writeString(offsets[2], object.eventText);
  writer.writeBool(offsets[3], object.isGapLarge);
  writer.writeString(offsets[4], object.location);
  writer.writeLong(offsets[5], object.moodScore);
  writer.writeStringList(offsets[6], object.moodTags);
  writer.writeDateTime(offsets[7], object.recordDate);
  writer.writeString(offsets[8], object.recordId);
  writer.writeString(offsets[9], object.selfAnalysis);
  writer.writeString(offsets[10], object.timeString);
  writer.writeString(offsets[11], object.weather);
}

DiaryRecord _diaryRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DiaryRecord(
    aiAnalysisReason: reader.readStringOrNull(offsets[0]),
    aiStabilityScore: reader.readLongOrNull(offsets[1]),
    eventText: reader.readString(offsets[2]),
    isarId: id,
    location: reader.readStringOrNull(offsets[4]),
    moodScore: reader.readLong(offsets[5]),
    moodTags: reader.readStringList(offsets[6]) ?? [],
    recordDate: reader.readDateTime(offsets[7]),
    recordId: reader.readString(offsets[8]),
    selfAnalysis: reader.readStringOrNull(offsets[9]),
    weather: reader.readStringOrNull(offsets[11]),
  );
  return object;
}

P _diaryRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readStringList(offset) ?? []) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _diaryRecordGetId(DiaryRecord object) {
  return object.isarId ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _diaryRecordGetLinks(DiaryRecord object) {
  return [];
}

void _diaryRecordAttach(
    IsarCollection<dynamic> col, Id id, DiaryRecord object) {
  object.isarId = id;
}

extension DiaryRecordByIndex on IsarCollection<DiaryRecord> {
  Future<DiaryRecord?> getByRecordId(String recordId) {
    return getByIndex(r'recordId', [recordId]);
  }

  DiaryRecord? getByRecordIdSync(String recordId) {
    return getByIndexSync(r'recordId', [recordId]);
  }

  Future<bool> deleteByRecordId(String recordId) {
    return deleteByIndex(r'recordId', [recordId]);
  }

  bool deleteByRecordIdSync(String recordId) {
    return deleteByIndexSync(r'recordId', [recordId]);
  }

  Future<List<DiaryRecord?>> getAllByRecordId(List<String> recordIdValues) {
    final values = recordIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'recordId', values);
  }

  List<DiaryRecord?> getAllByRecordIdSync(List<String> recordIdValues) {
    final values = recordIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'recordId', values);
  }

  Future<int> deleteAllByRecordId(List<String> recordIdValues) {
    final values = recordIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'recordId', values);
  }

  int deleteAllByRecordIdSync(List<String> recordIdValues) {
    final values = recordIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'recordId', values);
  }

  Future<Id> putByRecordId(DiaryRecord object) {
    return putByIndex(r'recordId', object);
  }

  Id putByRecordIdSync(DiaryRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'recordId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByRecordId(List<DiaryRecord> objects) {
    return putAllByIndex(r'recordId', objects);
  }

  List<Id> putAllByRecordIdSync(List<DiaryRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'recordId', objects, saveLinks: saveLinks);
  }
}

extension DiaryRecordQueryWhereSort
    on QueryBuilder<DiaryRecord, DiaryRecord, QWhere> {
  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DiaryRecordQueryWhere
    on QueryBuilder<DiaryRecord, DiaryRecord, QWhereClause> {
  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> isarIdNotEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> isarIdGreaterThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> isarIdLessThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> recordIdEqualTo(
      String recordId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'recordId',
        value: [recordId],
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> recordIdNotEqualTo(
      String recordId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'recordId',
              lower: [],
              upper: [recordId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'recordId',
              lower: [recordId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'recordId',
              lower: [recordId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'recordId',
              lower: [],
              upper: [recordId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension DiaryRecordQueryFilter
    on QueryBuilder<DiaryRecord, DiaryRecord, QFilterCondition> {
  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      aiAnalysisReasonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'aiAnalysisReason',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      aiAnalysisReasonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'aiAnalysisReason',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      aiAnalysisReasonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiAnalysisReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      aiAnalysisReasonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'aiAnalysisReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      aiAnalysisReasonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'aiAnalysisReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      aiAnalysisReasonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'aiAnalysisReason',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      aiAnalysisReasonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'aiAnalysisReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      aiAnalysisReasonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'aiAnalysisReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      aiAnalysisReasonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'aiAnalysisReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      aiAnalysisReasonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'aiAnalysisReason',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      aiAnalysisReasonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiAnalysisReason',
        value: '',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      aiAnalysisReasonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'aiAnalysisReason',
        value: '',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      aiStabilityScoreIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'aiStabilityScore',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      aiStabilityScoreIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'aiStabilityScore',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      aiStabilityScoreEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiStabilityScore',
        value: value,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      aiStabilityScoreGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'aiStabilityScore',
        value: value,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      aiStabilityScoreLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'aiStabilityScore',
        value: value,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      aiStabilityScoreBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'aiStabilityScore',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      eventTextEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      eventTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'eventText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      eventTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'eventText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      eventTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'eventText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      eventTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'eventText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      eventTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'eventText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      eventTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'eventText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      eventTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'eventText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      eventTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventText',
        value: '',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      eventTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'eventText',
        value: '',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      isGapLargeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isGapLarge',
        value: value,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> isarIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isarId',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      isarIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isarId',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> isarIdEqualTo(
      Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      isarIdGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> isarIdLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> isarIdBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      locationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'location',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      locationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'location',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> locationEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      locationGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      locationLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> locationBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'location',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      locationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      locationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      locationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> locationMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'location',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      locationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'location',
        value: '',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      locationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'location',
        value: '',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      moodScoreEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'moodScore',
        value: value,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      moodScoreGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'moodScore',
        value: value,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      moodScoreLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'moodScore',
        value: value,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      moodScoreBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'moodScore',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      moodTagsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'moodTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      moodTagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'moodTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      moodTagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'moodTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      moodTagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'moodTags',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      moodTagsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'moodTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      moodTagsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'moodTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      moodTagsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'moodTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      moodTagsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'moodTags',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      moodTagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'moodTags',
        value: '',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      moodTagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'moodTags',
        value: '',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      moodTagsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'moodTags',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      moodTagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'moodTags',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      moodTagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'moodTags',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      moodTagsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'moodTags',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      moodTagsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'moodTags',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      moodTagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'moodTags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      recordDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recordDate',
        value: value,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      recordDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recordDate',
        value: value,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      recordDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recordDate',
        value: value,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      recordDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recordDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> recordIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recordId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      recordIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recordId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      recordIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recordId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> recordIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recordId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      recordIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'recordId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      recordIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'recordId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      recordIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'recordId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> recordIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'recordId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      recordIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recordId',
        value: '',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      recordIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'recordId',
        value: '',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      selfAnalysisIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'selfAnalysis',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      selfAnalysisIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'selfAnalysis',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      selfAnalysisEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selfAnalysis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      selfAnalysisGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'selfAnalysis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      selfAnalysisLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'selfAnalysis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      selfAnalysisBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'selfAnalysis',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      selfAnalysisStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'selfAnalysis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      selfAnalysisEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'selfAnalysis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      selfAnalysisContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'selfAnalysis',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      selfAnalysisMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'selfAnalysis',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      selfAnalysisIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selfAnalysis',
        value: '',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      selfAnalysisIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'selfAnalysis',
        value: '',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      timeStringEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      timeStringGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timeString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      timeStringLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timeString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      timeStringBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timeString',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      timeStringStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'timeString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      timeStringEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'timeString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      timeStringContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'timeString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      timeStringMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'timeString',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      timeStringIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeString',
        value: '',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      timeStringIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'timeString',
        value: '',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      weatherIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'weather',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      weatherIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'weather',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> weatherEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weather',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      weatherGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weather',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> weatherLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weather',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> weatherBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weather',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      weatherStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'weather',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> weatherEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'weather',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> weatherContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'weather',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> weatherMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'weather',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      weatherIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weather',
        value: '',
      ));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
      weatherIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'weather',
        value: '',
      ));
    });
  }
}

extension DiaryRecordQueryObject
    on QueryBuilder<DiaryRecord, DiaryRecord, QFilterCondition> {}

extension DiaryRecordQueryLinks
    on QueryBuilder<DiaryRecord, DiaryRecord, QFilterCondition> {}

extension DiaryRecordQuerySortBy
    on QueryBuilder<DiaryRecord, DiaryRecord, QSortBy> {
  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy>
      sortByAiAnalysisReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiAnalysisReason', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy>
      sortByAiAnalysisReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiAnalysisReason', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy>
      sortByAiStabilityScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiStabilityScore', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy>
      sortByAiStabilityScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiStabilityScore', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByEventText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventText', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByEventTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventText', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByIsGapLarge() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGapLarge', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByIsGapLargeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGapLarge', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByMoodScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodScore', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByMoodScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodScore', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByRecordDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordDate', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByRecordDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordDate', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByRecordId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordId', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByRecordIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordId', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortBySelfAnalysis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selfAnalysis', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy>
      sortBySelfAnalysisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selfAnalysis', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByTimeString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeString', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByTimeStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeString', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByWeather() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weather', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByWeatherDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weather', Sort.desc);
    });
  }
}

extension DiaryRecordQuerySortThenBy
    on QueryBuilder<DiaryRecord, DiaryRecord, QSortThenBy> {
  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy>
      thenByAiAnalysisReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiAnalysisReason', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy>
      thenByAiAnalysisReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiAnalysisReason', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy>
      thenByAiStabilityScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiStabilityScore', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy>
      thenByAiStabilityScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiStabilityScore', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByEventText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventText', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByEventTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventText', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByIsGapLarge() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGapLarge', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByIsGapLargeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGapLarge', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByMoodScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodScore', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByMoodScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodScore', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByRecordDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordDate', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByRecordDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordDate', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByRecordId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordId', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByRecordIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordId', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenBySelfAnalysis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selfAnalysis', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy>
      thenBySelfAnalysisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selfAnalysis', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByTimeString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeString', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByTimeStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeString', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByWeather() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weather', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByWeatherDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weather', Sort.desc);
    });
  }
}

extension DiaryRecordQueryWhereDistinct
    on QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> {
  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByAiAnalysisReason(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aiAnalysisReason',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct>
      distinctByAiStabilityScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aiStabilityScore');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByEventText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventText', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByIsGapLarge() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isGapLarge');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByLocation(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'location', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByMoodScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'moodScore');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByMoodTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'moodTags');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByRecordDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recordDate');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByRecordId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recordId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctBySelfAnalysis(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'selfAnalysis', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByTimeString(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timeString', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByWeather(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weather', caseSensitive: caseSensitive);
    });
  }
}

extension DiaryRecordQueryProperty
    on QueryBuilder<DiaryRecord, DiaryRecord, QQueryProperty> {
  QueryBuilder<DiaryRecord, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<DiaryRecord, String?, QQueryOperations>
      aiAnalysisReasonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aiAnalysisReason');
    });
  }

  QueryBuilder<DiaryRecord, int?, QQueryOperations> aiStabilityScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aiStabilityScore');
    });
  }

  QueryBuilder<DiaryRecord, String, QQueryOperations> eventTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventText');
    });
  }

  QueryBuilder<DiaryRecord, bool, QQueryOperations> isGapLargeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isGapLarge');
    });
  }

  QueryBuilder<DiaryRecord, String?, QQueryOperations> locationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'location');
    });
  }

  QueryBuilder<DiaryRecord, int, QQueryOperations> moodScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'moodScore');
    });
  }

  QueryBuilder<DiaryRecord, List<String>, QQueryOperations> moodTagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'moodTags');
    });
  }

  QueryBuilder<DiaryRecord, DateTime, QQueryOperations> recordDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recordDate');
    });
  }

  QueryBuilder<DiaryRecord, String, QQueryOperations> recordIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recordId');
    });
  }

  QueryBuilder<DiaryRecord, String?, QQueryOperations> selfAnalysisProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'selfAnalysis');
    });
  }

  QueryBuilder<DiaryRecord, String, QQueryOperations> timeStringProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timeString');
    });
  }

  QueryBuilder<DiaryRecord, String?, QQueryOperations> weatherProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weather');
    });
  }
}
