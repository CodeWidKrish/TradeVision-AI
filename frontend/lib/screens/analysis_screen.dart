import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/data/stock_data.dart';
import '../widgets/ticker_logo.dart';
import '../widgets/animated_press_card.dart';
import '../widgets/real_stock_chart.dart';

class AnalysisScreen extends StatefulWidget {
  final StockModel currentStock;
  final Function(StockModel)? onSelectStock;

  const AnalysisScreen({
    super.key,
    required this.currentStock,
    this.onSelectStock,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  late StockModel _selectedStock;

  // Chart upload state
  String? _uploadedFileName;
  PlatformFile? _uploadedFile;
  bool _isAnalyzing = false;
  String? _analysisResult;

  @override
  void initState() {
    super.initState();
    _selectedStock = widget.currentStock;
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: kIsWeb ? FileType.image : FileType.custom,
        allowedExtensions: kIsWeb
            ? null
            : [
                'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'heif',
                'pdf', 'csv', 'xlsx',
              ],
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Client-side file size check (max 10MB)
        if (file.size > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File too large. Maximum allowed size is 10MB.'),
                backgroundColor: Color(0xFFFF3B3B),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        setState(() {
          _uploadedFile = file;
          _uploadedFileName = file.name;
          _analysisResult = null;
        });
        await _analyzeChart();
      }
    } catch (e) {
      debugPrint('File picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF3B3B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _analyzeChart() async {
    if (_uploadedFile == null) return;
    setState(() => _isAnalyzing = true);

    // Simulate AI analysis — replace with real API call later
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isAnalyzing = false;
      _analysisResult =
          'Chart shows a bullish flag pattern forming near the support zone of Rs 2,845. '
          'RSI at 62 indicates healthy momentum without being overbought. '
          'Volume confirms breakout potential. '
          'Suggested action: BUY on breakout above Rs 2,900 with stop loss at Rs 2,810.';
    });
  }

  void _showBacktestDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.analytics, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Backtest ${_selectedStock.ticker}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: theme.colorScheme.onSurface)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('3-Year Quantitative Backtest Results:', style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 10),
              _buildBacktestMetric('Simulated CAGR Return', '+28.4% / yr', AppColors.gain),
              _buildBacktestMetric('Win Rate (Profit Factor)', '74.2% (1.92)', AppColors.gain),
              _buildBacktestMetric('Max Peak-to-Trough Drawdown', '-11.6%', AppColors.loss),
              _buildBacktestMetric('Sharpe Ratio', '2.14 (Superior)', theme.colorScheme.primary),
            ],
          ),
          actions: [
            AnimatedPressCard(
              onTap: () => Navigator.pop(context),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
                child: const Text('CLOSE BACKTEST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBacktestMetric(String label, String val, Color color) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
          Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  void _showPriceAlertSheet() {
    final theme = Theme.of(context);
    double targetPrice = _selectedStock.price * 1.05;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set Price Alert for ${_selectedStock.ticker}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text('Current Price: ${_selectedStock.priceFormatted}', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.65), fontWeight: FontWeight.w600)),
                  Divider(height: 20, color: theme.dividerColor),
                  Text('Target Alert Price: Rs ${targetPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                  Slider(
                    value: targetPrice,
                    min: _selectedStock.price * 0.8,
                    max: _selectedStock.price * 1.3,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) => setModalState(() => targetPrice = val),
                  ),
                  const SizedBox(height: 12),
                  AnimatedPressCard(
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Price alert set for ${_selectedStock.ticker} at Rs ${targetPrice.toStringAsFixed(2)}'),
                              backgroundColor: theme.colorScheme.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
                        child: const Text('CREATE PRICE ALERT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Dropdown Selector
              Padding(
                padding: const EdgeInsets.fromLTRB(AppDim.screenH, 16, AppDim.screenH, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI Analytics',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    // Stock Dropdown Selector
                    PopupMenuButton<StockModel>(
                      onSelected: (stock) {
                        setState(() {
                          _selectedStock = stock;
                        });
                        if (widget.onSelectStock != null) {
                          widget.onSelectStock!(stock);
                        }
                      },
                      itemBuilder: (context) {
                        return StockRepository.stocks.map((s) {
                          return PopupMenuItem<StockModel>(
                            value: s,
                            child: Row(
                              children: [
                                TickerLogo(
                                  ticker: s.ticker,
                                  logoUrl: s.logoUrl,
                                  logoColor: s.logoColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(s.ticker, style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                              ],
                            ),
                          );
                        }).toList();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.dividerColor, width: 1.2),
                        ),
                        child: Row(
                          children: [
                            TickerLogo(
                              ticker: _selectedStock.ticker,
                              logoUrl: _selectedStock.logoUrl,
                              logoColor: _selectedStock.logoColor,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedStock.ticker,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── 0. Live Technical Chart (Uniform across all screens) ────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppDim.screenH),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor, width: 1.2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            TickerLogo(
                              ticker: _selectedStock.ticker,
                              logoUrl: _selectedStock.logoUrl,
                              logoColor: _selectedStock.logoColor,
                              size: 26,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_selectedStock.ticker} 1D Chart',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'LIVE 1D',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    RealStockChart(
                      ticker: _selectedStock.ticker,
                      period: '1D',
                      showHeader: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 1. AI Chart Analyser Upload Card (NEW) ──────────────
              _buildChartUploadCard(isDark),

              const SizedBox(height: 16),

              // ── 2. AI Technical Thesis Card ──────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: AppDim.screenH),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor, width: 1.2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'AI Suggestion: ${_selectedStock.aiSignal == "BUY" ? "Consider Buying" : _selectedStock.aiSignal == "SELL" ? "Consider Selling" : "Wait & Watch"}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: _selectedStock.isPositive ? AppColors.gain : AppColors.loss,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '92% Confidence',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _selectedStock.aiReason,
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 3. Derivatives & Option Chain ────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppDim.screenH),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Options Market Data',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Mood: Bullish',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.gain),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Call Active: 4.2M', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.65), fontWeight: FontWeight.w600)),
                        Text('Put Active: 5.2M', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.65), fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 6,
                        child: Row(
                          children: [
                            Expanded(flex: 45, child: Container(color: AppColors.loss)),
                            Expanded(flex: 55, child: Container(color: AppColors.gain)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 4. Interactive Action Buttons Bar ─────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDim.screenH),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedPressCard(
                        onTap: _showBacktestDialog,
                        child: ElevatedButton.icon(
                          onPressed: _showBacktestDialog,
                          icon: const Icon(Icons.speed_rounded, size: 15, color: Colors.white),
                          label: const Text(
                            'Backtest Strategy',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AnimatedPressCard(
                        onTap: _showPriceAlertSheet,
                        child: OutlinedButton.icon(
                          onPressed: _showPriceAlertSheet,
                          icon: Icon(Icons.add_alert_rounded, size: 15, color: theme.colorScheme.primary),
                          label: Text(
                            'Set Price Alert',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.colorScheme.primary, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 5. Company Fundamentals ───────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDim.screenH),
                child: Text('Company Fundamentals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDim.screenH),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.65,
                  children: [
                    _buildMetricTile('Price-to-Earnings (P/E)', _selectedStock.peRatio, 'Sector Avg: 26.4'),
                    _buildMetricTile('Company Size (Market Value)', _selectedStock.marketCap, 'Large Cap'),
                    _buildMetricTile('1-Year Highest Price', _selectedStock.high52, 'Peak High'),
                    _buildMetricTile('1-Year Lowest Price', _selectedStock.low52, 'Trough Low'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _BeginnerExplainerSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Chart Upload Card Widget ──────────────────────────────────────────
  Widget _buildChartUploadCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDim.screenH),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image_search_rounded,
                    size: 18, color: Color(0xFF8B5CF6)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Chart Analyser',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    'Upload any stock chart for instant AI reading',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF8892A4),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Upload area (show when no file uploaded)
          if (_uploadedFileName == null)
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E2A3A)
                      : const Color(0xFFF4F6F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.30),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_upload_outlined,
                        size: 28, color: Color(0xFF8B5CF6)),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to upload chart screenshot',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                    Text(
                      'PNG, JPG supported',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF8892A4),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Uploaded file preview
          if (_uploadedFileName != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2A3A)
                    : const Color(0xFFF4F6F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _uploadedFile?.bytes != null
                        ? Image.memory(
                            _uploadedFile!.bytes!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.insert_photo_rounded,
                              size: 20,
                              color: Color(0xFF8B5CF6),
                            ),
                          )
                        : const Icon(
                            Icons.insert_photo_rounded,
                            size: 20,
                            color: Color(0xFF8B5CF6),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _uploadedFileName!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Chart uploaded successfully',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF00C853),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: Text('Change Image',
                  style: GoogleFonts.inter(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0066CC),
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 32),
              ),
            ),
          ],

          // Analysis loading
          if (_isAnalyzing) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Analysing your chart...',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF8892A4),
                  ),
                ),
              ],
            ),
          ],

          // Analysis result
          if (_analysisResult != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF00C853).withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          size: 14, color: Color(0xFF00C853)),
                      const SizedBox(width: 6),
                      Text(
                        'AI Chart Reading',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00C853),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _analysisResult!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFFE8ECF0)
                          : const Color(0xFF1A1A2E),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, String subtitle) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF8892A4),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.robotoMono(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF8892A4),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget — tap to get simple explanation:
class TermTooltip extends StatelessWidget {
  final String term;
  final String explanation;
  const TermTooltip({super.key, required this.term, required this.explanation});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF111827) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(term,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
          content: Text(explanation,
            style: GoogleFonts.inter(fontSize: 14, height: 1.5,
              color: const Color(0xFF8892A4))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Got it!',
                style: GoogleFonts.inter(color: const Color(0xFF0066CC),
                    fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(term, style: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFF8892A4))),
          const SizedBox(width: 4),
          const Icon(Icons.help_outline_rounded,
              size: 13, color: Color(0xFF8892A4)),
        ],
      ),
    );
  }
}

class _BeginnerExplainerSection extends StatelessWidget {
  const _BeginnerExplainerSection();

  final List<Map<String, String>> _explainers = const [
    {
      'term': 'P/E Ratio — What is it?',
      'simple': 'Think of P/E as the price you pay for every ₹1 the company earns. '
          'A P/E of 28 means you are paying ₹28 for every ₹1 of profit. '
          'Lower P/E = cheaper stock. Higher P/E = market expects big growth.',
      'icon': 'info',
    },
    {
      'term': '52-Week High & Low — What does it mean?',
      'simple': 'The highest and lowest price this stock reached in the last 1 year. '
          'If a stock is near its 52W high, it is performing well. '
          'Near 52W low means it has fallen a lot.',
      'icon': 'show_chart',
    },
    {
      'term': 'Market Cap — What is it?',
      'simple': 'Market Cap tells you how big the company is. '
          'Large Cap (above ₹20,000 Cr) = big, stable companies like Reliance. '
          'Mid Cap = medium sized. Small Cap = smaller, riskier companies.',
      'icon': 'business',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Learn — What do these numbers mean?',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
            ),
          ),
        ),
        ..._explainers.map(
          (e) => Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E2733)
                    : const Color(0xFFE2E6EA),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e['term']!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFE8ECF0)
                        : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  e['simple']!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF8892A4),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
