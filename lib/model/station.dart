class Station {
  Station.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'],
        code = map['code'],
        simpleAlphabetic = map['simpleAlphabetic'],
        alphabetic = map['alphabetic'];

  final String id;
  final String name;
  final String code;
  final String simpleAlphabetic;
  final String alphabetic;
}

class StationMap {
  StationMap.fromMap(Map<String, dynamic> map)
      : version = map['version'],
        stationMap = Map<String, Station>.from(
          map['station'].map((key, value) => MapEntry(key.toString(), Station.fromMap(value))),
        );

  final String version;
  final Map<String, Station> stationMap;
}
