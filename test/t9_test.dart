import 'package:dialer/features/keypad/t9.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const john = T9Entry(name: 'John Doe', numbers: ['+92 300 1234567']);
  const ana = T9Entry(name: 'Ana Smith', numbers: ['0301-7654321']);
  const noNumber = T9Entry(name: 'Johnny', numbers: []);
  const all = [john, ana, noNumber];

  test('matches name from the start of a word, across words', () {
    final r = t9Search('5646', all); // "John"
    expect(r.single.entry, john);
    expect(r.single.nameRange, (0, 4));

    expect(t9Search('36', all).single.entry, john); // "Do"
    expect(t9Search('56463', all).single.nameRange, (0, 6)); // "John D", space skipped
  });

  test('does not match the middle of a word', () {
    expect(t9Search('46', all), isEmpty); // "hn" inside John
  });

  test('matches initials', () {
    final r = t9Search('53', all); // J D
    expect(r.single.entry, john);
    expect(r.single.nameRange, (0, 6));
  });

  test('first-word name matches rank before later-word and number matches', () {
    // "7" = S(mith) for Ana (later word) and digit 7 in Ana's number 0301-7654321... both
    // are Ana; John's number has a 7 too.
    final r = t9Search('7', all);
    expect(r.first.entry, ana);
    expect(r.first.nameRange, isNotNull);
    expect(r.last.entry, john);
    expect(r.last.numberRange, isNotNull);
  });

  test('matches numbers ignoring formatting, including +', () {
    final r = t9Search('+92300', all);
    expect(r.single.entry, john);
    expect(r.single.numberRange, (0, 7)); // "+92 300" in the original string
    expect(t9Search('17654', all).single.entry, ana); // across the dash
  });

  test('skips contacts without numbers and empty queries', () {
    expect(t9Search('', all), isEmpty);
    expect(t9Search('564669', all), isEmpty); // Johnny has no number
  });
}
