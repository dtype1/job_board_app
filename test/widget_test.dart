import 'package:flutter_test/flutter_test.dart';
import 'package:job_board_app/widgets.dart';

void main() {
  test('validazione email', () {
    expect(emailValidator('mario@rossi.it'), isNull);
    expect(emailValidator('non-una-email'), isNotNull);
    expect(emailValidator(''), isNotNull);
  });

  test('formattazione', () {
    expect(formatDate(DateTime(2026, 3, 7)), '07/03/2026');
    expect(formatBytes(2048), '2.0 KB');
  });
}
