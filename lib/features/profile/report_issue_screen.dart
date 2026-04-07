import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_back_button.dart';

class ReportIssueScreen extends ConsumerStatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  late TextEditingController _descriptionController;
  String _selectedCategory = 'Ride Quality';
  String _selectedSeverity = 'Medium';
  final List<String> _categories = [
    'Ride Quality',
    'Driver Behavior',
    'Vehicle Condition',
    'Safety Concern',
    'Payment Issue',
    'Other',
  ];
  final List<String> _severities = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0F0D) : const Color(0xFFF7F7F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(),
        title: Text(
          'Report an Issue',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 24,
                color: isDark ? Colors.white : Colors.black87,
              ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF17201C) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    AppColors.softStroke(isDark: isDark, highContrast: false),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We\'re sorry to hear you had an issue',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please provide details about what happened. Our support team will review and get back to you within 24 hours.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Issue Category', isDark),
          const SizedBox(height: 12),
          _buildDropdown(
            isDark: isDark,
            value: _selectedCategory,
            items: _categories,
            onChanged: (value) => setState(() => _selectedCategory = value),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Severity Level', isDark),
          const SizedBox(height: 12),
          _buildDropdown(
            isDark: isDark,
            value: _selectedSeverity,
            items: _severities,
            onChanged: (value) => setState(() => _selectedSeverity = value),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Description', isDark),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF17201C) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    AppColors.softStroke(isDark: isDark, highContrast: false),
              ),
            ),
            child: TextField(
              controller: _descriptionController,
              maxLines: 5,
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Describe what happened...',
                hintStyle: GoogleFonts.inter(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _submitReport(context, isDark),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Submit Report',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
        color: isDark ? Colors.white38 : Colors.black38,
      ),
    );
  }

  Widget _buildDropdown({
    required bool isDark,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17201C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.softStroke(isDark: isDark, highContrast: false),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          onChanged: (newValue) {
            if (newValue != null) onChanged(newValue);
          },
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _submitReport(BuildContext context, bool isDark) {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe the issue'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report submitted successfully!'),
        duration: Duration(seconds: 2),
      ),
    );

    _descriptionController.clear();
    Navigator.pop(context);
  }
}
