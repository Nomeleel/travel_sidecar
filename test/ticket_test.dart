import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:travel_sidecar/model/ticket.dart';

void main() {
  final File ticketJsonFile = File(path.join(Directory.current.path, 'backup', 'ticket_query.json'));
  final List ticketStrList = jsonDecode(ticketJsonFile.readAsStringSync())['result'];
  ticketStrList.forEach(ticketStrTest);
}

void ticketStrTest(str) {
  final Ticket ticket = Ticket.fromStr(str);
  debugPrint(ticket.toString());
}
