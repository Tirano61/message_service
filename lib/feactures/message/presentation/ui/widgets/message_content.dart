import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

class MessageContent extends StatelessWidget {
  final String text;
  final Color? textColor;
  const MessageContent(this.text, {super.key, this.textColor});

  static final _combinedUrlReg = RegExp(
    r'!\[[^\]]*\]\((https?://[^\s)]+)\)|\[[^\]]+\]\((https?://[^\s)]+)\)|(https?://[^\s<>()\[\]"]+)',
    caseSensitive: false,
  );

  String _cleanUrl(String raw) {
    var url = raw.trim();
    // Remove common trailing punctuation that often appears in prose/markdown.
    while (url.isNotEmpty && '.,;:!?)]}\'"'.contains(url[url.length - 1])) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  bool _isImage(String url) {
    final v = url.toLowerCase();
    return RegExp(r'\.(png|jpe?g|gif|webp)(\?|#|$)', caseSensitive: false).hasMatch(v);
  }

  bool _isPdf(String url) {
    final v = url.toLowerCase();
    return RegExp(r'\.pdf(\?|#|$)', caseSensitive: false).hasMatch(v);
  }

  @override
  Widget build(BuildContext context) {
    final parts = _buildOrderedParts(text);
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaWidth = (constraints.maxWidth * 0.5).clamp(120.0, 280.0);
        final children = <Widget>[];

        for (final part in parts) {
          if (part.isMedia) {
            if (children.isNotEmpty) {
              children.add(const SizedBox(height: 8));
            }
            children.add(
              Center(
                child: SizedBox(
                  width: mediaWidth,
                  child: _buildMediaPreview(context, part.value),
                ),
              ),
            );
          } else if (part.value.trim().isNotEmpty) {
            if (children.isNotEmpty) {
              children.add(const SizedBox(height: 6));
            }
            children.add(_buildLinkifiedText(context, part.value));
          }
        }

        if (children.isEmpty) {
          return _buildLinkifiedText(context, text);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      },
    );
  }

  List<_MessagePart> _buildOrderedParts(String source) {
    final parts = <_MessagePart>[];
    var cursor = 0;

    for (final match in _combinedUrlReg.allMatches(source)) {
      if (match.start > cursor) {
        parts.add(_MessagePart.text(source.substring(cursor, match.start)));
      }

      final rawUrl = match.group(1) ?? match.group(2) ?? match.group(3);
      if (rawUrl != null) {
        final cleaned = _cleanUrl(rawUrl);
        if (_isImage(cleaned) || _isPdf(cleaned)) {
          parts.add(_MessagePart.media(cleaned));
        } else {
          parts.add(_MessagePart.text(match.group(0) ?? cleaned));
        }
      }

      cursor = match.end;
    }

    if (cursor < source.length) {
      parts.add(_MessagePart.text(source.substring(cursor)));
    }

    return parts;
  }

  Widget _buildMediaPreview(BuildContext context, String url) {
    if (_isImage(url)) {
      return GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _ImageFullScreen(url: url))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 140,
            width: double.infinity,
            color: Colors.grey.shade100,
            child: CachedNetworkImage(
              imageUrl: url,
              placeholder: (_, __) => Container(
                alignment: Alignment.center,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (_, __, ___) => Container(
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image),
              ),
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PDFViewerCachedFromUrl(url: url))),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Preview inline: muestra el contenido del PDF dentro de la burbuja.
            IgnorePointer(
              child: PDF(
                enableSwipe: false,
                pageFling: false,
                pageSnap: true,
                defaultPage: 0,
              ).cachedFromUrl(
                url,
                placeholder: (progress) => Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: (progress / 100).clamp(0.0, 1.0),
                  ),
                ),
                errorWidget: (_) => const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.picture_as_pdf), SizedBox(width: 8), Flexible(child: Text('No se pudo previsualizar'))],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                color: Colors.black.withValues(alpha: 0.45),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.open_in_full, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Tocar para abrir PDF', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkifiedText(BuildContext context, String value) {
    final base = MarkdownStyleSheet.fromTheme(Theme.of(context));
    final styleSheet = base.copyWith(
      p: TextStyle(fontSize: 13, color: textColor ?? Colors.black, height: 1.25),
      tableHead: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor ?? Colors.black),
      tableBody: TextStyle(fontSize: 12.5, color: textColor ?? Colors.black),
      tableBorder: TableBorder.all(color: Colors.grey.shade300, width: 0.8),
      a: const TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline),
      code: TextStyle(fontFamily: 'monospace', fontSize: 12.5, color: Colors.indigo.shade900),
      blockquote: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
      blockquoteDecoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: Colors.grey.shade400, width: 3)),
      ),
    );

    return MarkdownBody(
      data: value,
      selectable: true,
      extensionSet: md.ExtensionSet.gitHubWeb,
      styleSheet: styleSheet,
      onTapLink: (textLink, href, title) async {
        final url = _cleanUrl(href ?? textLink);
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}

class _MessagePart {
  final String value;
  final bool isMedia;

  const _MessagePart._(this.value, {required this.isMedia});

  factory _MessagePart.text(String value) => _MessagePart._(value, isMedia: false);
  factory _MessagePart.media(String value) => _MessagePart._(value, isMedia: true);
}

class _ImageFullScreen extends StatelessWidget {
  final String url;
  const _ImageFullScreen({required this.url});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: PhotoView(imageProvider: CachedNetworkImageProvider(url)),
    );
  }
}

class PDFViewerCachedFromUrl extends StatelessWidget {
  final String url;
  const PDFViewerCachedFromUrl({super.key, required this.url});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF')),
      body: PDF().cachedFromUrl(
        url,
        placeholder: (progress) => Center(
          child: CircularProgressIndicator(value: (progress / 100).clamp(0.0, 1.0)),
        ),
        errorWidget: (error) => Center(child: Text('Error al cargar PDF')),
      ),
    );
  }
}
