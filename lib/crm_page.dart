import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CrmPage extends StatefulWidget {
  const CrmPage({super.key});

  @override
  State<CrmPage> createState() => _CrmPageState();
}

class _CrmPageState extends State<CrmPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<String> _titles = ['Lead', 'Appointment', 'Report'];

  final List<List<String>> _filters = [
    ['All (35)', 'Lead (22)', 'Converted (4)', 'Follow Up(5)', 'Not Interested (4)'], // Lead filters
    ['All (0)', 'Today (0)', 'Due (0)', 'Upcoming (0)', 'Open (0)', 'Closed (0)'], // Appointment filters
    [], // No filters for Report tab yet
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: 8.0,
                    children: _filters[_selectedIndex]
                        .map((filter) => Chip(label: Text(filter)))
                        .toList(),
                  ),
                ),
                const Text('Showing 0 of 0'),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: [
                _buildTabPage('Lead'),
                _buildTabPage('Appointment'),
                _buildTabPage('Report'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement new lead creation logic
                  Get.snackbar('New Lead', 'Add New Lead functionality here');
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

  Widget _buildTabPage(String title) {
    return Center(
      child: Text(
        '$title Content',
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}
