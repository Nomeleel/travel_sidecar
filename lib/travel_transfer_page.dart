import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'model/station.dart';
import 'widget/station_picker.dart';

class TravelTransferPage extends StatefulWidget {
  const TravelTransferPage({Key? key}) : super(key: key);

  @override
  _TravelTransferPageState createState() => _TravelTransferPageState();
}

typedef TicketWhere = bool Function(Ticket ticket);

class _TravelTransferPageState extends State<TravelTransferPage> {
  Station? fromStation;
  Station? transferStation;
  Station? toStation;

  DateTime? travelDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StationPicker(
                station: fromStation,
                onPicked: (station) => setState(() => fromStation = station),
              ),
              StationPicker(
                station: transferStation,
                onPicked: (station) => setState(() => transferStation = station),
              ),
              StationPicker(
                station: toStation,
                onPicked: (station) => setState(() => toStation = station),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () async {
                      final dateTime = await showDatePicker(
                        context: context,
                        initialDate: travelDate ?? DateTime.now(),
                        firstDate: DateTime(2022),
                        lastDate: DateTime(2222),
                      );
                      if (dateTime != null) setState(() => travelDate = dateTime);
                    },
                    icon: const Icon(Icons.date_range),
                  ),
                  Text(travelDateStr),
                ],
              )
            ],
          ),
          IconButton(
            onPressed: _syncTicketList,
            icon: const Icon(Icons.download),
          ),
          IconButton(
            onPressed: transfer,
            icon: const Icon(Icons.train),
          )
        ],
      ),
    );
  }

  late List<Ticket> firstTicketList;
  late List<Ticket> secondTicketList;

  bool _isValid() => fromStation != null && transferStation != null && toStation != null && travelDate != null;

  String get travelDateStr => travelDate?.toString().split(' ').first ?? '';

  Future<void> _syncTicketList() async {
    if (!_isValid()) return;
    firstTicketList = await _getParseTicketList(fromStation!.code, transferStation!.code);
    secondTicketList = await _getParseTicketList(transferStation!.code, toStation!.code);
  }

  Future<List<Ticket>> _getParseTicketList(String from, String to) async {
    // 2022-01-30
    final url = 'https://kyfw.12306.cn/otn/leftTicket/queryA?'
        'leftTicketDTO.train_date=$travelDateStr&'
        'leftTicketDTO.from_station=$from&'
        'leftTicketDTO.to_station=$to&'
        'purpose_codes=ADULT';

    final response = await http.get(Uri.parse(url), headers: {'Cookie': 'RAIL_DEVICEID=abc;'});
    if (response.statusCode == 200) {
      Map map = json.decode(response.body);
      return map['data']['result'].map<Ticket>((e) => Ticket.fromStr(e)).toList();
    }

    return const [];
  }

  late List<TicketWhere> firstWhere = [whereHasTicket];
  late List<TicketWhere> secondWhere = [whereHasTicket];

  bool where(List<TicketWhere> whereList, Ticket ticket) {
    if (whereList.isEmpty) return true;
    return whereList.every((where) => where(ticket));
  }

  int departureTime = 30;

  bool whereAfterDepartureTime(Ticket ticket) => ticket.departureTime.mins >= departureTime;

  int arrivalTime = 10800;

  bool whereBeforeArrivalTime(Ticket ticket) => ticket.departureTime.mins <= arrivalTime;

  bool whereHasTicket(Ticket ticket) => ticket.hasTicket;

  // TODO(Nomeleel): 隔天问题未考虑 first：23:50到 second：次日00:23出发
  void transfer() {
    final first = firstTicketList.where((e) => where(firstWhere, e)).toList()
      ..sort((i, j) => i.arrivalTime.mins.compareTo(j.arrivalTime.mins));

    final second = secondTicketList.where((e) => where(secondWhere, e)).toList()
      ..sort((i, j) => i.departureTime.mins.compareTo(j.departureTime.mins));

    for (int fIndex = 0, sStart = 0; fIndex < first.length; fIndex++) {
      final fItem = first[fIndex];
      int sIndex = second.indexWhere((e) => e.departureTime.mins > fItem.arrivalTime.mins, sStart);
      if (sIndex == -1) break;
      sStart = sIndex;
      for (; sIndex < second.length; sIndex++) {
        final sItem = second[sIndex];
        final duration = sItem.departureTime.mins - fItem.arrivalTime.mins;
        if (duration > 30 && duration <= 120) {
          if (fItem.toCode == sItem.fromCode) {
            debugPrint('--------wait: $duration min-----------\n$fItem \n$sItem');
          }
        } else {
          break;
        }
      }
    }
    debugPrint('------end---------');
  }
}

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

// TODO 处理加一天的问题
class StringTime {
  StringTime(this.timeStr) {
    mins = _toMins(timeStr);
  }

  final String timeStr;
  late final int mins;

  int _toMins(String timeStr) {
    final hhmm = timeStr.split(':').map((e) => int.tryParse(e)!);
    return hhmm.first * 60 + hhmm.last;
  }

  @override
  String toString() => timeStr;
}
