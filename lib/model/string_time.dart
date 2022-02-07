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