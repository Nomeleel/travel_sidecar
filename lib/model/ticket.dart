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
    hasTicketMap[SeatType.businessClassSeat] = _hasTicket(list[32]);
    hasTicketMap[SeatType.firstClassSeat] = _hasTicket(list[31]);
    hasTicketMap[SeatType.secondClassSeat] = _hasTicket(list[30]);
    hasTicketMap[SeatType.softSleeper] = _hasTicket(list[23]);
    hasTicketMap[SeatType.hardSleeper] = _hasTicket(list[28]);
    hasTicketMap[SeatType.hardSeat] = _hasTicket(list[29]);
    hasTicketMap[SeatType.standing] = _hasTicket(list[26]);
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
  businessClassSeat,
  firstClassSeat,
  secondClassSeat,
  softSleeper,
  hardSleeper,
  hardSeat,
  standing,
}
