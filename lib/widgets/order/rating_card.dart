import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../generated/l10n.dart';
import '../../screens/media/fullscreen_media_viewer.dart';

class RatingCard extends StatelessWidget {
  final dynamic rating;

  const RatingCard({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    final r = rating;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).dividerColor.withAlpha(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      r.username ?? 'Anonymous',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if ((r.rating ?? 0) > 0) ...[
                    Text((r.rating as num).toDouble().toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                  ]
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                DateFormat('dd/MM/yyyy').format(r.timeSent),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
            if (r.comment != null && (r.comment as String).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(r.comment as String),
              ),
            if ((r.videoUrl != null && (r.videoUrl as String).isNotEmpty) ||
                (r.imagesUrl != null && (r.imagesUrl as List).isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (r.videoUrl != null && (r.videoUrl as String).isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) =>
                                FullscreenMediaViewer(videoUrl: r.videoUrl),
                          ));
                        },
                        child: Container(
                          height: 160,
                          color: Theme.of(context).colorScheme.surface,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(r.videoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox()),
                              Center(
                                child: Icon(Icons.play_circle,
                                    color: const Color.fromRGBO(
                                        255, 255, 255, 0.9),
                                    size: 56),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (r.imagesUrl != null && (r.imagesUrl as List).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: SizedBox(
                          height: 80,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: (r.imagesUrl as List).map<Widget>((img) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(
                                      builder: (_) =>
                                          FullscreenMediaViewer(imageUrl: img),
                                    ));
                                  },
                                  child: Image.network(img,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox()),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            if (r.reply != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.of(context).appTitle,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface)),
                    const SizedBox(height: 6),
                    Text(r.reply.comment ?? ''),
                    const SizedBox(height: 6),
                    if (r.reply.timestamp != null)
                      Text(
                          DateFormat('dd/MM/yyyy HH:mm')
                              .format(r.reply.timestamp),
                          style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.6))),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
