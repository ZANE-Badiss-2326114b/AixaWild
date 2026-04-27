/// Point d'export conditionnel de la connexion Drift.
///
/// Sélectionne l'implémentation adaptée à la plateforme:
/// - IO natif (Linux/Windows/Android),
/// - Web (WASM + IndexedDB),
/// - Stub non supporté.
export 'connection_stub.dart' if (dart.library.io) 'connection_native.dart' if (dart.library.js_interop) 'connection_web.dart';
