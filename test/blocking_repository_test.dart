import 'package:dialer/features/blocking/blocking_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final repo = BlockingRepository.instance;
  tearDown(() => repo.numbers.value = const []);

  test('isBlocked matches stored formats and follows list changes', () {
    repo.numbers.value = ['+92 300 1234567'];
    expect(repo.isBlocked('0300-1234567'), true);
    expect(repo.isBlocked('03007654321'), false);
    expect(repo.isBlocked(''), false);
    repo.numbers.value = ['03007654321'];
    expect(repo.isBlocked('0300-1234567'), false);
    expect(repo.isBlocked('+923007654321'), true);
  });

  test('a long call log against a long block list stays fast (was an ANR on vivo)', () {
    repo.numbers.value = [for (var i = 0; i < 2000; i++) '+92 300 ${1000000 + i}'];
    final stopwatch = Stopwatch()..start();
    var blocked = 0;
    for (var i = 0; i < 5000; i++) {
      if (repo.isBlocked('0300${2000000 + i}')) blocked++;
    }
    expect(blocked, 0);
    // 10 million regex comparisons before; one set lookup per call now.
    expect(stopwatch.elapsedMilliseconds, lessThan(500));
  });
}
