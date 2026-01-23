import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart'; // Add this import
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Add this import
import 'dart:convert'; // Add this import for jsonEncode
import 'lead_detail_page.dart';
import 'new_lead_page.dart';
import 'appointment_detail_page.dart';
import 'new_appointment_page.dart';

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

  List<dynamic> _appointments = [];
  bool _appointmentsLoading = false;

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
    if (index == 1) { // Appointment tab
      _fetchAppointments();
    }
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
                if (index == 1) { // Appointment tab
                  _fetchAppointments();
                }
                setState(() {
                  _selectedIndex = index;
                  _currentFilterStatus = 'All'; // Reset filter when changing tabs
                });
              },
              children: [
                _buildLeadTab(),
                _buildAppointmentTab(),
                _buildTabPage('Report'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text('Showing ${currentFilteredLeads.length} of ${_leads.length}'),
          ),
          _buildActionButtons(),
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

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: _selectedIndex == 0
            ? ElevatedButton.icon(
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
              )
            : _selectedIndex == 1
                ? ElevatedButton.icon(
                    onPressed: () {
                      Get.to(() => NewAppointmentPage(onAppointmentCreated: _fetchAppointments));
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'New Appointment',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006767),
                    ),
                  )
                : const SizedBox.shrink(),
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

  Future<void> _fetchAppointments() async {
    setState(() {
      _appointmentsLoading = true;
    });

    try {
      final sid = await _secureStorage.read(key: 'sid');
      if (sid == null) {
        Get.snackbar('Error', 'Session expired.');
        return;
      }

      final response = await _dio.get(
        'https://mysahayog.com/api/resource/Appointment',
        queryParameters: {
          'fields': jsonEncode([
            'name',
            'customer_name',
            'scheduled_time',
            'status',
            'modified',
          ]),
        },
        options: Options(
          headers: {'Cookie': 'sid=$sid'},
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _appointments = response.data['data'];

          // --- Start Count Calculation ---
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          int allCount = _appointments.length;
          int todayCount = 0;
          int dueCount = 0;
          int upcomingCount = 0;
          int openCount = _appointments.where((a) => a['status'] == 'Open').length;
          int closedCount = _appointments.where((a) => a['status'] == 'Closed').length;

          for (var appt in _appointments) {
            final scheduledTimeString = appt['scheduled_time'];
            if (scheduledTimeString != null) {
              try {
                final scheduledTime = DateTime.parse(scheduledTimeString);
                final scheduledDate = DateTime(scheduledTime.year, scheduledTime.month, scheduledTime.day);

                if (scheduledDate.isAtSameMomentAs(today)) {
                  todayCount++;
                }
                
                if (scheduledTime.isAfter(now)) {
                  upcomingCount++;
                }

                if (scheduledTime.isBefore(now) && appt['status'] != 'Closed') {
                   dueCount++;
                }

              } catch (e) {
                // Ignore if date format is invalid
              }
            }
          }

          // Update the _filters list for the Appointment tab (index 1)
          _filters[1] = [
            'All ($allCount)',
            'Today ($todayCount)',
            'Due ($dueCount)',
            'Upcoming ($upcomingCount)',
            'Open ($openCount)',
            'Closed ($closedCount)',
          ];
          // --- End Count Calculation ---
        });
      }
    } on DioException catch (e) {
      Get.snackbar('Error', e.response?.data['message'] ?? 'An error occurred while fetching appointments');
    } finally {
      setState(() {
        _appointmentsLoading = false;
      });
    }
  }

  Widget _buildAppointmentTab() {
    if (_appointmentsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_appointments.isEmpty) {
      return const Center(child: Text('No Appointments Found'));
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<dynamic> filteredAppointments = _appointments.where((appt) {
      final status = _currentFilterStatus.split(' (')[0];
      if (status == 'All') {
        return true;
      }
      if (status == 'Open' || status == 'Closed') {
        return appt['status'] == status;
      }
      
      final scheduledTimeString = appt['scheduled_time'];
      if (scheduledTimeString != null) {
        try {
          final scheduledTime = DateTime.parse(scheduledTimeString);
          final scheduledDate = DateTime(scheduledTime.year, scheduledTime.month, scheduledTime.day);

          if (status == 'Today') {
            return scheduledDate.isAtSameMomentAs(today);
          }
          if (status == 'Upcoming') {
            return scheduledTime.isAfter(now);
          }
          if (status == 'Due') {
            return scheduledTime.isBefore(now) && appt['status'] != 'Closed';
          }
        } catch (e) {
          return false; // Don't show if date is invalid
        }
      }
      return false; // Don't show if no scheduled_time for date-based filters
    }).toList();
    
    if (filteredAppointments.isEmpty) {
      final status = _currentFilterStatus.split(' (')[0];
      return Center(child: Text('No $status Appointments Found'));
    }


    return ListView.builder(
      itemCount: filteredAppointments.length,
      itemBuilder: (context, index) {
        final appointment = filteredAppointments[index];
        return InkWell(
          onTap: () {
            Get.to(() => AppointmentDetailPage(appointment: appointment));
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment['customer_name'] ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  Text('Time: ${appointment['scheduled_time'] ?? 'N/A'}'),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status: ${appointment['status'] ?? 'N/A'}'),
                      Text('Modified: ${appointment['modified'] != null ? appointment['modified'].split(' ')[0] : 'N/A'}'),
                    ],
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