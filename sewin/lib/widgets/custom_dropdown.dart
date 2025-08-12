import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final String hint;
  final int? value;
  final List<Map<String, dynamic>> items;
  final Function(int?) onChanged;

  const CustomDropdown({
    Key? key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          hint: Text(hint, style: const TextStyle(color: Colors.grey)),
          value: value,
          isExpanded: true,
          items: items.map((Map<String, dynamic> item) {
            return DropdownMenuItem<int>(
              value: item['id'] as int,
              child: Text(item['name'] as String),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
