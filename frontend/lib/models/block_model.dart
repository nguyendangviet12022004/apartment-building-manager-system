class BlockModel {
  final int id;
  final String blockCode;
  final String? description;

  BlockModel({
    required this.id,
    required this.blockCode,
    this.description,
  });

  factory BlockModel.fromJson(Map<String, dynamic> json) {
    return BlockModel(
      id: json['id'],
      blockCode: json['blockCode'],
      description: json['description'],
    );
  }
}
