import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import 'widgets/marker_selector.dart';
import 'widgets/multi_trend_chart.dart';
import 'widgets/ai_insight_card.dart';
import 'widgets/marker_stat_card.dart';
import '../../core/providers.dart';
import '../../core/models.dart';

class TrendDashboardPage extends ConsumerStatefulWidget {
  const TrendDashboardPage({super.key});

  @override
  ConsumerState<TrendDashboardPage> createState() => _TrendDashboardPageState();
}

class _TrendDashboardPageState extends ConsumerState<TrendDashboardPage> {
  final List<String> _selectedMarkers = [];
  bool _normalizeData = false;
  Map<String, List<LabReport>> _loadedData = {};
  bool _isLoading = false;

  void _onMarkersChanged(List<String> markers) {
    setState(() {
      _selectedMarkers.clear();
      _selectedMarkers.addAll(markers);
    });
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (_selectedMarkers.isEmpty) {
      setState(() => _loadedData = {});
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(labRepositoryProvider);
      final data = await repo.getMultiMarkerHistory(_selectedMarkers);
      setState(() => _loadedData = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prepare data for chart
    final trendService = ref.watch(trendAnalysisServiceProvider);
    final normalizedData = _normalizeData
        ? trendService.normalizeData(_loadedData)
        : null; // Chart widget handles raw vs normalized

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Advanced Analytics',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compare Markers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            MarkerSelector(
              selectedMarkers: _selectedMarkers,
              onChanged: _onMarkersChanged,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Health Trajectory',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (_selectedMarkers.length > 1)
                        Row(
                          children: [
                            const Text(
                              'Normalize',
                              style: TextStyle(fontSize: 12),
                            ),
                            Switch(
                              value: _normalizeData,
                              onChanged: (v) =>
                                  setState(() => _normalizeData = v),
                              activeThumbColor: AppColors.primary,
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 300,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _selectedMarkers.isEmpty
                        ? const Center(
                            child: Text(
                              'Select markers to compare',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : MultiTrendChart(
                            data: _loadedData,
                            normalizedData: normalizedData,
                            isNormalized: _normalizeData,
                          ),
                  ),
                ],
              ),
            ),
            if (_selectedMarkers.isNotEmpty && !_isLoading) ...[
              const Text(
                'Marker Summaries',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedMarkers.length,
                  itemBuilder: (context, index) {
                    final marker = _selectedMarkers[index];
                    final stats = trendService.calculateStats(
                      _loadedData[marker] ?? [],
                      marker,
                    );
                    return MarkerStatCard(stats: stats);
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
            if (_selectedMarkers.length > 1 && !_isLoading)
              AiInsightCard(data: _loadedData, markers: _selectedMarkers),
          ],
        ),
      ),
    );
  }
}
