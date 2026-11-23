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

  test('a typed national number finds the saved international form', () {
    const saved = T9Entry(name: 'Zong', numbers: ['+923701234567']);
    final r = t9Search('03701234567', [saved]);
    expect(r.single.entry, saved);
    expect(r.single.numberRange, (3, 13)); // "3701234567" after "+92"
    expect(t9Search('0370', [saved]), hasLength(1));
    expect(t9Search('037', [saved]), isEmpty); // Too short to guess a country code.
    expect(t9Search('0380', [saved]), isEmpty);
  });

  test('a typed national number finds the saved 00 international form', () {
    const saved = T9Entry(name: 'Ali', numbers: ['00923211234567']);
    final r = t9Search('03211234567', [saved]);
    expect(r.single.entry, saved);
    expect(r.single.numberRange, (4, 14)); // "3211234567" after "0092"
  });

  test('a saved number shorter than a country code does not throw', () {
    const stub = T9Entry(name: 'Stub', numbers: ['+92']);
    expect(t9Search('0370', [stub]), isEmpty);
  });

  test('skips contacts without numbers and empty queries', () {
    expect(t9Search('', all), isEmpty);
    expect(t9Search('564669', all), isEmpty); // Johnny has no number
  });
  test('accented and Cyrillic names match like AOSP SmartDial', () {
    const ivan = T9Entry(name: 'Иван Петров', numbers: ['0300 1234567']);
    const jose = T9Entry(name: 'José', numbers: ['0300 1234568']);
    const muller = T9Entry(name: 'Müller', numbers: ['0300 1234569']);
    const sukru = T9Entry(name: 'Şükrü', numbers: ['0300 1234570']);
    const ipek = T9Entry(name: 'İpek', numbers: ['0300 1234571']);
    const decomposed = T9Entry(name: 'José Luis', numbers: ['0300 1234572']);
    final people = [ivan, jose, muller, sukru, ipek, decomposed];

    expect(t9Search('4225', people).single.entry, ivan);
    expect(t9Search('536', people).single.entry, ivan); // Пет(ров)
    expect(t9Search('5673', people).map((m) => m.entry), [jose, decomposed]);
    expect(t9Search('685537', people).single.entry, muller);
    expect(t9Search('78578', people).single.entry, sukru);
    expect(t9Search('4735', people).single.entry, ipek);
    // The combining accent stays inside the word: "José L".
    expect(t9Search('56735', people).single.nameRange, (0, 7));
  });
}
