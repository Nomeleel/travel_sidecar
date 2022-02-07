import 'string_time.dart';

class Ticket {
  Ticket.fromStr(String str) {
    final list = str.split('|');

    name = list[3];
    fromCode = list[6];
    toCode = list[7];
    departureTime = StringTime(list[8]);
    arrivalTime = StringTime(list[9]);

    final numberStr = list[32];
    hasTicket = numberStr != '' && numberStr != '无' && numberStr != '*';
  }

  late String name;
  late String fromCode;
  late String toCode;
  late StringTime departureTime;
  late StringTime arrivalTime;
  late bool hasTicket;

  @override
  String toString() {
    return '$name $departureTime - $arrivalTime';
  }
}