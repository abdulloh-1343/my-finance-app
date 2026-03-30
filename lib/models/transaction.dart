import 'package:hive/hive.dart';

enum TransactionType { income, expense }

class Transaction {
  final String id;
  final double amount;
  final String category;
  final DateTime date;
  final TransactionType type;
  final String note;

  Transaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.type,
    this.note = '',
  });
}

// Hand-written TypeAdapter to avoid build_runner and code-gen requirement
class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 0;

  @override
  Transaction read(BinaryReader reader) {
    return Transaction(
      id: reader.readString(),
      amount: reader.readDouble(),
      category: reader.readString(),
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      type: TransactionType.values[reader.readInt()],
      note: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer.writeString(obj.id);
    writer.writeDouble(obj.amount);
    writer.writeString(obj.category);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeInt(obj.type.index);
    writer.writeString(obj.note);
  }
}
