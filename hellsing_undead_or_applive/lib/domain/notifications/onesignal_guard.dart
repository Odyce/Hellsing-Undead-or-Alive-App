import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

/// OneSignal ne supporte que Android et iOS.
/// Appeler ses APIs sur Windows/macOS/Linux/Web lance MissingPluginException.
bool get isOneSignalSupported =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);
