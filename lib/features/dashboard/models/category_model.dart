class CategoryModel {
  final int? id;
  final String name;
  final int iconCode;
  final int colorCode;

  CategoryModel({
    this.id,
    required this.name,
    required this.iconCode,
    required this.colorCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCode': iconCode,
      'colorCode': colorCode,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      iconCode: map['iconCode'],
      colorCode: map['colorCode'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CategoryModel &&
        other.id == id &&
        other.name == name &&
        other.iconCode == iconCode &&
        other.colorCode == colorCode;
  }

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ iconCode.hashCode ^ colorCode.hashCode;
}
