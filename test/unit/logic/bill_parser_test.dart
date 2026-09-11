import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/logic/bill_parser.dart';
import 'package:ibudaya/core/models/energy.dart';

void main() {
  group('parsePlnReceipt — pascabayar payment receipt', () {
    const receipt = '''
STRUK PEMBAYARAN TAGIHAN LISTRIK
IDPEL : 512345678901
NAMA : CLARA
TARIF/DAYA : R1/1300 VA
BL/TH : SEP26
STAND METER : 00012345-00012465
RP TAG PLN : Rp 175.000
ADMIN BANK : Rp 2.500
TOTAL BAYAR : Rp 177.500
''';

    final parsed = parsePlnReceipt(receipt);

    test('detects a monthly bill', () {
      expect(parsed.kind, EnergyKind.postpaid);
    });

    test('derives kWh from the stand meter readings', () {
      expect(parsed.kwh, 120);
    });

    test('prefers TOTAL BAYAR over RP TAG PLN', () {
      expect(parsed.totalIdr, 177500);
    });

    test('reads BL/TH as the billing month', () {
      expect(parsed.periodMonth, DateTime(2026, 9));
    });

    test('reads the 12-digit customer id', () {
      expect(parsed.customerId, '512345678901');
      expect(parsed.isComplete, isTrue);
    });
  });

  group('parsePlnReceipt — prabayar token receipt', () {
    const receipt = '''
STRUK PEMBELIAN LISTRIK PRABAYAR
NO METER : 14123456789
IDPEL : 523456789012
TARIF/DAYA : R1/1300 VA
RP BAYAR : Rp 202.500,00
JML KWH : 136,4
STROOM/TOKEN : 1234 5678 9012 3456 7890
TGL : 05/09/2026
''';

    final parsed = parsePlnReceipt(receipt);

    test('detects a token purchase', () {
      expect(parsed.kind, EnergyKind.token);
    });

    test('reads a decimal-comma kWh', () {
      expect(parsed.kwh, closeTo(136.4, 0.001));
    });

    test('drops the ,00 cents from the rupiah amount', () {
      expect(parsed.totalIdr, 202500);
    });

    test('uses the purchase date for the month', () {
      expect(parsed.periodMonth, DateTime(2026, 9));
    });
  });

  test('PLN Mobile e-bill wording', () {
    final parsed = parsePlnReceipt('''
Tagihan Listrik
Periode Agustus 2026
ID Pelanggan 512345678901
Pemakaian 98 kWh
Total Tagihan Rp148.500
''');
    expect(parsed.kind, EnergyKind.postpaid);
    expect(parsed.kwh, 98);
    expect(parsed.totalIdr, 148500);
    expect(parsed.periodMonth, DateTime(2026, 8));
  });

  test('repairs O/I misread inside numbers', () {
    final parsed = parsePlnReceipt('''
STRUK PEMBELIAN TOKEN
RP BAYAR : Rp 2O2.5OO
JML KWH : 13O,4
''');
    expect(parsed.totalIdr, 202500);
    expect(parsed.kwh, closeTo(130.4, 0.001));
  });

  test('a kWh total is never mistaken for money', () {
    final parsed = parsePlnReceipt('''
TOKEN LISTRIK
TOTAL KWH : 136,4
RP BAYAR : Rp 50.000
''');
    expect(parsed.totalIdr, 50000);
  });

  test('text that is not a receipt yields nothing', () {
    final parsed = parsePlnReceipt('Selamat pagi ibu-ibu arisan');
    expect(parsed.foundAnything, isFalse);
    expect(parsed.kind, isNull);
  });

  group('parseIndonesianNumber', () {
    test('decimal comma', () => expect(parseIndonesianNumber('136,4'), 136.4));
    test('thousands dot', () => expect(parseIndonesianNumber('1.234'), 1234));
    test('both', () => expect(parseIndonesianNumber('1.234,5'), 1234.5));
    test('decimal dot', () => expect(parseIndonesianNumber('12.5'), 12.5));
    test('trailing dot', () => expect(parseIndonesianNumber('98.'), 98));
  });
}
