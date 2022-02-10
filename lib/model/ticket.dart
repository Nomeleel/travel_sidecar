import 'string_time.dart';

class Ticket {
  Ticket.fromStr(String str) {
    final list = str.split('|');

    name = list[3];
    fromCode = list[6];
    toCode = list[7];
    departureTime = StringTime(list[8]);
    arrivalTime = StringTime(list[9]);

    hasTicketMap = {};
    hasTicketStrMap = {};
    int typeIndex = 0;
    // TODO(Nomeleel): imp
    list.getRange(22, 33).toList().reversed.forEach((e) {
      hasTicketStrMap[typeIndex] = e;
      hasTicketMap[typeIndex++] = _hasTicket(e);
    });
  }

  late final String name;
  late final String fromCode;
  late final String toCode;
  late final StringTime departureTime;
  late final StringTime arrivalTime;
  late final Map<int, bool> hasTicketMap;
  late final Map<int, String> hasTicketStrMap;

  final hasTicketRegExp = RegExp(r'(有|\d)');

  bool _hasTicket(String numberStr) => hasTicketRegExp.hasMatch(numberStr);

  bool get hasTicket => hasTicketMap.values.any((e) => e);

  @override
  String toString() {
    return '$name $departureTime - $arrivalTime';
  }
}
