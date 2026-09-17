import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _symbolController =
      TextEditingController(text: 'AAPL');

  bool _isLoading = false;
  String? _errorMessage;

  StockModel? _stock;
  StockDetailModel? _stockDetail;
  RecommendationModel? _recommendation;
  OverviewModel? _overview;
  NewsModel? _news;
  IndicatorModel? _indicators;
  ChartModel? _chart;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _symbolController.dispose();
    super.dispose();
  }

  String get currentSymbol {
    final text = _symbolController.text.trim().toUpperCase();
    return text.isEmpty ? 'AAPL' : text;
  }

  Future<void> _loadDashboardData() async {
    final symbol = currentSymbol;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _apiService.fetchStock(symbol).catchError((_) => StockModel(symbol: symbol)),
        _apiService.fetchStockDetails(symbol).catchError((_) => StockDetailModel(symbol: symbol)),
        _apiService.fetchRecommendation(symbol).catchError((_) => RecommendationModel(symbol: symbol, decision: 'N/A', confidence: 0, reason: '', keyFactors: [])),
        _apiService.fetchOverview(symbol).catchError((_) => OverviewModel(
              stock: StockInfo(symbol: symbol),
              indicators: IndicatorInfo(symbol: symbol, signal: 'N/A'),
            )),
        _apiService.fetchNews(symbol).catchError((_) => NewsModel(symbol: symbol, articles: [])),
        _apiService.fetchIndicators(symbol).catchError((_) => IndicatorModel(symbol: symbol, signal: 'N/A')),
        _apiService.fetchChart(symbol).catchError((_) => ChartModel(symbol: symbol, points: [])),
      ]);

      setState(() {
        _stock = results[0] as StockModel?;
        _stockDetail = results[1] as StockDetailModel?;
        _recommendation = results[2] as RecommendationModel?;
        _overview = results[3] as OverviewModel?;
        _news = results[4] as NewsModel?;
        _indicators = results[5] as IndicatorModel?;
        _chart = results[6] as ChartModel?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load dashboard data: $e';
        _isLoading = false;
      });
    }
  }

  void _onQuickSymbolSelect(String symbol) {
    _symbolController.text = symbol;
    _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.show_chart_rounded, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text(
              'Stock Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _isLoading ? null : _loadDashboardData,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar Section
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _symbolController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'Enter Stock Symbol (e.g. AAPL, TSLA)',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            onSubmitted: (_) => _loadDashboardData(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _loadDashboardData,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.search),
                          label: const Text('Load'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Quick Select Ticker Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['AAPL', 'TSLA', 'MSFT', 'GOOGL', 'NVDA']
                            .map(
                              (ticker) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ActionChip(
                                  label: Text(ticker),
                                  backgroundColor:
                                      currentSymbol == ticker ? Colors.blue.shade100 : null,
                                  onPressed: () => _onQuickSymbolSelect(ticker),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Error Banner
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Responsive Layout Builder
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWideScreen = constraints.maxWidth > 850;

                        if (isWideScreen) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column
                              Expanded(
                                flex: 6,
                                child: Column(
                                  children: [
                                    StockSummaryCard(
                                      stockDetail: _stockDetail,
                                      stock: _stock,
                                      isLoading: _isLoading,
                                    ),
                                    const SizedBox(height: 16),
                                    ChartSectionWidget(
                                      chart: _chart,
                                      isLoading: _isLoading,
                                    ),
                                    const SizedBox(height: 16),
                                    IndicatorCard(
                                      indicators: _indicators ?? (
                                        _overview != null ? IndicatorModel(
                                          symbol: _overview!.indicators.symbol,
                                          rsi: _overview!.indicators.rsi,
                                          ma20: _overview!.indicators.ma20,
                                          ma50: _overview!.indicators.ma50,
                                          macd: _overview!.indicators.macd,
                                          signal: _overview!.indicators.signal,
                                        ) : null
                                      ),
                                      isLoading: _isLoading,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Right Column
                              Expanded(
                                flex: 6,
                                child: Column(
                                  children: [
                                    _buildStockDetailsSection(),
                                    const SizedBox(height: 16),
                                    RecommendationCard(
                                      recommendation: _recommendation,
                                      isLoading: _isLoading,
                                    ),
                                    const SizedBox(height: 16),
                                    NewsListWidget(
                                      news: _news,
                                      isLoading: _isLoading,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Mobile Single-Column Layout
                          return Column(
                            children: [
                              StockSummaryCard(
                                stockDetail: _stockDetail,
                                stock: _stock,
                                isLoading: _isLoading,
                              ),
                              const SizedBox(height: 16),
                              _buildStockDetailsSection(),
                              const SizedBox(height: 16),
                              ChartSectionWidget(
                                chart: _chart,
                                isLoading: _isLoading,
                              ),
                              const SizedBox(height: 16),
                              IndicatorCard(
                                indicators: _indicators ?? (
                                  _overview != null ? IndicatorModel(
                                    symbol: _overview!.indicators.symbol,
                                    rsi: _overview!.indicators.rsi,
                                    ma20: _overview!.indicators.ma20,
                                    ma50: _overview!.indicators.ma50,
                                    macd: _overview!.indicators.macd,
                                    signal: _overview!.indicators.signal,
                                  ) : null
                                ),
                                isLoading: _isLoading,
                              ),
                              const SizedBox(height: 16),
                              RecommendationCard(
                                recommendation: _recommendation,
                                isLoading: _isLoading,
                              ),
                              const SizedBox(height: 16),
                              NewsListWidget(
                                news: _news,
                                isLoading: _isLoading,
                              ),
                            ],
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockDetailsSection() {
    if (_isLoading) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final detail = _stockDetail;
    if (detail == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No stock details available.'),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Stock Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailTile('Open Price', detail.openPrice != null ? '\$${detail.openPrice!.toStringAsFixed(2)}' : 'N/A'),
                _buildDetailTile('High Price', detail.highPrice != null ? '\$${detail.highPrice!.toStringAsFixed(2)}' : 'N/A'),
                _buildDetailTile('Low Price', detail.lowPrice != null ? '\$${detail.lowPrice!.toStringAsFixed(2)}' : 'N/A'),
                _buildDetailTile('Volume', detail.volume != null ? detail.volume.toString() : 'N/A'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
