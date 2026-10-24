import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/data/seed/kana_data.dart';
import 'package:kana_quest/features/learn/session_controller.dart';

void main() {
  final ids = hiraganaList.take(10).toList();

  test('huruf yang sudah ada di antrean dipindah ke depan, jumlah tetap', () {
    final queue = [...ids];
    final target = ids[6];
    putKanaFirst(queue, target.id);
    expect(queue.first.id, target.id);
    expect(queue.length, 10);
    expect(queue.where((k) => k.id == target.id).length, 1);
  });

  test('huruf di luar antrean disisipkan di depan, jumlah tetap', () {
    final queue = [...ids];
    final outsider = hiraganaList[20];
    putKanaFirst(queue, outsider.id);
    expect(queue.first.id, outsider.id);
    expect(queue.length, 10);
  });

  test('huruf yang sama tidak berurutan walau ada duplikat', () {
    final a = ids[0];
    final b = ids[1];
    final queue = [b, a, a, b];
    putKanaFirst(queue, a.id);
    expect(queue.first.id, a.id);
    expect(queue[1].id, isNot(a.id));
  });

  test('tanpa firstKanaId antrean tidak berubah', () {
    final queue = [...ids];
    putKanaFirst(queue, null);
    expect(queue.map((k) => k.id), ids.map((k) => k.id));
  });

  test('withoutFirst membuang huruf pertama tapi menjaga pengaturan lain', () {
    const args = SessionArgs(type: 'katakana', quick: true, firstKanaId: 'x');
    final again = args.withoutFirst();
    expect(again.firstKanaId, isNull);
    expect(again.type, 'katakana');
    expect(again.quick, isTrue);
  });
}
