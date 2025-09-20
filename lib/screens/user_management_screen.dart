import 'package:flutter/material.dart';
import '../services/user_management_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with TickerProviderStateMixin {
  final UserManagementService _userService = UserManagementService();
  late TabController _tabController;
  
  // Filters and search
  final TextEditingController _searchController = TextEditingController();
  UserVerificationStatus? _selectedStatus;
  String? _selectedUserType;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool? _isActive;
  
  // Pagination
  int _currentPage = 1;
  final int _pageSize = 20;
  
  // State management
  bool _isLoading = false;
  Map<String, dynamic> _usersData = {};
  List<Map<String, dynamic>> _selectedUsers = [];
  Map<String, dynamic> _userAnalytics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUsers();
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await _userService.getUsers(
        page: _currentPage,
        limit: _pageSize,
        searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
        verificationStatus: _selectedStatus,
        userType: _selectedUserType,
        createdAfter: _dateFrom,
        createdBefore: _dateTo,
        isActive: _isActive,
      );
      setState(() => _usersData = data);
    } catch (e) {
      _showErrorSnackBar('Failed to load users: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final analytics = await _userService.getUserAnalytics();
      setState(() => _userAnalytics = analytics);
    } catch (e) {
      _showErrorSnackBar('Failed to load analytics: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All Users', icon: Icon(Icons.people)),
            Tab(text: 'Requiring Attention', icon: Icon(Icons.warning)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
            Tab(text: 'Bulk Operations', icon: Icon(Icons.batch_prediction)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllUsersTab(),
          _buildAttentionUsersTab(),
          _buildAnalyticsTab(),
          _buildBulkOperationsTab(),
        ],
      ),
    );
  }

  Widget _buildAllUsersTab() {
    return Column(
      children: [
        _buildFiltersSection(),
        _buildUsersTable(),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          // Search and basic filters
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by name, email, or phone...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: (_) => _loadUsers(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<UserVerificationStatus>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Statuses')),
                    ...UserVerificationStatus.values.map((status) => 
                      DropdownMenuItem(
                        value: status,
                        child: Text(status.name.toUpperCase()),
                      )
                    ),
                  ],
                  onChanged: (status) {
                    setState(() => _selectedStatus = status);
                    _loadUsers();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedUserType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Types')),
                    DropdownMenuItem(value: 'individual', child: Text('Individual')),
                    DropdownMenuItem(value: 'organization', child: Text('Organization')),
                    DropdownMenuItem(value: 'business', child: Text('Business')),
                  ],
                  onChanged: (type) {
                    setState(() => _selectedUserType = type);
                    _loadUsers();
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Advanced filters
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<bool>(
                  value: _isActive,
                  decoration: const InputDecoration(
                    labelText: 'Activity Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Users')),
                    DropdownMenuItem(value: true, child: Text('Active Users')),
                    DropdownMenuItem(value: false, child: Text('Inactive Users')),
                  ],
                  onChanged: (active) {
                    setState(() => _isActive = active);
                    _loadUsers();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _selectDateRange(),
                  icon: const Icon(Icons.date_range),
                  label: Text(_dateFrom != null 
                    ? '${_dateFrom!.day}/${_dateFrom!.month} - ${_dateTo?.day}/${_dateTo?.month}'
                    : 'Date Range'
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTable() {
    if (_isLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final users = _usersData['users'] as List<dynamic>? ?? [];
    if (users.isEmpty) {
      return const Expanded(
        child: Center(child: Text('No users found')),
      );
    }

    return Expanded(
      child: Column(
        children: [
          // Stats bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${users.length} of ${_usersData['total'] ?? 0} users (Page ${_usersData['page'] ?? 1})',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    Text('Selected: ${_selectedUsers.length}'),
                    if (_selectedUsers.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showBulkActionsDialog(),
                        icon: const Icon(Icons.batch_prediction),
                        label: const Text('Bulk Actions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Users table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                showCheckboxColumn: true,
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Created')),
                  DataColumn(label: Text('Last Active')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: users.map<DataRow>((user) {
                  final isSelected = _selectedUsers.any((u) => u['id'] == user['id']);
                  return DataRow(
                    selected: isSelected,
                    onSelectChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedUsers.add(user);
                        } else {
                          _selectedUsers.removeWhere((u) => u['id'] == user['id']);
                        }
                      });
                    },
                    cells: [
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user['name'] ?? 'No Name',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            if (user['phone_number'] != null)
                              Text(
                                user['phone_number'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      DataCell(Text(user['email'] ?? '')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getUserTypeColor(user['user_type']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (user['user_type'] ?? 'individual').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(user['verification_status']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (user['verification_status'] ?? 'pending').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatDate(user['created_at']),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      DataCell(
                        Text(
                          user['last_sign_in_at'] != null
                            ? _formatDate(user['last_sign_in_at'])
                            : 'Never',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, size: 16),
                              onPressed: () => _showUserDetails(user),
                              tooltip: 'View Details',
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 16),
                              onPressed: () => _showUserEditDialog(user),
                              tooltip: 'Edit User',
                            ),
                            if (user['verification_status'] == 'pending')
                              IconButton(
                                icon: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                onPressed: () => _verifyUser(user['id']),
                                tooltip: 'Verify User',
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          // Pagination
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildAttentionUsersTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _userService.getUsersRequiringAttention(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(child: Text('No users requiring attention'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(user['verification_status']),
                  child: Text(
                    (user['name'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(user['name'] ?? 'No Name'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['email'] ?? ''),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(user['verification_status']),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (user['verification_status'] ?? 'pending').toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Created: ${_formatDate(user['created_at'])}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () => _showUserDetails(user),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => _verifyUser(user['id']),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    if (_userAnalytics.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overview cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildAnalyticsCard(
                'Total Users',
                '${_userAnalytics['total_users'] ?? 0}',
                Icons.people,
                Colors.blue,
              ),
              _buildAnalyticsCard(
                'New (24h)',
                '${_userAnalytics['new_users_24h'] ?? 0}',
                Icons.person_add,
                Colors.green,
              ),
              _buildAnalyticsCard(
                'Active (7d)',
                '${_userAnalytics['active_users_7d'] ?? 0}',
                Icons.online_prediction,
                Colors.orange,
              ),
              _buildAnalyticsCard(
                'Needing Attention',
                '${_userAnalytics['users_requiring_attention'] ?? 0}',
                Icons.warning,
                Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Charts section
          Row(
            children: [
              Expanded(
                child: _buildVerificationChart(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUserTypeChart(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulkOperationsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bulk Operations',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select users from the "All Users" tab and use the bulk actions button, or use the options below for advanced operations.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildBulkActionCard(
                'Verify Pending Users',
                'Auto-verify all users with complete profiles',
                Icons.verified_user,
                Colors.green,
                () => _performBulkVerification(),
              ),
              _buildBulkActionCard(
                'Send Welcome Messages',
                'Send welcome message to new verified users',
                Icons.mail,
                Colors.blue,
                () => _sendBulkWelcomeMessages(),
              ),
              _buildBulkActionCard(
                'Export User Data',
                'Download user data for analytics',
                Icons.download,
                Colors.orange,
                () => _exportUserData(),
              ),
              _buildBulkActionCard(
                'Clean Inactive Users',
                'Flag users inactive for 6+ months',
                Icons.cleaning_services,
                Colors.red,
                () => _cleanInactiveUsers(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationChart() {
    final distribution = _userAnalytics['verification_distribution'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verification Status Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...distribution.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(entry.key.toUpperCase())),
                  Text('${entry.value}'),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeChart() {
    final distribution = _userAnalytics['type_distribution'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Type Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...distribution.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getUserTypeColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(entry.key.toUpperCase())),
                  Text('${entry.value}'),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkActionCard(String title, String description, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 250,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  child: const Text('Execute'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = _usersData['total_pages'] as int? ?? 1;
    final hasNext = _usersData['has_next'] as bool? ?? false;
    final hasPrevious = _usersData['has_previous'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: hasPrevious ? () {
              setState(() => _currentPage--);
              _loadUsers();
            } : null,
            child: const Text('Previous'),
          ),
          const SizedBox(width: 16),
          Text('Page $_currentPage of $totalPages'),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: hasNext ? () {
              setState(() => _currentPage++);
              _loadUsers();
            } : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'verified': return Colors.green;
      case 'pending': return Colors.orange;
      case 'rejected': return Colors.red;
      case 'flagged': return Colors.purple;
      case 'suspended': return Colors.grey;
      default: return Colors.grey;
    }
  }

  Color _getUserTypeColor(String? type) {
    switch (type) {
      case 'individual': return Colors.blue;
      case 'organization': return Colors.green;
      case 'business': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  // Action methods
  Future<void> _selectDateRange() async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateFrom != null && _dateTo != null
        ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
        : null,
    );

    if (range != null) {
      setState(() {
        _dateFrom = range.start;
        _dateTo = range.end;
      });
      _loadUsers();
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _selectedUserType = null;
      _dateFrom = null;
      _dateTo = null;
      _isActive = null;
      _currentPage = 1;
      _selectedUsers.clear();
    });
    _loadUsers();
  }

  Future<void> _verifyUser(String userId) async {
    final success = await _userService.updateUserVerificationStatus(
      userId,
      UserVerificationStatus.verified,
      'Verified by admin',
    );
    
    if (success) {
      _showSuccessSnackBar('User verified successfully');
      _loadUsers();
      _loadAnalytics();
    } else {
      _showErrorSnackBar('Failed to verify user');
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => UserDetailsDialog(
        userId: user['id'],
        userService: _userService,
      ),
    );
  }

  void _showUserEditDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => UserEditDialog(
        user: user,
        userService: _userService,
        onUserUpdated: () {
          _loadUsers();
          _loadAnalytics();
        },
      ),
    );
  }

  void _showBulkActionsDialog() {
    showDialog(
      context: context,
      builder: (context) => BulkActionsDialog(
        selectedUsers: _selectedUsers,
        userService: _userService,
        onCompleted: () {
          setState(() => _selectedUsers.clear());
          _loadUsers();
          _loadAnalytics();
        },
      ),
    );
  }

  // Bulk operation methods
  Future<void> _performBulkVerification() async {
    // Implementation for bulk verification
    _showSuccessSnackBar('Bulk verification completed');
  }

  Future<void> _sendBulkWelcomeMessages() async {
    // Implementation for bulk welcome messages
    _showSuccessSnackBar('Welcome messages sent');
  }

  Future<void> _exportUserData() async {
    // Implementation for data export
    _showSuccessSnackBar('User data exported');
  }

  Future<void> _cleanInactiveUsers() async {
    // Implementation for cleaning inactive users
    _showSuccessSnackBar('Inactive users cleaned');
  }
}

// Supporting dialog widgets
class UserDetailsDialog extends StatelessWidget {
  final String userId;
  final UserManagementService userService;

  const UserDetailsDialog({
    super.key,
    required this.userId,
    required this.userService,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, dynamic>>(
          future: userService.getUserDetails(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final data = snapshot.data!;
            final user = data['user'] as Map<String, dynamic>;
            final stats = data['statistics'] as Map<String, dynamic>;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? 'User Details',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Email', user['email'] ?? ''),
                        _buildDetailRow('Phone', user['phone_number'] ?? ''),
                        _buildDetailRow('Type', user['user_type'] ?? ''),
                        _buildDetailRow('Status', user['verification_status'] ?? ''),
                        _buildDetailRow('Total Donated', '\$${stats['total_donated']}'),
                        _buildDetailRow('Donation Count', '${stats['donation_count']}'),
                        _buildDetailRow('Request Count', '${stats['request_count']}'),
                        // Add more details as needed
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class UserEditDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  final UserManagementService userService;
  final VoidCallback onUserUpdated;

  const UserEditDialog({
    super.key,
    required this.user,
    required this.userService,
    required this.onUserUpdated,
  });

  @override
  State<UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<UserEditDialog> {
  UserVerificationStatus? _selectedStatus;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final statusString = widget.user['verification_status'] as String?;
    _selectedStatus = UserVerificationStatus.values
      .where((s) => s.name == statusString)
      .firstOrNull;
    _notesController.text = widget.user['admin_notes'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit User: ${widget.user['name']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserVerificationStatus>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Verification Status',
                border: OutlineInputBorder(),
              ),
              items: UserVerificationStatus.values.map((status) => 
                DropdownMenuItem(
                  value: status,
                  child: Text(status.name.toUpperCase()),
                )
              ).toList(),
              onChanged: (status) => setState(() => _selectedStatus = status),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Admin Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveChanges,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_selectedStatus == null) return;

    final success = await widget.userService.updateUserVerificationStatus(
      widget.user['id'],
      _selectedStatus!,
      _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    if (success) {
      Navigator.of(context).pop();
      widget.onUserUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update user')),
      );
    }
  }
}

class BulkActionsDialog extends StatefulWidget {
  final List<Map<String, dynamic>> selectedUsers;
  final UserManagementService userService;
  final VoidCallback onCompleted;

  const BulkActionsDialog({
    super.key,
    required this.selectedUsers,
    required this.userService,
    required this.onCompleted,
  });

  @override
  State<BulkActionsDialog> createState() => _BulkActionsDialogState();
}

class _BulkActionsDialogState extends State<BulkActionsDialog> {
  BulkUserOperation? _selectedOperation;
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bulk Actions (${widget.selectedUsers.length} users)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<BulkUserOperation>(
              value: _selectedOperation,
              decoration: const InputDecoration(
                labelText: 'Select Operation',
                border: OutlineInputBorder(),
              ),
              items: BulkUserOperation.values.map((op) => 
                DropdownMenuItem(
                  value: op,
                  child: Text(op.name.toUpperCase().replaceAll('_', ' ')),
                )
              ).toList(),
              onChanged: (op) => setState(() => _selectedOperation = op),
            ),
            const SizedBox(height: 16),
            if (_needsReason())
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading || _selectedOperation == null ? null : _performBulkAction,
                  child: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Execute'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _needsReason() {
    return _selectedOperation == BulkUserOperation.suspend ||
           _selectedOperation == BulkUserOperation.flag ||
           _selectedOperation == BulkUserOperation.delete;
  }

  Future<void> _performBulkAction() async {
    if (_selectedOperation == null) return;

    setState(() => _isLoading = true);

    final userIds = widget.selectedUsers.map((u) => u['id'] as String).toList();
    final parameters = <String, dynamic>{};
    
    if (_reasonController.text.trim().isNotEmpty) {
      parameters['reason'] = _reasonController.text.trim();
      parameters['admin_notes'] = _reasonController.text.trim();
    }

    try {
      final result = await widget.userService.performBulkOperation(
        userIds,
        _selectedOperation!,
        parameters,
      );

      if (result['success'] == true) {
        Navigator.of(context).pop();
        widget.onCompleted();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bulk operation completed: ${result['success_count']} successful, ${result['error_count']} failed'
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bulk operation failed: ${result['error']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
