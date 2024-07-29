import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'scan_screen.dart';
import 'document_detail_screen.dart';
import '../services/database_service.dart';
import '../models/document_model.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Document> _documents = [];
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategory;
  List<String> _categories = ['All', 'Work', 'Personal', 'Receipts', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    List<Document> documents = await _databaseService.getDocuments();
    setState(() {
      _documents = documents;
    });
  }

  Future<void> _searchDocuments() async {
    List<Document> searchResults = await _databaseService.searchDocuments(
      query: _searchController.text,
      startDate: _startDate,
      endDate: _endDate,
      category: _selectedCategory == 'All' ? null : _selectedCategory,
    );
    setState(() {
      _documents = searchResults;
    });
  }

  void _showDatePicker(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      _searchDocuments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ProScan'),
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ScanScreen()),
              );
              if (result == true) {
                _loadDocuments();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Documents',
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => _searchDocuments(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                child: Text(_startDate == null
                    ? 'Start Date'
                    : DateFormat('yyyy-MM-dd').format(_startDate!)),
                onPressed: () => _showDatePicker(true),
              ),
              ElevatedButton(
                child: Text(_endDate == null
                    ? 'End Date'
                    : DateFormat('yyyy-MM-dd').format(_endDate!)),
                onPressed: () => _showDatePicker(false),
              ),
              DropdownButton<String>(
                value: _selectedCategory ?? 'All',
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                  _searchDocuments();
                },
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.description),
                  title: Text(_documents[index].title),
                  subtitle: Text(
                      '${_documents[index].category} - ${DateFormat('yyyy-MM-dd').format(_documents[index].dateCreated)}'),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DocumentDetailScreen(document: _documents[index]),
                      ),
                    );
                    _loadDocuments();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
