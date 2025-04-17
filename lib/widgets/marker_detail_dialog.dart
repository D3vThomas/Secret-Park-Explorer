import 'package:flutter/material.dart';

class MarkerDetailDialog extends StatelessWidget {
    final String title;
    final String detail;
    final String? photoPath;
    final Function() onTakePhoto;
    final Function() onViewPhoto;

    const MarkerDetailDialog({
        super.key,
        required this.title,
        required this.detail,
        this.photoPath,
        required this.onTakePhoto,
        required this.onViewPhoto,
    });

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: Text(title),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    Text(detail),
                    if (photoPath != null) ElevatedButton(
                        onPressed: onViewPhoto,
                        child: Text("Voir la photo"),
                    )
                    else ElevatedButton(
                        onPressed: onTakePhoto,
                        child: Text("Prendre une photo"),
                    ),
                ],
            ),
            actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("Fermer"),
                ),
            ],
        );
    }
}
