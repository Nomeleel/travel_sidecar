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

  DateTime? travelDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              stationPickerBuilder('Start', fromStation, (s) => fromStation = s),
              stationPickerBuilder('Transfer', transferStation, (s) => transferStation = s),
              stationPickerBuilder('To', toStation, (s) => toStation = s),
              GestureDetector(
                onTap: () async {
                  final dateTime = await showDatePicker(
                    context: context,
                    initialDate: travelDate ?? DateTime.now(),
                    firstDate: DateTime(2022),
                    lastDate: DateTime(2222),
                  );
                  if (dateTime != null) setState(() => travelDate = dateTime);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.date_range),
                    Text(travelDateStr),
                  ],
                ),
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
          ),
          if (firstTicketList.isNotEmpty && secondTicketList.isNotEmpty) Expanded(child: resultView()),
        ],
      ),
    );
  }

  RangeValues intervalRange = const RangeValues(15, 300);

  Widget resultView() {
    return Column(
      children: [
        Container(
          height: 100,
          color: Colors.cyan,
          alignment: Alignment.center,
          child: RangeSlider(
            values: intervalRange,
            min: 15,
            max: 300,
            divisions: 50,
            labels: RangeLabels(intervalRange.start.toStringAsFixed(1), intervalRange.end.toStringAsFixed(1)),
            onChanged: (value) {
              intervalRange = value;
              transfer();
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: ticketResultList.length,
            itemBuilder: (context, index) {
              final item = ticketResultList[index];
              return Container(
                height: 50,
                alignment: Alignment.center,
                child: Text(item),
              );
            },
          ),
        )
      ],
    );
  }

  Widget stationPickerBuilder(String label, Station? station, onPicked) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const Icon(Icons.place),
        StationPicker(
          station: station,
          onPicked: (s) => setState(() => onPicked(s)),
        )
      ],
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

  late List<TicketWhere> firstWhere = [];
  late List<TicketWhere> secondWhere = [];

  bool where(List<TicketWhere> whereList, Ticket ticket) {
    if (whereList.isEmpty) return true;
    return whereList.every((where) => where(ticket));
  }

  int departureTime = 30;

  bool whereAfterDepartureTime(Ticket ticket) => ticket.departureTime.mins >= departureTime;

  int arrivalTime = 10800;

  bool whereBeforeArrivalTime(Ticket ticket) => ticket.departureTime.mins <= arrivalTime;

  bool whereHasTicket(Ticket ticket) => ticket.hasTicket;

  List<String> ticketResultList = [];

  // TODO(Nomeleel): 隔天问题未考虑 first：23:50到 second：次日00:23出发
  void transfer() {
    final first = firstTicketList.where((e) => where(firstWhere, e)).toList()
      ..sort((i, j) => i.arrivalTime.mins.compareTo(j.arrivalTime.mins));

    final second = secondTicketList.where((e) => where(secondWhere, e)).toList()
      ..sort((i, j) => i.departureTime.mins.compareTo(j.departureTime.mins));
    ticketResultList.clear();
    for (int fIndex = 0, sStart = 0; fIndex < first.length; fIndex++) {
      final fItem = first[fIndex];
      int sIndex = second.indexWhere((e) => e.departureTime.mins > fItem.arrivalTime.mins, sStart);
      if (sIndex == -1) break;
      sStart = sIndex;
      for (; sIndex < second.length; sIndex++) {
        final sItem = second[sIndex];
        final interval = sItem.departureTime.mins - fItem.arrivalTime.mins;
        if (interval >= intervalRange.start && interval <= intervalRange.end) {
          if (fItem.toCode == sItem.fromCode) {
            ticketResultList.add('--------wait: $interval min-----------\n$fItem \n$sItem');
          }
        } else {
          break;
        }
      }
    }

    setState(() {});
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
