import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart' as model;
import '../models/goal.dart';

final firestoreServiceProvider = Provider<FirestoreService?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  return FirestoreService(user.uid);
});

class FirestoreService {
  final String uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreService(this.uid);

  DocumentReference get _userDoc => _firestore.collection('users').doc(uid);
  CollectionReference get _profileCol => _userDoc.collection('profile');
  CollectionReference get _incomeCol => _userDoc.collection('income');
  CollectionReference get _expensesCol => _userDoc.collection('expenses');
  CollectionReference get _goalsCol => _userDoc.collection('goals');

  // ─── Profile & Income ────────────────────────────────────────────────────────

  Stream<double> getMonthlyIncomeStream() {
    return _profileCol.doc('data').snapshots().map((doc) {
      if (!doc.exists) return 0.0;
      final data = doc.data() as Map<String, dynamic>?;
      return (data?['monthlyIncome'] ?? 0.0).toDouble();
    });
  }

  Future<void> setMonthlyIncome(double income) async {
    await _profileCol.doc('data').set({'monthlyIncome': income}, SetOptions(merge: true));
  }

  // ─── Transactions ────────────────────────────────────────────────────────────

  model.Transaction _mapTransaction(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return model.Transaction(
      id: data['id'] ?? doc.id,
      amount: (data['amount'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      type: model.TransactionType.values[data['type'] ?? 0],
      note: data['note'] ?? '',
    );
  }

  Stream<List<model.Transaction>> getTransactionsStream() {
    final controller = StreamController<List<model.Transaction>>.broadcast();
    List<model.Transaction> income = [];
    List<model.Transaction> expenses = [];

    final incomeSub = _incomeCol.snapshots().listen((snapshot) {
      income = snapshot.docs.map(_mapTransaction).toList();
      controller.add([...income, ...expenses]);
    });

    final expensesSub = _expensesCol.snapshots().listen((snapshot) {
      expenses = snapshot.docs.map(_mapTransaction).toList();
      controller.add([...income, ...expenses]);
    });

    controller.onCancel = () {
      incomeSub.cancel();
      expensesSub.cancel();
    };

    return controller.stream;
  }

  Future<void> addTransaction(model.Transaction transaction) async {
    final col = transaction.type == model.TransactionType.income ? _incomeCol : _expensesCol;
    await col.doc(transaction.id).set({
      'id': transaction.id,
      'amount': transaction.amount,
      'category': transaction.category,
      'date': Timestamp.fromDate(transaction.date),
      'type': transaction.type.index,
      'note': transaction.note,
    });
  }

  Future<void> deleteTransaction(String id) async {
    // Try deleting from both, since we don't know the type from just ID
    await _incomeCol.doc(id).delete();
    await _expensesCol.doc(id).delete();
  }

  // ─── Goals ───────────────────────────────────────────────────────────────────

  Stream<List<Goal>> getGoalsStream() {
    return _goalsCol.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Goal(
          id: data['id'] ?? doc.id,
          title: data['title'] ?? '',
          targetAmount: (data['targetAmount'] ?? 0.0).toDouble(),
          currentAmount: (data['currentAmount'] ?? 0.0).toDouble(),
          deadline: (data['deadline'] as Timestamp).toDate(),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          isCompleted: data['isCompleted'] ?? false,
        );
      }).toList();
    });
  }

  Future<void> saveGoal(Goal goal) async {
    await _goalsCol.doc(goal.id).set({
      'id': goal.id,
      'title': goal.title,
      'targetAmount': goal.targetAmount,
      'currentAmount': goal.currentAmount,
      'deadline': Timestamp.fromDate(goal.deadline),
      'createdAt': Timestamp.fromDate(goal.createdAt),
      'isCompleted': goal.isCompleted,
    });
  }

  Future<void> deleteGoal(String id) async {
    await _goalsCol.doc(id).delete();
  }
}
