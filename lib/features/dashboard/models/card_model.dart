class CardModel {
  final int? id;
  final String bank;
  final String number;
  final String expiry;
  final String holder;
  final String balance;
  final String type;

  CardModel({
    this.id,
    required this.bank,
    required this.number,
    required this.expiry,
    required this.holder,
    required this.balance,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bank': bank,
      'number': number,
      'expiry': expiry,
      'holder': holder,
      'balance': balance,
      'type': type,
    };
  }

  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'],
      bank: map['bank'],
      number: map['number'],
      expiry: map['expiry'],
      holder: map['holder'],
      balance: map['balance'],
      type: map['type'],
    );
  }
}
