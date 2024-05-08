import 'package:flutter/material.dart';
import 'package:travel_sidecar/widget/checkbox_label.dart';

import 'model/station.dart';
import 'model/ticket.dart';
import 'service/ticket_service.dart';
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
        filterPanel(),
        Expanded(
          child: ListView.builder(
            itemCount: ticketResultList.length,
            itemBuilder: (context, index) {
              final item = ticketResultList[index];
              return Container(
                color: index.isEven ? Colors.grey[350] : Colors.transparent,
                child: Text(item),
              );
            },
          ),
        )
      ],
    );
  }

  List<SeatType> seatTypeList = [];

  Widget filterPanel() {
    return Column(
      children: [
        RangeSlider(
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
        Wrap(
          spacing: 20,
          children: SeatType.values.map<Widget>(
            (e) {
              final checked = seatTypeList.contains(e);
              return CheckboxLabel(
                checked: checked,
                label: e.name,
                onTab: () {
                  checked ? seatTypeList.remove(e) : seatTypeList.add(e);

                  if (seatTypeList.isEmpty) {
                    firstWhere.remove(whereHasTicket);
                    secondWhere.remove(whereHasTicket);
                  } else {
                    firstWhere.add(whereHasTicket);
                    secondWhere.add(whereHasTicket);
                  }

                  transfer();
                },
              );
            },
          ).toList(),
        ),
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

  List<Ticket> firstTicketList = [];
  List<Ticket> secondTicketList = [];

  bool _isValid() => fromStation != null && transferStation != null && toStation != null && travelDate != null;

  String get travelDateStr => travelDate?.toString().split(' ').first ?? '';

  Future<void> _syncTicketList() async {
    if (!_isValid()) return;
    firstTicketList = await _getParseTicketList(fromStation!.code, transferStation!.code);
    secondTicketList = await _getParseTicketList(transferStation!.code, toStation!.code);
  }

  Future<List<Ticket>> _getParseTicketList(String from, String to) {
    return ticketService.query(from: from, to: to, trainDate: travelDateStr);
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

  bool whereHasTicket(Ticket ticket) => ticket.hasTicketWhereSeatTypeList(seatTypeList);

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
