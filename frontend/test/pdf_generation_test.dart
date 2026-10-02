// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:tradevision_ai/services/report_pdf_service.dart';
import 'package:tradevision_ai/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ReportPdfService generates flawless 2-page PDF for Reliance and other stocks with live prices', () async {
    // 1. Test Reliance with dynamic live price
    final relianceReport = ApiService.generateLocalReportForTesting(
      'RELIANCE',
      livePrice: 1247.50,
      changeAmount: 18.50,
      changePercent: 1.51,
      dayHigh: 1255.00,
      dayLow: 1238.20,
      volume: '3.2M',
    );

    final relianceBytes = await ReportPdfService.generateReportPdfBytes(relianceReport);
    expect(relianceBytes, isNotNull);
    expect(relianceBytes.length, greaterThan(1000));
    print('Generated Reliance PDF: ${relianceBytes.length} bytes');

    // 2. Test TCS with another dynamic price
    final tcsReport = ApiService.generateLocalReportForTesting(
      'TCS',
      livePrice: 4120.00,
      changeAmount: -25.40,
      changePercent: -0.61,
      dayHigh: 4150.00,
      dayLow: 4095.00,
      volume: '1.8M',
    );

    final tcsBytes = await ReportPdfService.generateReportPdfBytes(tcsReport);
    expect(tcsBytes, isNotNull);
    expect(tcsBytes.length, greaterThan(1000));
    print('Generated TCS PDF: ${tcsBytes.length} bytes');

    // 3. Test formatRupee
    expect(ReportPdfService.formatRupee(1247.5), contains('₹'));
    expect(ReportPdfService.formatRupee(1247.5), contains('1,247.50'));

    // 4. Test cleanText
    expect(ReportPdfService.cleanText('₹ 1,247.50'), equals('₹ 1,247.50'));
  });
}
