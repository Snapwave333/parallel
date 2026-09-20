/// DTOs mirroring `packages/shared_schemas/schemas.json`. Every fromJson reads
/// defensively: the backend occasionally omits a key (null), so a missing
/// field must never crash a list render.
library;

String _str(Object? v) {
  if (v is String) return v;
  if (v is num) return v.toString();
  if (v is bool) return v.toString();
  return '';
}

bool _b(Object? v) => v is bool && v;

int _i(Object? v) => v is num ? v.toInt() : 0;

double _d(Object? v) => v is num ? v.toDouble() : 0.0;

List<Map<String, Object?>> _list(Object? v) => v is List
    ? v.whereType<Map<String, Object?>>().toList()
    : <Map<String, Object?>>[];

class PublicUser {
  PublicUser({
    required this.id,
    this.name,
    this.age,
    this.gender,
    this.city,
    this.about,
    this.datingIntents = const [],
    this.relationshipGoals = const [],
    this.ageVerified = false,
    this.identityVerified = false,
  });

  factory PublicUser.fromJson(Map<String, Object?> json) => PublicUser(
        id: _i(json['id']),
        name: json['name'] as String?,
        age: json['age'] is num ? (json['age'] as num).toInt() : null,
        gender: json['gender'] as String?,
        city: json['city'] as String?,
        about: json['about'] as String?,
        datingIntents: json['dating_intents'] is List
            ? (json['dating_intents'] as List).map(_str).toList()
            : const [],
        relationshipGoals: json['relationship_goals'] is List
            ? (json['relationship_goals'] as List).map(_str).toList()
            : const [],
        ageVerified: _b(json['age_verified']),
        identityVerified: _b(json['identity_verified']),
      );

  final int id;
  final String? name;
  final int? age;
  final String? gender;
  final String? city;
  final String? about;
  final List<String> datingIntents;
  final List<String> relationshipGoals;
  final bool ageVerified;
  final bool identityVerified;

  String get displayName => (name == null || name!.isEmpty) ? 'User $id' : name!;
}

class IntroPhoto {
  IntroPhoto({required this.id, required this.url, required this.position});

  factory IntroPhoto.fromJson(Map<String, Object?> json) => IntroPhoto(
        id: _i(json['id']),
        url: _str(json['url']),
        position: _i(json['position']),
      );

  final int id;
  final String url;
  final int position;
}

class ExplainLine {
  ExplainLine({required this.level, required this.text});

  factory ExplainLine.fromJson(Map<String, Object?> json) =>
      ExplainLine(level: _str(json['level']), text: _str(json['text']));

  final String level;
  final String text;
}

class IntroReason {
  IntroReason({
    required this.overall,
    required this.sharedInterests,
    required this.explain,
  });

  factory IntroReason.fromJson(Map<String, Object?> json) => IntroReason(
        overall: _d(json['overall']),
        sharedInterests: _i(json['shared_interests']),
        explain: _list(json['explain'])
            .map(ExplainLine.fromJson)
            .toList(growable: false),
      );

  final double overall;
  final int sharedInterests;
  final List<ExplainLine> explain;
}

class TodayIntro {
  TodayIntro({
    required this.userId,
    required this.user,
    required this.photos,
    required this.reason,
  });

  factory TodayIntro.fromJson(Map<String, Object?> json) {
    final userJson = json['user'];
    final reasonJson = json['reason'];
    return TodayIntro(
      userId: _i(json['user_id']),
      user: userJson is Map<String, Object?>
          ? PublicUser.fromJson(userJson)
          : PublicUser(id: _i(json['user_id'])),
      photos: _list(json['photos']).map(IntroPhoto.fromJson).toList(),
      reason: reasonJson is Map<String, Object?>
          ? IntroReason.fromJson(reasonJson)
          : IntroReason(overall: 0, sharedInterests: 0, explain: const []),
    );
  }

  final int userId;
  final PublicUser user;
  final List<IntroPhoto> photos;
  final IntroReason reason;
}

class DiscoverToday {
  DiscoverToday({required this.day, required this.introductions});

  factory DiscoverToday.fromJson(Map<String, Object?> json) => DiscoverToday(
        day: _i(json['day']),
        introductions: _list(json['introductions'])
            .map(TodayIntro.fromJson)
            .toList(),
      );

  final int day;
  final List<TodayIntro> introductions;

  int get count => introductions.length;
}

class CatalogFeature {
  CatalogFeature({
    required this.key,
    required this.label,
    required this.ordinal,
    required this.options,
  });

  factory CatalogFeature.fromJson(Map<String, Object?> json) => CatalogFeature(
        key: _str(json['key']),
        label: _str(json['label']),
        ordinal: _b(json['ordinal']),
        options: json['options'] is List
            ? (json['options'] as List).map(_str).toList()
            : const [],
      );

  final String key;
  final String label;
  final bool ordinal;
  final List<String> options;
}

class DimensionGroup {
  DimensionGroup({required this.dimension, required this.features});

  factory DimensionGroup.fromJson(Map<String, Object?> json) => DimensionGroup(
        dimension: _str(json['dimension']),
        features: _list(json['features']).map(CatalogFeature.fromJson).toList(),
      );

  final String dimension;
  final List<CatalogFeature> features;
}

class FeatureValue {
  FeatureValue({
    required this.key,
    required this.value,
    this.importance,
    this.classification,
    this.visibility,
  });

  final String key;
  final String value;
  final int? importance;
  final String? classification;
  final String? visibility;

  Map<String, Object?> toJson() => {
        'key': key,
        'value': value,
        if (importance != null) 'importance': importance,
        if (classification != null) 'classification': classification,
        if (visibility != null) 'visibility': visibility,
      };
}

class RequestItem {
  RequestItem({
    required this.id,
    required this.fromUser,
    required this.toUser,
    required this.otherUser,
    required this.reason,
  });

  factory RequestItem.fromJson(Map<String, Object?> json) {
    final userJson = json['other_user'];
    final otherId = json['from_user'] is num
        ? _i(json['from_user'])
        : _i(json['to_user']);
    return RequestItem(
      id: _i(json['id']),
      fromUser: _i(json['from_user']),
      toUser: _i(json['to_user']),
      otherUser: userJson is Map<String, Object?>
          ? PublicUser.fromJson(userJson)
          : PublicUser(id: otherId),
      reason: json['reason'] as String?,
    );
  }

  final int id;
  final int fromUser;
  final int toUser;
  final PublicUser otherUser;
  final String? reason;
}

class ConnectionEntry {
  ConnectionEntry({required this.userId, required this.user, required this.since});

  factory ConnectionEntry.fromJson(Map<String, Object?> json) {
    final userJson = json['user'];
    return ConnectionEntry(
      userId: _i(json['user_id']),
      user: userJson is Map<String, Object?>
          ? PublicUser.fromJson(userJson)
          : PublicUser(id: _i(json['user_id'])),
      since: _i(json['since']),
    );
  }

  final int userId;
  final PublicUser user;
  final int since;
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.kind,
    required this.noResponseNeeded,
    required this.state,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, Object?> json) => ChatMessage(
        id: _i(json['id']),
        conversationId: _i(json['conversation_id']),
        senderId: _i(json['sender_id']),
        body: _str(json['body']),
        kind: _str(json['kind']),
        noResponseNeeded: _b(json['no_response_needed']),
        state: _str(json['state']),
        createdAt: _i(json['created_at']),
      );

  final int id;
  final int conversationId;
  final int senderId;
  final String body;
  final String kind;
  final bool noResponseNeeded;
  final String state;
  final int createdAt;
}

class Conversation {
  Conversation({
    required this.id,
    required this.otherUser,
    this.lastMessage,
  });

  factory Conversation.fromJson(Map<String, Object?> json) {
    final userJson = json['other_user'];
    final lastJson = json['last_message'];
    return Conversation(
      id: _i(json['id']),
      otherUser: userJson is Map<String, Object?>
          ? PublicUser.fromJson(userJson)
          : PublicUser(id: 0),
      lastMessage: lastJson is Map<String, Object?>
          ? ChatMessage(
              id: _i(lastJson['id']),
              conversationId: 0,
              senderId: _i(lastJson['sender_id']),
              body: _str(lastJson['body']),
              kind: 'text',
              noResponseNeeded: false,
              state: 'sent',
              createdAt: _i(lastJson['created_at']),
            )
          : null,
    );
  }

  final int id;
  final PublicUser otherUser;
  final ChatMessage? lastMessage;
}

class ContractRule {
  ContractRule({
    required this.key,
    required this.label,
    required this.askFirst,
    required this.enabled,
  });

  factory ContractRule.fromJson(Map<String, Object?> json) => ContractRule(
        key: _str(json['key']),
        label: _str(json['label']),
        askFirst: _b(json['ask_first']),
        enabled: _b(json['enabled']),
      );

  final String key;
  final String label;
  final bool askFirst;
  final bool enabled;

  ContractRule copyWith({bool? enabled}) =>
      ContractRule(key: key, label: label, askFirst: askFirst, enabled: enabled ?? this.enabled);
}

class CatalogContractRule {
  CatalogContractRule({
    required this.key,
    required this.label,
    required this.askFirst,
  });

  factory CatalogContractRule.fromJson(Map<String, Object?> json) =>
      CatalogContractRule(
        key: _str(json['key']),
        label: _str(json['label']),
        askFirst: _b(json['ask_first']),
      );

  final String key;
  final String label;
  final bool askFirst;
}

class IntentInfo {
  IntentInfo({this.mine, required this.theirsRevealed, this.mutual});

  factory IntentInfo.fromJson(Map<String, Object?> json) => IntentInfo(
        mine: json['mine'] as String?,
        theirsRevealed: _b(json['theirs_revealed']),
        mutual: json['mutual'] as String?,
      );

  final String? mine;
  final bool theirsRevealed;
  final String? mutual;
}

class SocialStatus {
  SocialStatus({required this.battery, required this.temperature});

  factory SocialStatus.fromJson(Map<String, Object?> json) => SocialStatus(
        battery: _i(json['battery']),
        temperature: _str(json['temperature']),
      );

  final int battery;
  final String temperature;
}

class DatePrefs {
  DatePrefs({
    required this.userId,
    required this.distanceMiles,
    required this.ageMin,
    required this.ageMax,
    this.city,
    required this.quietVenues,
    required this.outside,
    required this.groupSizeMax,
    required this.weekdays,
    required this.weekends,
    required this.eveningOk,
    required this.daytimeOk,
  });

  factory DatePrefs.fromJson(Map<String, Object?> json) => DatePrefs(
        userId: _i(json['user_id']),
        distanceMiles: _i(json['distance_miles']),
        ageMin: _i(json['age_min']),
        ageMax: _i(json['age_max']),
        city: json['city'] as String?,
        quietVenues: _b(json['quiet_venues']),
        outside: _b(json['outside']),
        groupSizeMax: _i(json['group_size_max']),
        weekdays: json['weekdays'] is List
            ? (json['weekdays'] as List).map((e) => _i(e)).toList()
            : const [],
        weekends: _b(json['weekends']),
        eveningOk: _b(json['evening_ok']),
        daytimeOk: _b(json['daytime_ok']),
      );

  final int userId;
  final int distanceMiles;
  final int ageMin;
  final int ageMax;
  final String? city;
  final bool quietVenues;
  final bool outside;
  final int groupSizeMax;
  final List<int> weekdays;
  final bool weekends;
  final bool eveningOk;
  final bool daytimeOk;

  Map<String, Object?> toJson() => {
        'distance_miles': distanceMiles,
        'age_min': ageMin,
        'age_max': ageMax,
        'city': city,
        'quiet_venues': quietVenues,
        'outside': outside,
        'group_size_max': groupSizeMax,
        'weekdays': weekdays,
        'weekends': weekends,
        'evening_ok': eveningOk,
        'daytime_ok': daytimeOk,
      };
}

class DatePlan {
  DatePlan({
    required this.id,
    required this.initiatorId,
    required this.partnerId,
    required this.title,
    required this.planA,
    this.planB,
    this.planC,
    required this.day,
    this.startAt,
    this.detail,
    required this.state,
    required this.otherUser,
  });

  factory DatePlan.fromJson(Map<String, Object?> json) {
    final userJson = json['other_user'];
    return DatePlan(
      id: _i(json['id']),
      initiatorId: _i(json['initiator_id']),
      partnerId: _i(json['partner_id']),
      title: _str(json['title']),
      planA: _str(json['plan_a']),
      planB: json['plan_b'] as String?,
      planC: json['plan_c'] as String?,
      day: _i(json['day']),
      startAt: json['start_at'] is num ? _i(json['start_at']) : null,
      detail: json['detail'] as String?,
      state: _str(json['state']),
      otherUser: userJson is Map<String, Object?>
          ? PublicUser.fromJson(userJson)
          : PublicUser(id: 0),
    );
  }

  final int id;
  final int initiatorId;
  final int partnerId;
  final String title;
  final String planA;
  final String? planB;
  final String? planC;
  final int day;
  final int? startAt;
  final String? detail;
  final String state;
  final PublicUser otherUser;

  String dayLabel() {
    final d = DateTime.fromMillisecondsSinceEpoch(day * 86400000);
    return '${d.month}/${d.day}/${d.year}';
  }
}

class TogetherSession {
  TogetherSession({
    required this.id,
    required this.pairingCode,
    required this.state,
    this.permissionScope = const {},
    required this.createdAt,
    required this.otherUser,
  });

  factory TogetherSession.fromJson(Map<String, Object?> json) {
    final userJson = json['other_user'];
    final scope = json['permission_scope'];
    return TogetherSession(
id: _i(json['id']),
        pairingCode: _str(json['pairing_code']),
        state: _str(json['state']),
        permissionScope: scope is Map<String, Object?>
            ? scope
            : const <String, Object?>{},
        createdAt: _i(json['created_at']),
      otherUser: userJson is Map<String, Object?>
          ? PublicUser.fromJson(userJson)
          : PublicUser(id: 0),
    );
  }

  final int id;
  final String pairingCode;
  final String state;
  final Map<String, Object?> permissionScope;
  final int createdAt;
  final PublicUser otherUser;
}

class Block {
  Block({required this.blockedId, required this.user, required this.createdAt});

  factory Block.fromJson(Map<String, Object?> json) {
    final userJson = json['user'];
    return Block(
      blockedId: _i(json['blocked_id']),
      user: userJson is Map<String, Object?>
          ? PublicUser.fromJson(userJson)
          : PublicUser(id: _i(json['blocked_id'])),
      createdAt: _i(json['created_at']),
    );
  }

  final int blockedId;
  final PublicUser user;
  final int createdAt;
}

class ReportItem {
  ReportItem({
    required this.id,
    required this.reportedId,
    this.category,
    this.reason,
    required this.createdAt,
  });

  factory ReportItem.fromJson(Map<String, Object?> json) => ReportItem(
        id: _i(json['id']),
        reportedId: _i(json['reported_id']),
        category: json['category'] as String?,
        reason: json['reason'] as String?,
        createdAt: _i(json['created_at']),
      );

  final int id;
  final int reportedId;
  final String? category;
  final String? reason;
  final int createdAt;
}

class ExplainDimension {
  ExplainDimension({
    required this.dimension,
    required this.label,
    required this.alignment,
    this.compat,
    required this.aImportance,
    required this.bImportance,
    this.aValue,
    this.bValue,
  });

  factory ExplainDimension.fromJson(Map<String, Object?> json) {
    final imp = json['importance'];
    final items = json['items'];
    final aItem = items is Map<String, Object?> ? items['a'] : null;
    final bItem = items is Map<String, Object?> ? items['b'] : null;
    Object? vOf(Object? x) =>
        x is Map<String, Object?> ? x['value'] : x;
    return ExplainDimension(
      dimension: _str(json['dimension']),
      label: _str(json['label']),
      alignment: _str(json['alignment']),
      compat: json['compat'] is num ? _d(json['compat']) : null,
      aImportance:
          imp is Map<String, Object?> && imp['a'] is num ? _i(imp['a']) : 0,
      bImportance:
          imp is Map<String, Object?> && imp['b'] is num ? _i(imp['b']) : 0,
      aValue: vOf(aItem) is String ? _str(vOf(aItem)) : null,
      bValue: vOf(bItem) is String ? _str(vOf(bItem)) : null,
    );
  }

  final String dimension;
  final String label;
  final String alignment;
  final double? compat;
  final int aImportance;
  final int bImportance;
  final String? aValue;
  final String? bValue;
}

class ExplainResponse {
  ExplainResponse({
    this.dealbreakerConflicts = const [],
    required this.dimensions,
    required this.sharedInterests,
    required this.explain,
  });

  factory ExplainResponse.fromJson(Map<String, Object?> json) =>
      ExplainResponse(
        dealbreakerConflicts: json['dealbreaker_conflicts'] is List
            ? (json['dealbreaker_conflicts'] as List)
            : const [],
        dimensions: _list(json['dimensions'])
            .map(ExplainDimension.fromJson)
            .toList(),
        sharedInterests: _i(json['shared_interests']),
        explain: _list(json['explain']).map(ExplainLine.fromJson).toList(),
      );

  final List<Object?> dealbreakerConflicts;
  final List<ExplainDimension> dimensions;
  final int sharedInterests;
  final List<ExplainLine> explain;
}

class SeedResult {
  SeedResult({required this.email, required this.name, required this.token});

  factory SeedResult.fromJson(Map<String, Object?> json) => SeedResult(
        email: _str(json['email']),
        name: _str(json['name']),
        token: _str(json['token']),
      );

  final String email;
  final String name;
  final String token;
}