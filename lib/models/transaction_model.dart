class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final String type; // 'Thu' (Thu nhập) hoặc 'Chi' (Chi tiêu)
  final String category;
  final String date; // Định dạng YYYY-MM-DD
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

  // Chuyển đối tượng Model thành Map để lưu vào SQLite
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

  // Chuyển dữ liệu Map từ SQLite thành đối tượng Model
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      type: map['type'],
      category: map['category'],
      date: map['date'],
      note: map['note'],
    );
  }
}