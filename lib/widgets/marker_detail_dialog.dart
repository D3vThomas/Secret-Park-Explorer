import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/photo_storage.dart';
import 'package:intl/intl.dart'; // Pour formater les dates

class MarkerDetailDialog extends StatefulWidget {
    final String title;
    final String detail;
    final List<String>? initialPhotoPaths;

    const MarkerDetailDialog({
        super.key,
        required this.title,
        required this.detail,
        this.initialPhotoPaths,
    });

    @override
    State<MarkerDetailDialog> createState() => _MarkerDetailDialogState();
}

class _MarkerDetailDialogState extends State<MarkerDetailDialog> {
    late List<String> photoPaths;

    @override
    void initState() {
        super.initState();
        // Trier les photos pour que les plus récentes apparaissent en premier
        photoPaths = (widget.initialPhotoPaths ?? []).reversed.toList();
    }

    Future<void> _takePhoto() async {
        final newPhoto = await takePhoto(widget.title);
        if (newPhoto != null) {
            setState(() {
                photoPaths.insert(0, newPhoto); // insérer au début pour ordre décroissant
            });
        }
    }

    String _getPhotoDate(String path) {
        try {
            final filename = path.split('/').last; // titre-timestamp.jpg
            final timestampStr = filename.split('-').last.split('.').first;
            final timestamp = int.parse(timestampStr);
            final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
            return 'prise le ${DateFormat('dd/MM/yyyy à HH:mm').format(date)}';
        } catch (e) {
         return ''; // fallback si parsing échoue
        }
    }

    void _viewPhotos() {
        if (photoPaths.isEmpty) return;

        showDialog(
            context: context,
            builder: (context) {
                return AlertDialog(
                    title: Text('Photos de ${widget.title}'),
                    content: SizedBox(
                        width: double.maxFinite,
                        height: 350,
                        child: PageView.builder(
                            itemCount: photoPaths.length,
                            itemBuilder: (context, index) {
                                final path = photoPaths[index];
                                return Column(
                                    children: [
                                        Expanded(child: Image.file(File(path), fit: BoxFit.contain)),
                                        const SizedBox(height: 5),
                                        Text(
                                            _getPhotoDate(path),
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                    ],
                                );
                            },
                        ),
                    ),
                    actions: [
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("Fermer"),
                        ),
                    ],
                );
            },
        );
    }

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: Text(widget.title),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    Text(widget.detail),
                    const SizedBox(height: 10),
                    ElevatedButton(
                        onPressed: _takePhoto,
                        child: const Text("Prendre une photo"),
                    ),
                    if (photoPaths.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ElevatedButton(
                            onPressed: _viewPhotos,
                            child: Text("Voir les photos (${photoPaths.length})"),
                        ),
                    ],
                ],
            ),
            actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(photoPaths),
                    child: const Text("Fermer"),
                ),
            ],
        );
    }
}
