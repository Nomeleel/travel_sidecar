import 'package:flutter/material.dart';

class StationPicker extends StatefulWidget {
  const StationPicker({
    Key? key,
    this.station,
    this.onPicked,
  }) : super(key: key);

  final String? station;
  final void Function(String)? onPicked;

  @override
  _StationPickerState createState() => _StationPickerState();
}

class _StationPickerState extends State<StationPicker> {
  final LayerLink _link = LayerLink();
  OverlayEntry? suggestionOverlay;

  final ValueNotifier<List<String>> suggestionList = ValueNotifier([]);
  late final TextEditingController _inputTextController = TextEditingController(text: widget.station ?? '');
  final FocusNode _focusNode = FocusNode();

  final double width = 150;
  final double radius = 30;

  @override
  void didUpdateWidget(covariant StationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.station != oldWidget.station) {
      _inputTextController.text = widget.station!;
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
          onChanged: (input) {
            // TODO(Nomeleel): imp.
            suggestionList.value = List.generate(input.length, (index) => '$index');
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
                builder: (BuildContext context, List<String> value, Widget? child) {
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
                        child: Text(value[index]),
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
