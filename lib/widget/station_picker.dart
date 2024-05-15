import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/station.dart';
import '../service/station_service.dart';

class StationPicker extends StatefulWidget {
  const StationPicker({
    Key? key,
    this.station,
    this.onPicked,
  }) : super(key: key);

  final Station? station;
  final void Function(Station)? onPicked;

  @override
  _StationPickerState createState() => _StationPickerState();
}

class _StationPickerState extends State<StationPicker> {
  final LayerLink _link = LayerLink();
  OverlayEntry? suggestionOverlay;

  final ValueNotifier<List<Station>> suggestionList = ValueNotifier([]);
  late final TextEditingController _inputTextController = TextEditingController(text: stationName);
  final FocusNode _focusNode = FocusNode();

  final double width = 150;
  final double radius = 30;

  final StationService _stationService = StationService();

  String get stationName => widget.station?.name ?? '';

  @override
  void didUpdateWidget(covariant StationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.station != oldWidget.station) {
      _inputTextController.text = stationName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(horizontal: radius),
        decoration: BoxDecoration(
          color: Colors.tealAccent,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: TextField(
          controller: _inputTextController,
          focusNode: _focusNode,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            border: InputBorder.none,
          ),
          inputFormatters: [
            FilteringTextInputFormatter(RegExp('[a-z]*', caseSensitive: false), allow: true),
          ],
          onChanged: (input) async {
            suggestionList.value = await _stationService.search(input);
            if (suggestionOverlay == null) {
              suggestionOverlay = buildSuggestionOverlay();
              Overlay.of(context)?.insert(suggestionOverlay!);
            }
          },
        ),
      ),
    );
  }

  // TODO(Nomeleel): Support Tab keyboard.
  OverlayEntry buildSuggestionOverlay() {
    return OverlayEntry(
      builder: (context) => UnconstrainedBox(
        child: CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.bottomCenter,
          followerAnchor: Alignment.topCenter,
          showWhenUnlinked: false,
          child: DefaultTextStyle(
            style: const TextStyle(fontSize: 10),
            child: Container(
              constraints: BoxConstraints(maxHeight: 300, maxWidth: width - radius),
              color: Colors.purple,
              child: ValueListenableBuilder(
                valueListenable: suggestionList,
                builder: (BuildContext context, List<Station> value, Widget? child) {
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: value.length,
                    itemBuilder: (_, index) => GestureDetector(
                      onTap: () {
                        suggestionOverlay?.remove();
                        suggestionOverlay = null;
                        _focusNode.unfocus();
                        widget.onPicked?.call(value[index]);
                      },
                      child: Container(
                        height: 30,
                        color: index.isEven ? Colors.grey : Colors.transparent,
                        alignment: Alignment.center,
                        child: Text(value[index].name),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
