import 'package:flutter/material.dart';

class CrmPage extends StatefulWidget {
  const CrmPage({super.key});

  @override
  State<CrmPage> createState() => _CrmPageState();
}

class _CrmPageState extends State<CrmPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<String> _titles = ['Appointment', 'Lead', 'Report'];

  final List<List<String>> _filters = [
    ['All (0)', 'Today (0)', 'Due (0)', 'Upcoming (0)', 'Open (0)', 'Closed (0)'],
    ['All (35)', 'Lead (22)', 'Converted (4)', 'Follow Up(5)', 'Not Interested (4)'],
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
                _buildTabPage('Appointment'),
                _buildTabPage('Lead'),
                _buildTabPage('Report'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Lead',
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
