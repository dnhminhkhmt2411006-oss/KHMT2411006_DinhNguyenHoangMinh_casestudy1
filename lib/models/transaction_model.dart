class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final String type; // 'income' (thu nhập) hoặc 'expense' (chi tiêu)
  final String category;
  final String date; // Chuỗi ISO 8601, ví dụ 2026-10-17T00:00:00.000
  final String? note;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
  });

  bool get isIncome => type == 'income';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date,
      'note': note,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      // ép qua num để không lỗi khi database trả về int thay vì double
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      category: map['category'] as String,
      date: map['date'] as String,
      note: map['note'] as String?,
    );
  }
}