// FILE STATUS: EXPERIMENTAL
// REASON: Unreachable from main routing - secondary feature screen
// DATE_CLASSIFIED: 2025-12-29

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum SearchFilterType { all, events, users, communities, posts }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  SearchFilterType _selectedFilter = SearchFilterType.all;
  late TabController _tabController;
  List<String> _recentSearches = ['Konser Musik Jakarta', 'Workshop Design', 'Tech Meetup'];
  List<String> _trendingSearches = ['Fashion Week 2025', 'Startup Pitching', 'Art Exhibition'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    // TODO: Implement search logic
    Navigator.pushNamed(context, '/search-results', arguments: {
      'query': query,
      'filter': _selectedFilter,
    });
  }

  void _removeRecentSearch(int index) {
    setState(() {
      _recentSearches.removeAt(index);
    });
  }

  void _clearAllRecent() {
    setState(() {
      _recentSearches.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            Expanded(
              child: _searchController.text.isEmpty
                  ? _buildSearchSuggestions()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Cari event, user, komunitas...',
                  prefixIcon: const Icon(LucideIcons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: _performSearch,
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Filter Chips
          PopupMenuButton<SearchFilterType>(
            icon: Icon(LucideIcons.sliders, color: Colors.grey[700]),
            onSelected: (filter) {
              setState(() {
                _selectedFilter = filter;
                if (_searchController.text.isNotEmpty) {
                  _performSearch(_searchController.text);
                }
              });
            },
            itemBuilder: (context) => [
              _buildFilterItem(SearchFilterType.all, 'Semua'),
              _buildFilterItem(SearchFilterType.events, 'Event'),
              _buildFilterItem(SearchFilterType.users, 'User'),
              _buildFilterItem(SearchFilterType.communities, 'Komunitas'),
              _buildFilterItem(SearchFilterType.posts, 'Post'),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<SearchFilterType> _buildFilterItem(
    SearchFilterType type,
    String label,
  ) {
    return PopupMenuItem(
      value: type,
      child: Row(
        children: [
          Icon(
            _selectedFilter == type ? LucideIcons.check : LucideIcons.circle,
            size: 16,
            color: _selectedFilter == type ? const Color(0xFFBBC863) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_recentSearches.isNotEmpty) ...[
          _buildSectionHeader('Pencarian Terakhir', onClear: _clearAllRecent),
          const SizedBox(height: 8),
          ...List.generate(_recentSearches.length, (index) {
            return _buildRecentSearchItem(_recentSearches[index], index);
          }),
          const SizedBox(height: 24),
        ],
        _buildSectionHeader('Sedang Tren'),
        const SizedBox(height: 8),
        ...List.generate(_trendingSearches.length, (index) {
          return _buildTrendingSearchItem(_trendingSearches[index], index + 1);
        }),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onClear}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (onClear != null)
          TextButton(
            onPressed: onClear,
            child: const Text(
              'Hapus Semua',
              style: TextStyle(fontSize: 12, color: Color(0xFFBBC863)),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentSearchItem(String query, int index) {
    return ListTile(
      leading: Icon(LucideIcons.clock, size: 18, color: Colors.grey[600]),
      title: Text(query, style: const TextStyle(fontSize: 14)),
      trailing: IconButton(
        icon: Icon(LucideIcons.x, size: 16, color: Colors.grey[400]),
        onPressed: () => _removeRecentSearch(index),
      ),
      contentPadding: EdgeInsets.zero,
      onTap: () => _performSearch(query),
    );
  }

  Widget _buildTrendingSearchItem(String query, int rank) {
    return ListTile(
      leading: Text(
        '$rank',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: rank <= 3 ? const Color(0xFFBBC863) : Colors.grey[400],
        ),
      ),
      title: Text(query, style: const TextStyle(fontSize: 14)),
      leadingAndTrailingTextStyle: const TextStyle(fontSize: 14),
      contentPadding: EdgeInsets.zero,
      onTap: () => _performSearch(query),
    );
  }

  Widget _buildSearchResults() {
    // Placeholder for actual search results
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.search, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Mencari "${_searchController.text}"',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
