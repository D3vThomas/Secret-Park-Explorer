import 'package:flutter/material.dart';

class FilterButton extends StatelessWidget {
    final String label;
    final String type;
    final String selectedFilter;
    final Function(String) onPressed;

    const FilterButton({
        super.key,
        required this.label,
        required this.type,
        required this.selectedFilter,
        required this.onPressed,
    });

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ElevatedButton(
                onPressed: () => onPressed(type),
                style: ElevatedButton.styleFrom(
                    backgroundColor: selectedFilter == type ? Colors.blue : Colors.grey,
                ),
                child: Text(label, style: TextStyle(color: Colors.white)),
            ),
        );
    }
}
