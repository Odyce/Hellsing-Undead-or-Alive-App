import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'book_index.dart';
import 'content/book_content.dart';

/// Fournit le [BookIndex] construit à partir du contenu complet du livre.
///
/// Construit une seule fois (Provider synchrone non-modifiable).
final bookIndexProvider = Provider<BookIndex>(
  (ref) => buildBookIndex(),
);
