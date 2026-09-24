import 'package:flutter/material.dart';   
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/alert_model.dart';
import '../services/alert_service.dart';
import '../core/data/stock_data.dart';

import '../services/notification_service.dart';

class CreateAlertSheet extends StatefulWidget {
  final StockModel stock;

  const CreateAlertSheet({super.key, required this.stock});

  static Future<void> show(BuildContext context, StockModel stock) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateAlertSheet(stock: stock),
    );
  }

  @override
  State<CreateAlertSheet> createState() => _CreateAlertSheetState();
}

class _CreateAlertSheetState extends State<CreateAlertSheet> {
  AlertType _selectedType = AlertType.priceAbove;
  late TextEditingController _priceController;
  late TextEditingController _percentController;
  String _selectedSignal = 'BUY';

  @override
  void initState() {
    super.initState();
    // Default suggestion: 2% above current price
    final defaultTarget = (widget.stock.price * 1.02).toStringAsFixed(2);
    _priceController = TextEditingController(text: defaultTarget);
    _percentController = TextEditingController(text: '2.0');
  }

  @override
  void dispose() {
    _priceController.dispose();
    _percentController.dispose();
    super.dispose();
  }

  void _saveAlert() async {
    HapticFeedback.mediumImpact();
    double? targetPrice;
    double? targetPercent;

    if (_selectedType == AlertType.priceAbove || _selectedType == AlertType.priceBelow) {
      targetPrice = double.tryParse(_priceController.text.trim());
      if (targetPrice == null || targetPrice <= 0) {
        _showSnack('Please enter a valid target price');
        return;
      }
    } else if (_selectedType == AlertType.percentGain || _selectedType == AlertType.percentLoss) {
      targetPercent = double.tryParse(_percentController.text.trim());
      if (targetPercent == null || targetPercent <= 0) {
        _showSnack('Please enter a valid percentage');
        return;
      }
    }

    // Request system permission from Android OS / Browser
    await NotificationService.instance.requestPermission();

    final alert = PriceAlert(
      id: '${widget.stock.ticker}_${DateTime.now().millisecondsSinceEpoch}',
      ticker: widget.stock.ticker,
      stockName: widget.stock.fullName,
      type: _selectedType,
      targetPrice: targetPrice,
      targetPercent: targetPercent,
      targetSignal: _selectedType == AlertType.aiSignalShift ? _selectedSignal : null,
    );

    await AlertService.instance.addAlert(alert);

    // Trigger system notification to confirm alert is active
    NotificationService.instance.showNotification(
      id: alert.id.hashCode,
      title: '🎯 Price Alert Active: ${alert.ticker}',
      body: 'Tracking live market price. You will receive an instant push notification when ${alert.ticker} reaches ₹${(targetPrice ?? widget.stock.price).toStringAsFixed(2)}.',
      payload: alert.ticker,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Alert created: ${alert.title}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0066CC),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 12)),
        backgroundColor: const Color(0xFFFF3B3B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat('₹#,##,##0.00', 'en_IN');
    final stockAlerts = AlertService.instance.alerts
        .where((a) => a.ticker.toUpperCase() == widget.stock.ticker.toUpperCase())
        .toList();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A374A) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066CC).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFF0066CC),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Alert for ${widget.stock.ticker}',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Current Price: ${currencyFormatter.format(widget.stock.price)}',
                        style: GoogleFonts.robotoMono(
                          fontSize: 12,
                          color: widget.stock.isPositive
                              ? const Color(0xFF00C853)
                              : const Color(0xFFFF3B3B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Trigger Type Tabs
            Text(
              'Alert Trigger Type',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8892A4),
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTypeChip(AlertType.priceAbove, 'Price Above', Icons.trending_up_rounded),
                _buildTypeChip(AlertType.priceBelow, 'Price Below', Icons.trending_down_rounded),
                _buildTypeChip(AlertType.percentGain, '+% Gain', Icons.bolt_rounded),
                _buildTypeChip(AlertType.aiSignalShift, 'AI Signal Shift', Icons.psychology_rounded),
                _buildTypeChip(AlertType.rsiOversold, 'RSI < 30 (Oversold)', Icons.waves_rounded),
              ],
            ),
            const SizedBox(height: 18),

            // Target Input Fields
            if (_selectedType == AlertType.priceAbove || _selectedType == AlertType.priceBelow) ...[
              Text(
                'Target Price (₹)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.robotoMono(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: GoogleFonts.robotoMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0066CC),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 8),
              // Preset suggestions
              Row(
                children: [
                  _presetButton('+1%', 1.01),
                  const SizedBox(width: 8),
                  _presetButton('+2%', 1.02),
                  const SizedBox(width: 8),
                  _presetButton('+5%', 1.05),
                  const SizedBox(width: 8),
                  _presetButton('-2%', 0.98),
                ],
              ),
            ] else if (_selectedType == AlertType.percentGain || _selectedType == AlertType.percentLoss) ...[
              Text(
                'Trigger Percentage (%)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _percentController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.robotoMono(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  suffixText: '%',
                  suffixStyle: GoogleFonts.robotoMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0066CC),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ] else if (_selectedType == AlertType.aiSignalShift) ...[
              Text(
                'Notify when AI signal becomes:',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _signalOption('BUY', const Color(0xFF00C853)),
                  const SizedBox(width: 10),
                  _signalOption('HOLD', const Color(0xFFFF8C00)),
                  const SizedBox(width: 10),
                  _signalOption('SELL', const Color(0xFFFF3B3B)),
                ],
              ),
            ] else if (_selectedType == AlertType.rsiOversold) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066CC).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF0066CC), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You will receive an alert as soon as the 14-period RSI dips below 30 (extreme oversold condition, potential bullish reversal).',
                        style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAlert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_alert_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Create Live Alert',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),

            if (stockAlerts.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Active Alerts for ${widget.stock.ticker}',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),
              ...stockAlerts.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(
                      a.isTriggered ? Icons.check_circle_rounded : Icons.alarm_on_rounded,
                      size: 18,
                      color: a.isTriggered ? const Color(0xFF00C853) : const Color(0xFF0066CC),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          if (a.isTriggered)
                            Text(
                              'Triggered! ${a.triggerMessage ?? ""}',
                              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF00C853)),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFFF3B3B)),
                      onPressed: () async {
                        await AlertService.instance.deleteAlert(a.id);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _presetButton(String label, double multiplier) {
    return InkWell(
      onTap: () {
        final newPrice = (widget.stock.price * multiplier).toStringAsFixed(2);
        _priceController.text = newPrice;
        HapticFeedback.selectionClick();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0066CC).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0066CC),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(AlertType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 14,
        color: isSelected ? Colors.white : const Color(0xFF8892A4),
      ),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF8892A4),
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF0066CC),
      onSelected: (val) {
        if (val) {
          HapticFeedback.selectionClick();
          setState(() => _selectedType = type);
        }
      },
    );
  }

  Widget _signalOption(String signal, Color color) {
    final isSelected = _selectedSignal == signal;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedSignal = signal);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: isSelected ? 2 : 1),
          ),
          child: Center(
            child: Text(
              signal,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
