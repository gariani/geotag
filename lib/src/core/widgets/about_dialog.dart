import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/support_config.dart';

/// App name shown in About.
const String _appName = 'GetTag';

const String _openStreetMapUrl = 'https://www.openstreetmap.org';

void showAppAboutDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      title: Text('About $_appName'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add or fix location data on your photos. Pick photos, set a place on the map, and export with embedded GPS.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _SectionTitle(title: 'Tools & Libraries'),
            const SizedBox(height: 8),
            _ToolItem(name: 'Flutter Map', desc: 'Map display'),
            _ToolItem(name: 'OpenStreetMap', desc: 'Map tiles', url: _openStreetMapUrl),
            _ToolItem(name: 'Nominatim', desc: 'Place search'),
            _ToolItem(name: 'flutter_exif_plugin', desc: 'EXIF read/write'),
            _ToolItem(name: 'image_picker', desc: 'Photo import'),
            _ToolItem(name: 'file_selector', desc: 'File dialogs'),
            _ToolItem(name: 'geolocator', desc: 'GPS location'),
            const SizedBox(height: 20),
            _SectionTitle(title: 'OpenStreetMap'),
            const SizedBox(height: 8),
            _OpenStreetMapParagraph(),
            const SizedBox(height: 20),
            _SectionTitle(title: 'Support'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _launchUrl(buyMeACoffeeUrl),
              icon: const Icon(Icons.coffee, size: 20),
              label: const Text('Buy me a coffee'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Future<void> _launchUrl(String url) async {
  final uri = Uri.parse(url);
  try {
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  } on Exception {
    // Launch failed - can happen on some Android 11+ devices
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _ToolItem extends StatelessWidget {
  const _ToolItem({required this.name, required this.desc, this.url});

  final String name;
  final String desc;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).textTheme.bodyMedium?.color,
        );
    final linkStyle = style?.copyWith(
      color: Colors.blue.shade700,
      decoration: TextDecoration.underline,
      decorationColor: Colors.blue.shade700,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: url != null
          ? RichText(
              text: TextSpan(
                style: style,
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: () => _launchUrl(url!),
                      child: Text(
                        '$name — ',
                        style: linkStyle?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  TextSpan(text: desc),
                ],
              ),
            )
          : RichText(
              text: TextSpan(
                style: style,
                children: [
                  TextSpan(
                    text: '$name — ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: desc),
                ],
              ),
            ),
    );
  }
}

class _OpenStreetMapParagraph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).textTheme.bodyMedium?.color,
        );
    final linkStyle = style?.copyWith(
      color: Colors.blue.shade700,
      decoration: TextDecoration.underline,
      decorationColor: Colors.blue.shade700,
    );
    return RichText(
      text: TextSpan(
        style: style,
        children: [
          const TextSpan(text: 'Maps © '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => _launchUrl(_openStreetMapUrl),
              child: Text('OpenStreetMap', style: linkStyle),
            ),
          ),
          const TextSpan(text: ' contributors. '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => _launchUrl(_openStreetMapUrl),
              child: Text('OpenStreetMap', style: linkStyle),
            ),
          ),
          const TextSpan(
            text: ' is a free, editable map of the world created by volunteers. '
                'Tiles are used under the ODbL. Learn more at openstreetmap.org.',
          ),
        ],
      ),
    );
  }
}
