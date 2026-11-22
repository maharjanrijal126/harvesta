import 'package:flutter_test/flutter_test.dart';
import 'package:harvesta/core/utils.dart';

void main() {
  test('NPR formatting', () => expect(npr(4750), 'NPR 4,750'));
  test('validators', () {
    expect(emailV('a@b.com'), isNull);
    expect(emailV('nope'), isNotNull);
    expect(passV('12345'), isNotNull);
  });
}
