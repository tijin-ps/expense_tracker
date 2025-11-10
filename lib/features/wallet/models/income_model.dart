class IncomeModel {
  final int? id;
  final String title;
  final double amount;
  final String category;
  final String date;
  final String? card; // <-- added card field

  IncomeModel({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.card, // <-- added to constructor
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "amount": amount,
      "category": category,
      "date": date,
      "card": card, // <-- added here
    };
  }

  factory IncomeModel.fromMap(Map<String, dynamic> map) {
    return IncomeModel(
      id: map["id"],
      title: map["title"],
      amount: map["amount"],
      category: map["category"],
      date: map["date"],
      card: map["card"], // <-- added here
    );
  }
}
