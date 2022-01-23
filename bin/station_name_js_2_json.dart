import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

void main({List<String> args = const ['station_name_v10168']}) {
  File jsFile = File(path.join(Directory.current.path, 'bin', '${args.first}.js'));
  if (jsFile.existsSync()) {
    final jsStr = jsFile.readAsStringSync();
    if (jsStr.isNotEmpty) {
      // var station_names ='${stationStr}';
      final stationList = jsStr.substring("var station_names ='".length, jsStr.length - 2).split('|');
      final stationMap = {};
      for (int i = 0; i < stationList.length - 1; i += 5) {
        stationMap[stationList[i]] = {
          'id': stationList[i],
          'name': stationList[i + 1],
          'code': stationList[i + 2],
          'simpleAlphabetic': stationList[i + 3],
          'alphabetic': stationList[i + 4],
        };
      }

      File jsonFile = File(path.join(Directory.current.path, 'assets', 'json', 'station_name.json'));
      jsonFile.writeAsStringSync(jsonEncode(
        {
          'version': args.first.split('_').last,
          'station': stationMap,
        },
      ));
    }
  }
}
