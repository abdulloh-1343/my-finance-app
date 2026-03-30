import 'package:hive/hive.dart';

class Goal {
  final String id;
  final String title;
  final double targetAmount;
  double currentAmount;
  final DateTime deadline;
  final DateTime createdAt;
  bool isCompleted;

  Goal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.deadline,
    required this.createdAt,
    this.isCompleted = false,
  });

  // ----------- Computed Properties -----------

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  int get daysLeft {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDay.difference(today).inDays;
  }

  double get requiredPerDay {
    final days = daysLeft;
    if (days <= 0) return remainingAmount;
    return remainingAmount / days;
  }

  bool get isOverdue => daysLeft < 0 && !isCompleted;

  void addMoney(double amount) {
    currentAmount += amount;
    if (currentAmount >= targetAmount) {
      currentAmount = targetAmount;
      isCompleted = true;
    }
  }

  void withdrawMoney(double amount) {
    currentAmount -= amount;
    if (currentAmount < 0) currentAmount = 0;
    // Revert completion if amount drops below target
    if (currentAmount < targetAmount) {
      isCompleted = false;
    }
  }
}

/// Hand-written TypeAdapter to avoid build_runner and code-gen requirement
class GoalAdapter extends TypeAdapter<Goal> {
  @override
  final int typeId = 1;

  @override
  Goal read(BinaryReader reader) {
    return Goal(
      id: reader.readString(),
      title: reader.readString(),
      targetAmount: reader.readDouble(),
      currentAmount: reader.readDouble(),
      deadline: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      isCompleted: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, Goal obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeDouble(obj.targetAmount);
    writer.writeDouble(obj.currentAmount);
    writer.writeInt(obj.deadline.millisecondsSinceEpoch);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeBool(obj.isCompleted);
  }
}
