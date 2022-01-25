import 'dart:convert';

import 'package:flutter/services.dart';
import '../model/station.dart';

class StationService {
  StationService._();

  static final StationService _stationService = StationService._();

  factory StationService() => _stationService;

  final Map<String, Station> _stationMap = {};

  Future<Map<String, Station>> get stationMap async {
    if (_stationMap.isEmpty) {
      _stationMap.addAll(await _loadStationMap());
    }

    return _stationMap;
  }

  Future<Map<String, Station>> _loadStationMap() async {
    Map<String, Station> stationMap = {};
    final stationMapStr = await rootBundle.loadString('assets/json/station_name.json');
    if (stationMapStr.isNotEmpty) {
      stationMap = StationMap.fromMap(jsonDecode(stationMapStr)).stationMap;
    }

    return stationMap;
  }

  Future<List<Station>> search(String station) async {
    if (station.isEmpty) return [];
    // TODO: search use name and alphabetic.
    return (await stationMap).entries.where((e) => e.value.name.contains(station)).map((e) => e.value).toList();
  }
}
