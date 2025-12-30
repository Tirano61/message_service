import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Configuración centralizada de la aplicación
class AppConfig {
  // URL base del servidor
  // Cambia esta URL según el entorno:
  // - Emulador Android: 'http://10.0.2.2:3000'
  // - Localhost (escritorio): 'http://localhost:3000'
  // - Dispositivo físico en red local: 'http://TU_IP:3000' (ej: 'http://192.168.1.100:3000')
  // - Dev Tunnels / Producción: 'https://3ztt6mfl-3000.brs.devtunnels.ms'
  static const String baseUrl = 'https://3ztt6mfl-3000.brs.devtunnels.ms';
  
  // Cliente HTTP que acepta certificados no confiables (solo para desarrollo)
  // ⚠️ PRODUCCIÓN: Eliminar badCertificateCallback y usar certificado SSL válido
  // TODO: Antes de publicar en producción:
  //   1. Cambiar baseUrl a dominio con certificado SSL válido
  //   2. Eliminar el método getHttpClient() y usar http.Client() directamente
  //   3. Verificar que AndroidManifest.xml tenga usesCleartextTraffic="false"
  static http.Client getHttpClient() {
    final ioClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // ADVERTENCIA: Esto solo debe usarse en desarrollo con túneles de Dev Tunnels
        // En producción con un dominio real, elimina esto
        return host.contains('devtunnels.ms') || host.contains('localhost');
      };
    return IOClient(ioClient);
  }
}
