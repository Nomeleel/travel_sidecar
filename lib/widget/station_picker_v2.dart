import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../model/station.dart';
import '../service/station_service.dart';

const double width = 150;
const double radius = 30;

class StationPicker extends StatelessWidget {
  const StationPicker({
    Key? key,
    this.onPicked,
  }) : super(key: key);

  final void Function(Station)? onPicked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: radius / 2),
      decoration: BoxDecoration(
        color: Colors.tealAccent,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Autocomplete<Station>(
        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) => TextField(
          controller: textEditingController,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            border: InputBorder.none,
          ),
          inputFormatters: [
            FilteringTextInputFormatter(RegExp('[a-z]*', caseSensitive: false), allow: true),
          ],
          onSubmitted: (value) => onFieldSubmitted(),
        ),
        onSelected: onPicked,
        displayStringForOption: (station) => station.name,
        optionsBuilder: (textEditingValue) {
          return StationService().search(textEditingValue.text);
        },
        optionsViewBuilder: (context, onSelected, options) => AutocompleteStations(
          options: options,
          onSelected: onSelected,
        ),
      ),
    );
  }
}

class AutocompleteStations extends StatelessWidget {
  const AutocompleteStations({
    super.key,
    required this.options,
    required this.onSelected,
  });

  final Iterable<Station> options;
  final AutocompleteOnSelected<Station> onSelected;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300, maxWidth: width - radius),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (BuildContext context, int index) {
              final Station station = options.elementAt(index);
              return InkWell(
                onTap: () {
                  onSelected(station);
                  Focus.maybeOf(context)?.unfocus();
                },
                child: Builder(
                  builder: (BuildContext context) {
                    final bool highlight = AutocompleteHighlightedOption.of(context) == index;
                    if (highlight) {
                      SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
                        Scrollable.ensureVisible(context, alignment: 0.5);
                      });
                    }

                    return Container(
                      height: 30,
                      color: highlight
                          ? Theme.of(context).primaryColor
                          : index.isEven
                              ? Colors.grey
                              : Colors.white,
                      alignment: Alignment.center,
                      child: Text(station.name),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
