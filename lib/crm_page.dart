import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart'; // Add this import
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Add this import
import 'dart:convert'; // Add this import for jsonEncode
import 'lead_detail_page.dart';
import 'new_lead_page.dart';

class CrmPage extends StatefulWidget {
  const CrmPage({super.key});

  @override
  State<CrmPage> createState() => _CrmPageState();
}

class _CrmPageState extends State<CrmPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  List<dynamic> _leads = [];
  bool _leadsLoading = false;
  String _currentFilterStatus = 'All'; // Add this

  final List<String> _titles = ['Lead', 'Appointment', 'Report'];

  final List<List<String>> _filters = [
    ['All', 'Lead', 'Converted', 'Follow Up', 'Not Interested'], // Lead filters (names only)
    ['All (0)', 'Today (0)', 'Due (0)', 'Upcoming (0)', 'Open (0)', 'Closed (0)'], // Appointment filters
    [], // No filters for Report tab yet
  ];

  @override
  void initState() {
    super.initState();
    _fetchLeads(); // Call fetch leads on init
  }

  Future<void> _fetchLeads() async {
    setState(() {
      _leadsLoading = true;
    });

    try {
      final sid = await _secureStorage.read(key: 'sid');
      if (sid == null) {
        Get.snackbar('Error', 'Session expired. Please log in again.');
        return;
      }

      final response = await _dio.get(
        'https://mysahayog.com/api/resource/Lead',
        queryParameters: {
          'fields': jsonEncode([
            'name',
            'first_name',
            'status',
            'mobile_no',
            'custom_branch',
            'source',
            'modified',
            'custom_product_table',
          ]),
        },
        options: Options(
          headers: {'Cookie': 'sid=$sid'},
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _leads = response.data['data'];

          // Calculate counts for Lead filters
          int allCount = _leads.length;
          int leadCount = _leads.where((lead) => lead['status'] == 'Lead').length;
          int convertedCount = _leads.where((lead) => lead['status'] == 'Converted').length;
          int followUpCount = _leads.where((lead) => lead['status'] == 'Follow Up').length;
          int notInterestedCount = _leads.where((lead) => lead['status'] == 'Not Interested').length;

          // Update the _filters list for the Lead tab (index 0)
          _filters[0] = [
            'All ($allCount)',
            'Lead ($leadCount)',
            'Converted ($convertedCount)',
            'Follow Up ($followUpCount)',
            'Not Interested ($notInterestedCount)',
          ];
        });
      } else {
        Get.snackbar('Error', 'Failed to fetch leads');
      }
    } on DioException catch (e) {
      Get.snackbar('Error', e.response?.data['message'] ?? 'An error occurred while fetching leads');
    } finally {
      setState(() {
        _leadsLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _currentFilterStatus = 'All'; // Reset filter when changing tabs
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate filtered leads here for displaying count
    final List<dynamic> currentFilteredLeads = _selectedIndex == 0
        ? (_currentFilterStatus == 'All'
            ? _leads
            : _leads.where((lead) => lead['status'] == _currentFilterStatus).toList())
        : [];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: const Color(0xFF006767),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: false,
                    trackVisibility: false,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Wrap(
                        spacing: 8.0,
                        children: _filters[_selectedIndex]
                            .map((filter) {
                              // Extract status from "Status (Count)" format
                              final status = filter.split(' (')[0];
                              return ChoiceChip(
                                label: Text(filter),
                                selected: _currentFilterStatus == status,
                                onSelected: (selected) {
                                  setState(() {
                                    _currentFilterStatus = status;
                                  });
                                },
                              );
                            })
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                  _currentFilterStatus = 'All'; // Reset filter when changing tabs
                });
              },
              children: [
                _buildLeadTab(),
                _buildTabPage('Appointment'),
                _buildTabPage('Report'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text('Showing ${currentFilteredLeads.length} of ${_leads.length}'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.to(() => NewLeadPage(onLeadCreated: _fetchLeads));
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'New Lead',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006767),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Lead',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Report',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildLeadTab() {
    if (_leadsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_leads.isEmpty) {
      return const Center(child: Text('No Leads Found'));
    }

    final List<dynamic> _filteredLeads = _currentFilterStatus == 'All'
        ? _leads
        : _leads.where((lead) => lead['status'] == _currentFilterStatus).toList();

    if (_filteredLeads.isEmpty) {
      return Center(child: Text('No ${_currentFilterStatus} Leads Found'));
    }

    return ListView.builder(
      itemCount: _filteredLeads.length,
      itemBuilder: (context, index) {
        final lead = _filteredLeads[index];
        return InkWell( // Added InkWell
          onTap: () {
            Get.to(() => LeadDetailPage(leadName: lead['name'])); // Navigate to LeadDetailPage
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead['first_name'] ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  Text(lead['mobile_no'] ?? 'N/A'),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status: ${lead['status'] ?? 'N/A'}'),
                      Text('Branch: ${lead['custom_branch'] ?? 'N/A'}'),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('Modified: ${lead['modified'] != null ? lead['modified'].split(' ')[0] : 'N/A'}'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabPage(String title) {
    return Center(
      child: Text(
        '$title Content',
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}