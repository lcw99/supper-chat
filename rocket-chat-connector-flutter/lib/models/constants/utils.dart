DateTime? jsonToDateTime(json) => json != null
    ? (json is String
        ? DateTime.parse(json).toUtc()
        : DateTime.fromMillisecondsSinceEpoch(json['\$date']! is String
              ? int.parse(json['\$date'])
              : json['\$date'], isUtc: true)
      )
    : null;