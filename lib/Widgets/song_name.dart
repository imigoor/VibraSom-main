import 'package:flutter/material.dart';
import 'package:VibraSound/core/app_export.dart';

class SongNameWidget extends StatelessWidget {
  final String fileName;

  SongNameWidget({required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
      child: Text(
        fileName,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}