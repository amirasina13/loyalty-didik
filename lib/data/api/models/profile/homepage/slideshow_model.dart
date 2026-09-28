import '../../../../../domain/domain.dart';

// Slideshoe model (will call in home_page_model.dart)

class SlideshowModel extends SlideshowEntity {
  const SlideshowModel({required super.id, super.path, super.url});

  factory SlideshowModel.fromJson(Map<String, dynamic> json) {
    var index = 0;

    return SlideshowModel(
      id: (index++).toString(),
      path: json['path'],
      url: json['url'],
    );
  }
}
