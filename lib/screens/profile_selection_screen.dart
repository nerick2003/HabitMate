import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'home_screen.dart';

class ProfileSelectionScreen extends StatefulWidget {
  final void Function(ThemeMode)? onThemeChanged;

  const ProfileSelectionScreen({super.key, this.onThemeChanged});

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    final users = await UserService.instance.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _selectUser(User user) async {
    await UserService.instance.setCurrentUser(user.id!);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(onThemeChanged: widget.onThemeChanged),
        ),
      );
    }
  }


  Future<void> _createNewProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateProfileScreen(),
      ),
    );
    if (result == true) {
      _loadUsers();
    }
  }

  Future<void> _editProfile(User user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateProfileScreen(user: user),
      ),
    );
    if (result == true) {
      _loadUsers();
    }
  }

  Future<void> _deleteProfile(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text('Are you sure you want to delete "${user.name}"? This will also delete all their habits.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && user.id != null) {
      await UserService.instance.deleteUser(user.id!);
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6C63FF),
              const Color(0xFF6C63FF).withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Text(
                            'HabitMate',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _users.isEmpty
                                ? 'Create your first profile to get started'
                                : 'Choose a profile to continue',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Profiles List
                    Expanded(
                      child: _users.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(32),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.person_add,
                                        size: 64,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'No Profiles Yet',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Create your first profile to start tracking your habits',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _users.length,
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Card(
                                    elevation: 0,
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: InkWell(
                                      onTap: () => _selectUser(user),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                _getAvatarIcon(user.avatar ?? 'person'),
                                                color: const Color(0xFF6C63FF),
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    user.name,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Theme.of(context).colorScheme.onSurface,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    user.email,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_vert),
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  _editProfile(user);
                                                } else if (value == 'delete') {
                                                  _deleteProfile(user);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.edit, size: 20),
                                                      SizedBox(width: 8),
                                                      Text('Edit'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete, size: 20, color: Colors.red),
                                                      SizedBox(width: 8),
                                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    // Add Profile Button
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: ElevatedButton.icon(
                        onPressed: _createNewProfile,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create New Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6C63FF),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  IconData _getAvatarIcon(String avatar) {
    switch (avatar) {
      case 'person':
        return Icons.person;
      case 'face':
        return Icons.face;
      case 'child_care':
        return Icons.child_care;
      case 'sports':
        return Icons.sports;
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      default:
        return Icons.person;
    }
  }
}

class CreateProfileScreen extends StatefulWidget {
  final User? user;

  const CreateProfileScreen({super.key, this.user});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedAvatar = 'person';

  final List<Map<String, dynamic>> _avatars = [
    {'icon': Icons.person, 'name': 'person'},
    {'icon': Icons.face, 'name': 'face'},
    {'icon': Icons.child_care, 'name': 'child_care'},
    {'icon': Icons.sports, 'name': 'sports'},
    {'icon': Icons.work, 'name': 'work'},
    {'icon': Icons.school, 'name': 'school'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _nameController.text = widget.user!.name;
      _emailController.text = widget.user!.email;
      _selectedAvatar = widget.user!.avatar ?? 'person';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final user = User(
        id: widget.user?.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        avatar: _selectedAvatar,
        createdAt: widget.user?.createdAt,
      );

      if (widget.user == null) {
        await UserService.instance.createUser(user);
      } else {
        await UserService.instance.updateUser(user);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user == null ? 'Create Profile' : 'Edit Profile'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Avatar Selection
            Text(
              'Choose Avatar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _avatars.map((avatar) {
                final isSelected = _selectedAvatar == avatar['name'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAvatar = avatar['name'] as String;
                    });
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6C63FF).withValues(alpha: 0.1)
                          : Colors.grey[100],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      avatar['icon'] as IconData,
                      color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[600],
                      size: 32,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter your name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Email Field
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            // Save Button
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(widget.user == null ? 'Create Profile' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

