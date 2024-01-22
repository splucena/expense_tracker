import 'dart:convert'; // Import the 'json' package

class Expense {
  String id;
  String title;
  double amount;
  DateTime? date;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    DateTime? date, // Make the date parameter optional
  }) : date = date ?? DateTime.now(); // Use DateTime.now() as the default value

  // Convert the expense to a JSON string
  String toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date?.toIso8601String(), // Convert DateTime to string
    };
    return json.encode(data); // Encode the map as a JSON string
  }

  // Create an expense from a JSON string
  static Expense fromJson(String jsonStr) {
    final Map<String, dynamic> data = json.decode(jsonStr); // Decode JSON string to a map
    return Expense(
      id: data['id'],
      title: data['title'],
      amount: data['amount'],
      date: data['date'] != null ? DateTime.parse(data['date']) : null, // Parse string to DateTime
    );
  }
}