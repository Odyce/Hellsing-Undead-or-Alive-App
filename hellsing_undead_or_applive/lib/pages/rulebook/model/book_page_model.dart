enum BookPageType {
  text,
  image,
  character,
}

class BookPageModel {
  final BookPageType type;
  final String title;
  final String content;
  final String? imageUrl;

  BookPageModel({
    required this.type,
    required this.title,
    required this.content,
    this.imageUrl,
  });
}