import 'package:flutter/material.dart';
import 'package:VibraSound/core/app_export.dart';

class CustomToggleButton extends StatefulWidget {
  final IconData icon;
  final ValueChanged<bool> onChanged;

  CustomToggleButton({
    required this.icon,
    required this.onChanged,
  });

  @override
  _CustomToggleButtonState createState() => _CustomToggleButtonState();
}

class _CustomToggleButtonState extends State<CustomToggleButton> {
  bool _value = true; // Inicia ligado

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CupertinoSwitch(
          value: _value,
          onChanged: (value) {
            setState(() {
              _value = value;
            });
            widget.onChanged(value);
          },
          activeColor: Colors.green.shade900,
        ),
        SizedBox(width: 12),
    widget.icon == Icons.lightbulb ? Padding(
      padding: EdgeInsets.only(left: 4), //Padding apenas do lightbulb
      child: Icon(
        widget.icon,
        color: _value ? Colors.green.shade900 : Colors.grey.shade300,
        size: 40,
      ),
    ) : Icon(
      widget.icon,
      color: _value ? Colors.green.shade900 : Colors.grey.shade300,
      size: 40,
        
        ),
      ],
    );
  }
}