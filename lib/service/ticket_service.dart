import 'dart:convert';

import 'package:http/http.dart' as http;

import '/model/ticket.dart';

late TicketService ticketService = TicketService();

class TicketService {
  TicketService._();

  static late final TicketService _ticketService = TicketService._();

  factory TicketService() => _ticketService;

  Future<List<Ticket>> query({
    required String from,
    required String to,
    required String trainDate,
  }) async {
    final url = 'https://kyfw.12306.cn/otn/leftTicket/queryA?'
        'leftTicketDTO.train_date=$trainDate&'
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
}
