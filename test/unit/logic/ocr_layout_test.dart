import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/logic/bill_parser.dart';
import 'package:ibudaya/core/models/energy.dart';

OcrLine _line(String text, double top, double left, {double height = 30}) =>
    OcrLine(text: text, top: top, bottom: top + height, left: left);

void main() {
  test('label and value printed on one row are joined left to right', () {
    final text = layoutOcrLines([
      _line('RP 191.757', 402, 520),
      _line('TOTAL BAYAR :', 400, 60),
      _line('STAND METER : 00012450-00012581', 300, 60),
    ]);
    expect(text.split('\n'), [
      'STAND METER : 00012450-00012581',
      'TOTAL BAYAR : RP 191.757',
    ]);
  });

  test('lines on different rows stay separate', () {
    final text = layoutOcrLines([
      _line('IDPEL : 521234567890', 100, 60),
      _line('BL/TH : AGU26', 160, 60),
    ]);
    expect(text.split('\n'), hasLength(2));
  });

  test('empty input gives empty text', () {
    expect(layoutOcrLines(const []), '');
  });

  test('the sample PLN receipt used for device testing parses fully', () {
    final text = layoutOcrLines([
      _line('STRUK PEMBAYARAN TAGIHAN LISTRIK', 90, 60),
      _line('PT PLN (PERSERO)', 154, 60),
      _line('IDPEL', 282, 60),
      _line(': 521234567890', 283, 290),
      _line('BL/TH', 474, 60),
      _line(': AGU26', 475, 290),
      _line('STAND METER', 538, 60),
      _line(': 00012450-00012581', 539, 290),
      _line('RP TAG PLN', 602, 60),
      _line(': RP 189.257', 603, 290),
      _line('ADMIN BANK', 666, 60),
      _line(': RP 2.500', 667, 290),
      _line('TOTAL BAYAR', 730, 60),
      _line(': RP 191.757', 731, 290),
    ]);
    final r = parsePlnReceipt(text);
    expect(r.kind, EnergyKind.postpaid);
    expect(r.kwh, 131);
    expect(r.totalIdr, 191757);
    expect(r.periodMonth, DateTime(2026, 8));
    expect(r.customerId, '521234567890');
    expect(r.isComplete, isTrue);
  });
}
