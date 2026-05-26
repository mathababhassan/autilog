import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../child_profile/presentation/screens/child_profile_screen.dart';

class ParentProfileScreen extends StatelessWidget {
  const ParentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parents')
            .doc(uid)
            .snapshots(),
        builder: (context, parentSnap) {
          final parentData = parentSnap.hasData && parentSnap.data!.exists
              ? parentSnap.data!.data() as Map<String, dynamic>
              : <String, dynamic>{};

          final name = parentData['name'] as String? ?? 'Parent';
          final gender = parentData['gender'] as String? ?? '';
          final email =
              FirebaseAuth.instance.currentUser?.email ?? '';
          final photoPath =
              parentData['profilePhotoPath'] as String? ?? '';

          return CustomScrollView(
            slivers: [
              // ── Header ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _ProfileHeader(
                  name: name,
                  email: email,
                  gender: gender,
                  photoPath: photoPath,
                  uid: uid ?? '',
                ),
              ),

              // ── Children Section ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Children',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      GestureDetector(
                        onTap: () => context.push(Routes.childRegistration),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8A00),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Add Child',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Children List ─────────────────────────────────────────
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('parents')
                    .doc(uid)
                    .collection('children')
                    .snapshots(),
                builder: (context, childSnap) {
                  if (!childSnap.hasData ||
                      childSnap.data!.docs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: const Center(
                            child: Text(
                              'No children added yet.',
                              style: TextStyle(color: Colors.black45),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final children = childSnap.data!.docs;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final child = children[index].data()
                            as Map<String, dynamic>;
                        final childId = children[index].id;
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                          child: _ChildCard(
                            childId: childId,
                            parentId: uid ?? '',
                            data: child,
                          ),
                        );
                      },
                      childCount: children.length,
                    ),
                  );
                },
              ),

              // ── Account Actions ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      _AccountTile(
                        icon: Icons.lock_outline,
                        label: 'Change Password',
                        onTap: () =>
                            _showChangePasswordDialog(context),
                      ),
                      const SizedBox(height: 10),
                      _AccountTile(
                        icon: Icons.logout_rounded,
                        label: 'Log Out',
                        color: Colors.red,
                        onTap: () => _confirmLogout(context),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 32,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Change password dialog ───────────────────────────────────────────────

  void _showChangePasswordDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
        title: const Text('Change Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFFF8A00), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.black45)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.length >= 8) {
                await FirebaseAuth.instance.currentUser
                    ?.updatePassword(controller.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A00),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Update',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Logout confirmation ──────────────────────────────────────────────────

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.black45)),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) context.go(Routes.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Header
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatefulWidget {
  final String name;
  final String email;
  final String gender;
  final String photoPath;
  final String uid;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.gender,
    required this.photoPath,
    required this.uid,
  });

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  bool _isEditing = false;
  late final TextEditingController _nameController;
  String? _selectedGender;
  String? _newPhotoPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _selectedGender = widget.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _newPhotoPath = picked.path);
  }

  Future<void> _saveChanges() async {
    await FirebaseFirestore.instance
        .collection('parents')
        .doc(widget.uid)
        .update({
      'name': _nameController.text.trim(),
      'gender': _selectedGender,
      if (_newPhotoPath != null) 'profilePhotoPath': _newPhotoPath,
    });
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final photo = _newPhotoPath ?? widget.photoPath;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 16, 24, 28),
      decoration: const BoxDecoration(
        color: Color(0xFFFF8A00),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        children: [
          // ── Top row: back + title + edit ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Text(
                'My Profile',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  if (_isEditing) {
                    _saveChanges();
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isEditing ? 'Save' : 'Edit',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Avatar ────────────────────────────────────────────────────
          GestureDetector(
            onTap: _isEditing ? _pickPhoto : null,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  backgroundImage:
                      photo.isNotEmpty ? FileImage(File(photo)) : null,
                  child: photo.isEmpty
                      ? const Icon(Icons.person,
                          size: 48, color: Colors.white)
                      : null,
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 16, color: Color(0xFFFF8A00)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Name ──────────────────────────────────────────────────────
          if (_isEditing)
            TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color.fromARGB(255, 49, 175, 24),
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Your name',
                hintStyle: TextStyle(color: const Color.fromARGB(255, 17, 136, 13).withOpacity(0.6)),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            )
          else
            Text(
              widget.name,
              style: const TextStyle(
                  color: Color.fromARGB(255, 49, 173, 55),
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),

          const SizedBox(height: 4),
          Text(
            widget.email,
            style: TextStyle(
                color: Colors.white.withOpacity(0.85), fontSize: 14),
          ),
          const SizedBox(height: 12),

          // ── Gender (edit mode) ────────────────────────────────────────
          if (_isEditing) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['Male', 'Female', 'Prefer not to say'].map((g) {
                final selected = _selectedGender == g.toLowerCase() ||
                    _selectedGender == g;
                return GestureDetector(
                  onTap: () => setState(() => _selectedGender = g),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      g,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFFFF8A00)
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            if (widget.gender.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.gender,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Child Card
// ─────────────────────────────────────────────────────────────────────────────

class _ChildCard extends StatefulWidget {
  final String childId;
  final String parentId;
  final Map<String, dynamic> data;

  const _ChildCard({
    required this.childId,
    required this.parentId,
    required this.data,
  });

  @override
  State<_ChildCard> createState() => _ChildCardState();
}

class _ChildCardState extends State<_ChildCard> {
  bool _isEditing = false;
  late final TextEditingController _nameController;
  String? _selectedSeverity;

  static const _severityOptions = ['Level 1', 'Level 2', 'Level 3'];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.data['name'] as String? ?? '');
    _selectedSeverity =
        widget.data['asdSeverity'] as String? ?? 'Level 1';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveChild() async {
    await FirebaseFirestore.instance
        .collection('parents')
        .doc(widget.parentId)
        .collection('children')
        .doc(widget.childId)
        .update({
      'name': _nameController.text.trim(),
      'asdSeverity': _selectedSeverity,
    });
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final age = widget.data['age'] as int? ?? 0;

    return GestureDetector(
      onTap: _isEditing
          ? null
          : () => context.push(
                Routes.childProfile,
                extra: ChildProfileArgs(
                  parentId: widget.parentId,
                  childId: widget.childId,
                ),
              ),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ───────────────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    const Color(0xFFFF8A00).withOpacity(0.15),
                child: const Icon(Icons.child_care,
                    color: Color(0xFFFF8A00), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _isEditing
                    ? TextField(
                        controller: _nameController,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Color(0xFFFF8A00)),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Color(0xFFFF8A00), width: 2),
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.data['name'] as String? ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87),
                          ),
                          Text(
                            'Age $age',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black45),
                          ),
                        ],
                      ),
              ),
              GestureDetector(
                onTap: () {
                  if (_isEditing) {
                    _saveChild();
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isEditing
                        ? const Color(0xFFFF8A00)
                        : const Color(0xFFFF8A00).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isEditing ? 'Save' : 'Edit',
                    style: TextStyle(
                      color: _isEditing
                          ? Colors.white
                          : const Color(0xFFFF8A00),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Severity row ──────────────────────────────────────────────
          const SizedBox(height: 12),
          if (_isEditing) ...[
            const Text('Diagnosis Level',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54)),
            const SizedBox(height: 8),
            Row(
              children: _severityOptions.map((level) {
                final selected = _selectedSeverity == level;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSeverity = level),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFFF8A00)
                          : const Color(0xFFFF8A00).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      level,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFFFF8A00),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFFF8A00).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.data['asdSeverity'] as String? ?? '',
                    style: const TextStyle(
                        color: Color(0xFFFF8A00),
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account Tile
// ─────────────────────────────────────────────────────────────────────────────

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _AccountTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: color.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}