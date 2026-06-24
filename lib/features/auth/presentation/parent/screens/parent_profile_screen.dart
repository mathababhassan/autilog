import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../child_profile/presentation/screens/child_profile_screen.dart';
import '../../../../patients/data/patient_repository.dart';
import 'child_edit_screen.dart';

class ParentProfileScreen extends StatelessWidget {
  const ParentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.surfaceDefault,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parents')
            .doc(uid)
            .snapshots(),
        builder: (context, snap) {
          final data = snap.hasData && snap.data!.exists
              ? snap.data!.data() as Map<String, dynamic>
              : <String, dynamic>{};

          final name = data['name'] as String? ?? 'Parent';
          final gender = data['gender'] as String? ?? '';
          final email = FirebaseAuth.instance.currentUser?.email ?? '';

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ProfileHeader(
                  uid: uid,
                  name: name,
                  email: email,
                  gender: gender,
                ),
              ),

              // ── Children Section ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Children',
                          style: AppTextStyles.subtitle.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain)),
                      GestureDetector(
                        onTap: () => context.push('${Routes.childRegistration}?from=profile'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text('Add Child',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textWhite,
                                      fontWeight: FontWeight.w700)),
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
                            color: AppColors.surfaceDefault,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.borderInactive),
                          ),
                          child: Center(
                            child: Text('No children added yet.',
                                style: AppTextStyles.body.copyWith(
                                    color: AppColors.textSubtle)),
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
                          padding:
                              const EdgeInsets.fromLTRB(24, 0, 24, 12),
                          child: _ChildCard(
                            childId: childId,
                            parentId: uid,
                            data: child,
                          ),
                        );
                      },
                      childCount: children.length,
                    ),
                  );
                },
              ),

              // ── Account Section ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Account',
                          style: AppTextStyles.subtitle.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain)),
                      const SizedBox(height: 12),
                      _AccountTile(
                        icon: Icons.lock_outline,
                        label: 'Change Password',
                        onTap: () => _showChangePasswordDialog(context),
                      ),
                      const SizedBox(height: 10),
                      _AccountTile(
                        icon: Icons.logout_rounded,
                        label: 'Log Out',
                        color: AppColors.error,
                        onTap: () => _confirmLogout(context),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 32),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Change Password',
            style: AppTextStyles.subtitle
                .copyWith(fontWeight: FontWeight.w700)),
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
                  const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSubtle)),
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
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Update',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out',
            style: AppTextStyles.subtitle
                .copyWith(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to log out?',
            style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSubtle)),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) context.go(Routes.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Log Out',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.uid,
    required this.name,
    required this.email,
    required this.gender,
  });

  final String uid;
  final String name;
  final String email;
  final String gender;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase())
        .take(2)
        .join();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 16, 24, 28),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        children: [
          // ── Top bar ───────────────────────────────────────────────
          Stack(
            alignment: Alignment.center,
            children: [
              // Title — centered across the full header width.
              Center(
                child: Text('My Profile',
                    style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textWhite)),
              ),
              // Back (left) + actions (right), overlaid on the centered title.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => context.push(Routes.parentSettings),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.settings_outlined,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () => context.push(
                          Routes.parentProfileEdit,
                          extra: {
                            'name': name,
                            'gender': gender,
                            'email': email,
                          },
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Edit',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Avatar ────────────────────────────────────────────────
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            child: initials.isNotEmpty
                ? Text(initials,
                    style: AppTextStyles.heading1
                        .copyWith(color: AppColors.textWhite))
                : const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),

          Text(name,
              style: AppTextStyles.subtitle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textWhite)),

          const SizedBox(height: 8),
          Text(email,
              style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: 16),

  

          // ── Gender badge ──────────────────────────────────────────
          if (gender.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(gender,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textWhite)),
            ),
        ],
      ),
    );
  }
}

// ─── Child Card ───────────────────────────────────────────────────────────────

class _ChildCard extends StatefulWidget {
  const _ChildCard({
    required this.childId,
    required this.parentId,
    required this.data,
  });

  final String childId;
  final String parentId;
  final Map<String, dynamic> data;

  @override
  State<_ChildCard> createState() => _ChildCardState();
}

class _ChildCardState extends State<_ChildCard> {
  // Linked therapist (loaded once)
  String? _linkedTherapistId;
  String? _linkedTherapistName;
  String? _linkedTherapistEmail;

  @override
  void initState() {
    super.initState();
    _loadLinkedTherapist();
  }

  Future<void> _loadLinkedTherapist() async {
    try {
      // ── Step 1: linkedTherapists subcollection (written when therapist accepts) ──
      final linkedSnap = await FirebaseFirestore.instance
          .collection('parents')
          .doc(widget.parentId)
          .collection('children')
          .doc(widget.childId)
          .collection('linkedTherapists')
          .orderBy('linkedAt', descending: true)
          .limit(1)
          .get();

      if (linkedSnap.docs.isNotEmpty) {
        final doc = linkedSnap.docs.first;
        final therapistId = doc.id;
        final docData = doc.data();

        // Prefer denormalized fields stored in the subcollection doc itself
        String name  = docData['therapistName'] as String? ?? docData['name'] as String? ?? '';
        String email = docData['therapistEmail'] as String? ?? docData['email'] as String? ?? '';

        // Fallback: try to read the therapists collection (may be denied by rules)
        if (name.isEmpty || email.isEmpty) {
          try {
            final tDoc = await FirebaseFirestore.instance
                .collection('therapists')
                .doc(therapistId)
                .get();
            if (tDoc.exists) {
              if (name.isEmpty)  name  = tDoc.data()?['name']  as String? ?? '';
              if (email.isEmpty) email = tDoc.data()?['email'] as String? ?? '';
            }
          } catch (_) {}
        }

        if (mounted) {
          setState(() {
            _linkedTherapistId    = therapistId;
            _linkedTherapistName  = name;
            _linkedTherapistEmail = email;
          });
        }
        return;
      }

      // ── Step 2: fallback — linkRequests filtered by parentId (security rule) ──
      final snap = await FirebaseFirestore.instance
          .collection('linkRequests')
          .where('childId', isEqualTo: widget.childId)
          .where('parentId', isEqualTo: widget.parentId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return;

      final doc = snap.docs.first.data();
      final therapistEmail = doc['therapistEmail'] as String?;
      final therapistId = doc['therapistId'] as String?;

      if (therapistEmail == null && therapistId == null) return;

      String? name;
      String? email = therapistEmail;

      if (therapistId != null) {
        final tDoc = await FirebaseFirestore.instance
            .collection('therapists')
            .doc(therapistId)
            .get();
        if (tDoc.exists) {
          final tData = tDoc.data() as Map<String, dynamic>;
          name = tData['name'] as String?;
          email ??= tData['email'] as String?;
        }
      } else if (therapistEmail != null) {
        final tSnap = await FirebaseFirestore.instance
            .collection('therapists')
            .where('email', isEqualTo: therapistEmail)
            .limit(1)
            .get();
        if (tSnap.docs.isNotEmpty) {
          name = tSnap.docs.first.data()['name'] as String?;
        }
      }

      if (mounted) {
        setState(() {
          // Only use therapistId (UID) — never fall back to email as an ID
          _linkedTherapistId = therapistId;
          _linkedTherapistName = name ?? '';
          _linkedTherapistEmail = email ?? '';
        });
      }
    } catch (_) {}
  }

  int _calcAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final childName = widget.data['name'] as String? ?? 'this child';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Child Profile'),
        content: Text(
          'Are you sure you want to delete $childName\'s profile? '
          'This cannot be undone.'
          '${_linkedTherapistId != null ? '\n\nThe linked therapist will be notified.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSubtle)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete',
                style: AppTextStyles.body.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await PatientRepository().deleteChild(
        parentId: widget.parentId,
        childId: widget.childId,
        linkedTherapistId: _linkedTherapistId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(
          content: Text('Child profile deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dobTs = widget.data['dob'];
    final dob = dobTs is Timestamp ? dobTs.toDate() : null;
    final age = dob != null
        ? _calcAge(dob)
        : widget.data['age'] as int? ?? 0;

    return GestureDetector(
      onTap: () => context.push(
        Routes.childProfile,
        extra: ChildProfileArgs(
          parentId: widget.parentId,
          childId: widget.childId,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDefault,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderInactive),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.15),
                  child: const Icon(Icons.child_care,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.data['name'] as String? ?? '',
                        style: AppTextStyles.subtitle.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain),
                      ),
                      Text('Age $age',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSubtle)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(
                    Routes.childEdit,
                    extra: ChildEditArgs(
                      childId: widget.childId,
                      parentId: widget.parentId,
                      data: widget.data,
                      linkedTherapistId: _linkedTherapistId,
                      linkedTherapistName: _linkedTherapistName,
                      linkedTherapistEmail: _linkedTherapistEmail,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Edit',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _confirmDelete(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Delete',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── View mode badges ──────────────────────────────────────
            const SizedBox(height: 12),
            Row(
              children: [
                if ((widget.data['asdSeverity'] as String? ?? '').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.data['asdSeverity'] as String? ?? '',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                if ((widget.data['gender'] as String? ?? '').isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.data['gender'] as String? ?? '',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
            // Linked therapist row
            if (_linkedTherapistId != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined,
                        color: AppColors.secondary, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      (_linkedTherapistName?.isNotEmpty == true)
                          ? _linkedTherapistName!
                          : (_linkedTherapistEmail ?? ''),
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Account Tile ─────────────────────────────────────────────────────────────

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textMain,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDefault,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderInactive),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(label,
                style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600, color: color)),
            const Spacer(),
            Icon(Icons.chevron_right,
                color: color.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}
