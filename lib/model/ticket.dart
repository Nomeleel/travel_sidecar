// ignore_for_file: avoid_function_literals_in_foreach_calls

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

    SeatType.values.forEach((e) => hasTicketMap[e] = _hasTicket(list[e.position]));
  }

  late final String name;
  late final String fromCode;
  late final String toCode;
  late final StringTime departureTime;
  late final StringTime arrivalTime;
  late final Map<SeatType, bool> hasTicketMap;

  final hasTicketRegExp = RegExp(r'(有|\d)');

  bool _hasTicket(String numberStr) => hasTicketRegExp.hasMatch(numberStr);

  bool get hasTicket => hasTicketMap.values.any((e) => e);

  bool hasTicketWhereSeatTypeList([List<SeatType>? seatTypeList]) {
    return (seatTypeList?.isEmpty ?? true) ? hasTicket : seatTypeList!.any((e) => hasTicketMap[e]!);
  }

  @override
  String toString() {
    return '$name $departureTime - $arrivalTime\n$hasTicketMap';
  }
}

enum SeatType {
  businessClassSeat(name: '商务', position: 32),
  firstClassSeat(name: '一等', position: 31),
  secondClassSeat(name: '二等', position: 30),
  softSleeper(name: '软卧', position: 23),
  hardSleeper(name: '硬卧', position: 28),
  hardSeat(name: '硬座', position: 29),
  standing(name: '无座', position: 26);

  const SeatType({required this.name, required this.position});

  final String name;

  final int position;

  @override
  String toString() => name;
}
