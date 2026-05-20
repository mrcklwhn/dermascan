import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

class LocalAssetServer {
  static HttpServer? _server;

  static const int port = 8080;

  static Future<void> start() async {
    if (_server != null) {
      debugPrint('Asset server already running');
      return;
    }

    Future<Response> handler(Request request) async {
      try {
        String path = request.url.path;

        debugPrint('REQUEST PATH: $path');

        if (path.isEmpty) {
          return Response.ok(
            'Dermascan Asset Server Running',
            headers: <String, Object>{'Access-Control-Allow-Origin': '*'},
          );
        }

        path = path.replaceFirst(RegExp('^/'), '');

        final String assetPath = 'assets/$path';

        debugPrint('TRY LOAD ASSET: $assetPath');

        // Asset laden
        final ByteData data = await rootBundle.load(assetPath);

        final List<int> bytes = data.buffer.asUint8List();

        String contentType = 'application/octet-stream';

        if (path.endsWith('.glb')) {
          contentType = 'model/gltf-binary';
        } else if (path.endsWith('.gltf')) {
          contentType = 'model/gltf+json';
        } else if (path.endsWith('.html')) {
          contentType = 'text/html';
        } else if (path.endsWith('.js')) {
          contentType = 'application/javascript';
        } else if (path.endsWith('.css')) {
          contentType = 'text/css';
        } else if (path.endsWith('.png')) {
          contentType = 'image/png';
        } else if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
          contentType = 'image/jpeg';
        }

        debugPrint('ASSET LOADED SUCCESSFULLY: $assetPath');

        return Response.ok(
          bytes,
          headers: <String, Object>{
            'Content-Type': contentType,

            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, OPTIONS',
            'Access-Control-Allow-Headers': '*',

            'Cache-Control': 'no-cache',
          },
        );
      } catch (e, s) {
        debugPrint('ASSET LOAD ERROR: $e');
        debugPrintStack(stackTrace: s);

        return Response.notFound(
          'Asset not found',
          headers: <String, Object>{'Access-Control-Allow-Origin': '*'},
        );
      }
    }

    try {
      _server = await io.serve(handler, InternetAddress.anyIPv4, port);

      debugPrint('Asset server running at: http://localhost:$port');
    } catch (e, s) {
      debugPrint('SERVER START ERROR: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  static Future<void> stop() async {
    try {
      await _server?.close(force: true);

      debugPrint('Asset server stopped');

      _server = null;
    } catch (e) {
      debugPrint('SERVER STOP ERROR: $e');
    }
  }
}
