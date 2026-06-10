import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../patients/data/patient_repository.dart';

/// Route extra — passed via GoRouter `extra:`.
class ChildEditArgs {
  const ChildEditArgs({
    required this.childId,
    required this.parentId,
    required this.data,
    this.linkedTherapistId,
    this.linkedTherapistName,
    this.linkedTherapistEmail,
  });

  final String childId;
  final String parentId;
  final Map<String, dynamic> data;

  /// Pre-loaded linked therapist info (optional). If provided, the screen
  /// skips the async Firestore lookup and shows this immediately.
  final String? linkedTherapistId;
  final String? linkedTherapistName;
  final String? linkedTherapistEmail;
}

class ChildEditScreen extends StatefulWidget {
  const ChildEditScreen({super.key, required this.args});
  final ChildEditArgs args;

  @override
  State<ChildEditScreen> createState() => _ChildEditScreenState();
}

class _ChildEditScreenState extends State<ChildEditScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _therapistEmailCtrl;

  String? _selectedGender;
  String? _selectedSeverity;
  DateTime? _selectedDob;

  bool _saving = false;
  bool _deleting = false;
  bool _changingTherapist = false;

  // Linked therapist (loaded once)
  String? _linkedTherapistId;
  String? _linkedTherapistName;
  String? _linkedTherapistEmail;

  static const _severityOptions = ['Level 1', 'Level 2', 'Level 3'];

  Map<String, dynamic> get _data => widget.args.data;
  String get _childId => widget.args.childId;
  String get _parentId => widget.args.parentId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: _data['name'] as String? ?? '');
    _therapistEmailCtrl = TextEditingController();
    _selectedGender = _data['gender'] as String? ?? '';
    _selectedSeverity = _data['asdSeverity'] as String? ?? 'Level 1';

    final dobTs = _data['dob'];
    if (dobTs is Timestamp) _selectedDob = dobTs.toDate();

    _nameCtrl.addListener(() => setState(() {}));

    // If pre-loaded data is available, show it immediately (no flicker).
    // Always also query Firestore to get the most up-to-date therapist info.
    if (widget.args.linkedTherapistId != null) {
      _linkedTherapistId    = widget.args.linkedTherapistId;
      _linkedTherapistName  = widget.args.linkedTherapistName ?? '';
      _linkedTherapistEmail = widget.args.linkedTherapistEmail ?? '';
    }
    // Always fetch from Firestore — updates state if data comes back
    _loadLinkedTherapist();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _therapistEmailCtrl.dispose();
    super.dispose();
  }

  // ── Dirty check ────────────────────────────────────────────────────────────

  bool get _isDirty {
    final origName = _data['name'] as String? ?? '';
    final origGender = _data['gender'] as String? ?? '';
    final origSeverity = _data['asdSeverity'] as String? ?? 'Level 1';
    final origDob = (_data['dob'] is Timestamp)
        ? (_data['dob'] as Timestamp).toDate()
        : null;

    return _nameCtrl.text.trim() != origName ||
        (_selectedGender ?? '') != origGender ||
        (_selectedSeverity ?? '') != origSeverity ||
        _selectedDob != origDob ||
        _therapistEmailCtrl.text.trim().isNotEmpty;
  }

  // ── Load linked therapist ──────────────────────────────────────────────────

  Future<void> _loadLinkedTherapist() async {
    try {
      // ── Step 1: check the linkedTherapists subcollection (same as ChildProfileRepository) ──
      final linkedSnap = await FirebaseFirestore.instance
          .collection('parents')
          .doc(_parentId)
          .collection('children')
          .doc(_childId)
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

      // ── Step 2: fallback — check linkRequests filtered by parentId (security rule) ──
      final snap = await FirebaseFirestore.instance
          .collection('linkRequests')
          .where('childId', isEqualTo: _childId)
          .where('parentId', isEqualTo: _parentId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return; // keep any pre-loaded data as-is

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
          final tData = tDoc.data()!;
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
          _linkedTherapistId = therapistId ?? therapistEmail;
          _linkedTherapistName = name ?? '';
          _linkedTherapistEmail = email ?? '';
        });
      }
    } catch (_) {}
  }

  // ── Date picker ────────────────────────────────────────────────────────────

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 5),
      firstDate: DateTime(now.year - 18),
      lastDate: now,
      helpText: "Select Child's Date of Birth",
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDob = picked);
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

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_isDirty) return;
    setState(() => _saving = true);
    try {
      final age = _selectedDob != null ? _calcAge(_selectedDob!) : _data['age'];

      await FirebaseFirestore.instance
          .collection('parents')
          .doc(_parentId)
          .collection('children')
          .doc(_childId)
          .update({
        'name': _nameCtrl.text.trim(),
        'gender': _selectedGender ?? '',
        'asdSeverity': _selectedSeverity,
        if (_selectedDob != null) 'dob': Timestamp.fromDate(_selectedDob!),
        if (age != null) 'age': age,
      });

      final therapistEmail = _therapistEmailCtrl.text.trim();
      if (therapistEmail.isNotEmpty) {
        await _sendLinkRequest(therapistEmail);
        return; // snackbar shown inside
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Child profile updated'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendLinkRequest(String therapistEmail) async {
    final snap = await FirebaseFirestore.instance
        .collection('therapists')
        .where('email', isEqualTo: therapistEmail)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Therapist not found with that email')),
        );
      }
      setState(() => _saving = false);
      return;
    }

    final therapistDoc = snap.docs.first;
    final therapistId = therapistDoc.id;
    final parentId = FirebaseAuth.instance.currentUser!.uid;

    // Fetch parent name to denormalize onto the request
    String parentName = '';
    try {
      final parentDoc = await FirebaseFirestore.instance
          .collection('parents').doc(parentId).get();
      parentName = parentDoc.data()?['name'] as String? ?? '';
    } catch (_) {}

    await FirebaseFirestore.instance.collection('linkRequests').add({
      'parentId': parentId,
      'parentName': parentName,
      'therapistId': therapistId,
      'childId': _childId,
      'childName': _nameCtrl.text.trim().isNotEmpty
          ? _nameCtrl.text.trim()
          : (_data['name'] as String? ?? ''),
      'therapistEmail': therapistEmail,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link request sent to therapist'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    }
  }

  // ── Delete child ───────────────────────────────────────────────────────────

  Future<void> _deleteChild() async {
    final childName = _data['name'] as String? ?? 'this child';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Child Profile'),
        content: Text(
          'Are you sure you want to delete $childName\'s profile? '
          'This cannot be undone.\n\n'
          'If linked to a therapist, they will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: AppTextStyles.body.copyWith(color: AppColors.textSubtle)),
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

    setState(() => _deleting = true);
    try {
      await PatientRepository().deleteChild(
        parentId: _parentId,
        childId: _childId,
        linkedTherapistId: _linkedTherapistId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Child profile deleted'),
            backgroundColor: Colors.green,
          ),
        );
        // Pop twice: back from edit screen, then back from child card
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _deleting = false);
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final childName = _data['name'] as String? ?? 'Child';
    final initials = childName.isNotEmpty ? childName[0].toUpperCase() : 'C';

    final dobDisplay = _selectedDob != null
        ? '${_selectedDob!.day.toString().padLeft(2, '0')}/'
            '${_selectedDob!.month.toString().padLeft(2, '0')}/'
            '${_selectedDob!.year}'
        : 'Select date of birth';

    return Scaffold(
      backgroundColor: AppColors.surfaceDefault,
      body: Column(
        children: [
          // ── Nav bar ────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                topPadding + 12,
                AppSpacing.screenMargin,
                12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceDefault,
              border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: AppColors.textMain),
                ),
                Expanded(
                  child: Center(
                    child: Text('Edit Child',
                        style: AppTextStyles.heading1
                            .copyWith(color: AppColors.textMain)),
                  ),
                ),
                GestureDetector(
                  onTap: _isDirty && !_saving ? _save : null,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        )
                      : Text(
                          'Save',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _isDirty
                                ? AppColors.primary
                                : AppColors.textDisabled,
                          ),
                        ),
                ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Avatar block ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(0, 28, 0, 20),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceDefault,
                      border: Border(
                          bottom: BorderSide(color: AppColors.dividerLight)),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 41,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 26,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('Child Profile',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSubtle)),
                      ],
                    ),
                  ),

                  // ── Basic Info ────────────────────────────────────
                  _EditSection(
                    label: 'Basic Info',
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenMargin,
                            10,
                            AppSpacing.screenMargin,
                            10),
                        child: AppTextField(
                          label: 'Full Name',
                          controller: _nameCtrl,
                        ),
                      ),
                    ],
                  ),

                  // ── Date of Birth ─────────────────────────────────
                  _EditSection(
                    label: 'Date of Birth',
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenMargin,
                            12,
                            AppSpacing.screenMargin,
                            12),
                        child: GestureDetector(
                          onTap: _pickDob,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dobDisplay,
                                  style: AppTextStyles.body.copyWith(
                                    color: _selectedDob != null
                                        ? AppColors.textMain
                                        : AppColors.textSubtle,
                                  ),
                                ),
                                const Icon(Icons.calendar_today_outlined,
                                    color: AppColors.primary, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Gender ────────────────────────────────────────
                  _EditSection(
                    label: 'Gender',
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenMargin,
                            12,
                            AppSpacing.screenMargin,
                            12),
                        child: Wrap(
                          spacing: 10,
                          children: [
                            _buildChip('Male', 'male',
                                isSelected: _selectedGender == 'male' ||
                                    _selectedGender == 'Male',
                                onTap: () =>
                                    setState(() => _selectedGender = 'male')),
                            _buildChip('Female', 'female',
                                isSelected: _selectedGender == 'female' ||
                                    _selectedGender == 'Female',
                                onTap: () =>
                                    setState(() => _selectedGender = 'female')),
                            _buildChip('Prefer not to say', 'other',
                                isSelected: _selectedGender == 'other' ||
                                    _selectedGender == 'Prefer not to say',
                                onTap: () =>
                                    setState(() => _selectedGender = 'other')),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ── Diagnosis Level ───────────────────────────────
                  _EditSection(
                    label: 'Diagnosis Level',
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenMargin,
                            12,
                            AppSpacing.screenMargin,
                            12),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: _severityOptions
                              .map((level) => _buildChip(
                                    level,
                                    level,
                                    isSelected: _selectedSeverity == level,
                                    onTap: () => setState(
                                        () => _selectedSeverity = level),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),

                  // ── Therapist ─────────────────────────────────────
                  _EditSection(
                    label: 'Linked Therapist',
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenMargin,
                            12,
                            AppSpacing.screenMargin,
                            12),
                        child: _buildTherapistSection(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Save button ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenMargin),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isDirty && !_saving ? _save : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.pillRadius),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                'Save Changes',
                                style: AppTextStyles.subtitle.copyWith(
                                    color: AppColors.textWhite,
                                    fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Delete button ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenMargin),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _deleting ? null : _deleteChild,
                        icon: _deleting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.error),
                              )
                            : const Icon(Icons.delete_outline,
                                size: 18, color: AppColors.error),
                        label: Text('Delete Child Profile',
                            style: AppTextStyles.subtitle.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppSpacing.pillRadius),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTherapistSection() {
    if (_linkedTherapistId != null && !_changingTherapist) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_user_outlined,
                color: AppColors.secondary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((_linkedTherapistName ?? '').isNotEmpty)
                    Text(
                      _linkedTherapistName!,
                      style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary),
                    ),
                  if ((_linkedTherapistEmail ?? '').isNotEmpty)
                    Text(
                      _linkedTherapistEmail!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSubtle),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _changingTherapist = true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Change',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _therapistEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() {}),
          style: AppTextStyles.body.copyWith(color: AppColors.textMain),
          decoration: InputDecoration(
            hintText: 'therapist@clinic.com',
            hintStyle:
                AppTextStyles.body.copyWith(color: AppColors.textSubtle),
            prefixIcon: const Icon(Icons.link_rounded,
                color: AppColors.primary, size: 20),
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'A link request will be sent to the therapist',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
            ),
            if (_changingTherapist)
              GestureDetector(
                onTap: () => setState(() {
                  _changingTherapist = false;
                  _therapistEmailCtrl.clear();
                }),
                child: Text('Cancel',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(
    String label,
    String value, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: isSelected ? AppColors.textWhite : AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Helper widgets ────────────────────────────────────────────────────────────

class _EditSection extends StatelessWidget {
  const _EditSection({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenMargin, 14, AppSpacing.screenMargin, 6),
          child: Text(
            label.toUpperCase(),
            style: AppTextStyles.tag.copyWith(
              color: AppColors.textDisabled,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
            ),
          ),
        ),
        Container(
          color: AppColors.surfaceDefault,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children),
        ),
        const Divider(
            height: 1,
            indent: AppSpacing.screenMargin,
            endIndent: AppSpacing.screenMargin,
            color: AppColors.dividerLight),
      ],
    );
  }
}
