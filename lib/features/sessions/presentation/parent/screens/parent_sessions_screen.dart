import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../features/sessions/data/jaas_repository.dart';
import '../../../../../features/sessions/data/session_repository.dart';
import '../../../../../shared/models/session_model.dart';
import '../../../../../shared/widgets/app_snackbar.dart';

class ParentSessionsScreen extends StatefulWidget {
  const ParentSessionsScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  final String childId;
  final String childName;

  @override
  State<ParentSessionsScreen> createState() => _ParentSessionsScreenState();
}

class _ParentSessionsScreenState extends State<ParentSessionsScreen> {
  final _repo = SessionRepository();

  List<SessionModel> _upcoming = [];
  List<SessionModel> _past = [];
  Map<String, String> _therapistNames = {};
  bool _loading = true;
  String? _error;
  int _pastLimit = 5;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await _repo.fetchSessionsForChild(widget.childId);
      final now = DateTime.now();

      final upcoming = all
          .where((s) => s.status == 'upcoming' && s.scheduledAt.isAfter(now))
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

      final past = all
          .where((s) =>
              s.status == 'completed' ||
              s.status == 'cancelled' ||
              (s.status == 'upcoming' && s.scheduledAt.isBefore(now)))
          .toList()
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

      // Fetch therapist names
      final therapistIds =
          all.map((s) => s.therapistId).toSet().toList();
      final names = <String, String>{};
      for (final id in therapistIds) {
        if (id.isEmpty) continue;
        try {
          final doc = await FirebaseFirestore.instance
              .collection('therapists')
              .doc(id)
              .get();
          names[id] = doc.data()?['name'] as String? ?? '';
        } catch (_) {}
      }

      setState(() {
        _upcoming = upcoming;
        _past = past;
        _therapistNames = names;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _therapistName(SessionModel s) {
    final name = _therapistNames[s.therapistId] ?? '';
    return name.isNotEmpty ? 'Dr. $name' : 'Dr. —';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDefault,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Could not load sessions.\n$_error',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textPlaceholder),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.primary,
                        child: SingleChildScrollView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                              20, 24, 20, 32),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _sectionTitle('Upcoming Sessions'),
                              const SizedBox(height: 12),
                              _buildUpcoming(context),
                              const SizedBox(height: 28),
                              _sectionTitle('Past Sessions'),
                              const SizedBox(height: 12),
                              _buildPast(),
                            ],
                          ),
                        ),
                      ),
          ),
          _buildBottomNav(context),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back,
                color: AppColors.textWhite, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sessions',
                    style: AppTextStyles.heading1
                        .copyWith(color: AppColors.textWhite)),
                Text(widget.childName,
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textWhite
                            .withValues(alpha: 0.85))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push(Routes.parentProfile),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.22),
              ),
              child: const Icon(Icons.person_outline,
                  color: AppColors.textWhite, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section title ─────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Text(title,
        style: AppTextStyles.subtitle.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textMain));
  }

  // ── Upcoming ──────────────────────────────────────────────────────────────

  Widget _buildUpcoming(BuildContext context) {
    if (_upcoming.isEmpty) {
      return _EmptyUpcomingCard();
    }

    return Column(
      children: [
        ..._upcoming.map((s) => _UpcomingSessionCard(
              session: s,
              therapistName: _therapistName(s),
              onCancel: () => _showCancelSheet(context, s),
            )),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.secondary20,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 15, color: AppColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Join button becomes active 10 minutes before session time.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.secondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Past ──────────────────────────────────────────────────────────────────

  Widget _buildPast() {
    if (_past.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text('No past sessions yet.',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textPlaceholder),
            textAlign: TextAlign.center),
      );
    }

    final visible = _past.take(_pastLimit).toList();

    return Column(
      children: [
        ...visible.map((s) => _PastSessionCard(
              session: s,
              therapistName: _therapistName(s),
            )),
        if (_past.length > _pastLimit) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _pastLimit += 5),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border:
                    Border.all(color: AppColors.dividerLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Load More',
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain)),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down,
                      color: AppColors.textMain, size: 18),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Cancel sheet ──────────────────────────────────────────────────────────

  void _showCancelSheet(
      BuildContext context, SessionModel session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CancelSessionSheet(
        session: session,
        onConfirm: (reason) async {
          await _repo.cancelSession(session.id, reason: reason);
          if (mounted) {
            Navigator.of(context).pop();
            _load();
          }
        },
      ),
    );
  }

  // ── Bottom nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 2, // 2 = Sessions tab is active
      onTap: (index) {
        if (index == 0) {
          context.go(Routes.parentHome);
        } else if (index == 1) {
          // Navigate to Log History screen
          context.push(Routes.logHistory, extra: widget.childId);
        } else if (index == 2) {
          // Already on Sessions screen, optionally refresh
          _load();
        }
      },
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.black38,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          activeIcon: Icon(Icons.assignment),
          label: 'Log',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          activeIcon: Icon(Icons.calendar_month),
          label: 'Sessions',
        ),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _formatDateShort(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final period = d.hour < 12 ? 'AM' : 'PM';
  return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]} · $h:$m $period';
}

int _duration(SessionModel s) =>
    s.endTime.difference(s.scheduledAt).inMinutes;

bool _isJoinActive(SessionModel s) {
  final now = DateTime.now();
  return now.isAfter(
          s.scheduledAt.subtract(const Duration(minutes: 10))) &&
      now.isBefore(s.endTime);
}

String _reminderTime(SessionModel s) {
  final r = s.scheduledAt.subtract(const Duration(minutes: 30));
  final h = r.hour % 12 == 0 ? 12 : r.hour % 12;
  final m = r.minute.toString().padLeft(2, '0');
  final period = r.hour < 12 ? 'AM' : 'PM';
  return '$h:$m $period';
}

// ─── Upcoming session card ────────────────────────────────────────────────────

class _UpcomingSessionCard extends StatefulWidget {
  const _UpcomingSessionCard({
    required this.session,
    required this.therapistName,
    required this.onCancel,
  });

  final SessionModel session;
  final String therapistName;
  final VoidCallback onCancel;

  @override
  State<_UpcomingSessionCard> createState() => _UpcomingSessionCardState();
}

class _UpcomingSessionCardState extends State<_UpcomingSessionCard> {
  bool _joiningCall = false;

  Future<void> _joinCall() async {
    setState(() => _joiningCall = true);
    try {
      final result =
          await JaasRepository().fetchJoinToken(widget.session.id);
      final url = result.joinUrl;
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open the meeting link.');
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(
            context, 'Could not join the session. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _joiningCall = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final joinActive = _isJoinActive(session);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDefault,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerLight),
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
          // Therapist name
          Text(widget.therapistName,
              style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain)),
          const SizedBox(height: 4),
          // Date & time
          Text(_formatDateShort(session.scheduledAt),
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textPlaceholder)),
          const SizedBox(height: 2),
          // Mode & duration
          Text(
            '${session.mode} · ${_duration(session)} mins',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textPlaceholder),
          ),
          const SizedBox(height: 10),
          // Reminder badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.secondary20,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_outlined,
                    size: 13, color: AppColors.secondary),
                const SizedBox(width: 5),
                Text(
                  'Reminder set for ${_reminderTime(session)}',
                  style: AppTextStyles.tag.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: (joinActive && !_joiningCall) ? _joinCall : null,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: joinActive
                          ? AppColors.primary
                          : AppColors.inputFill,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _joiningCall
                          ? [
                              const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              ),
                            ]
                          : [
                              Icon(Icons.video_call_outlined,
                                  size: 16,
                                  color: joinActive
                                      ? AppColors.textWhite
                                      : AppColors.textSubtle),
                              const SizedBox(width: 6),
                              Text('Join',
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: joinActive
                                        ? AppColors.textWhite
                                        : AppColors.textSubtle,
                                  )),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward,
                                  size: 14,
                                  color: joinActive
                                      ? AppColors.textWhite
                                      : AppColors.textSubtle),
                            ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: widget.onCancel,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDefault,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: AppColors.accentRed),
                    ),
                    child: Text('Cancel',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentRed,
                        )),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Empty upcoming card ──────────────────────────────────────────────────────

class _EmptyUpcomingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 32, color: AppColors.textSubtle),
          const SizedBox(height: 10),
          Text('No upcoming sessions scheduled.',
              style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            'Your therapist will notify you when a new session is booked.',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textPlaceholder),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Past session card ────────────────────────────────────────────────────────

class _PastSessionCard extends StatelessWidget {
  const _PastSessionCard({
    required this.session,
    required this.therapistName,
  });

  final SessionModel session;
  final String therapistName;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDefault,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_formatDateShort(session.scheduledAt)} · $therapistName',
                  style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain),
                ),
              ),
              if (session.status == 'cancelled')
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed20,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Cancelled',
                      style: AppTextStyles.tag.copyWith(
                          color: AppColors.accentRed,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${session.mode} · ${_duration(session)} mins',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textPlaceholder),
          ),
          if (session.status != 'cancelled') ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.dividerLight, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.notes_outlined,
                    size: 14, color: AppColors.secondary),
                const SizedBox(width: 6),
                Text('Session Notes:',
                    style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              session.notes != null && session.notes!.isNotEmpty
                  ? session.notes!
                  : 'No session notes added yet.',
              style: AppTextStyles.caption.copyWith(
                color: session.notes != null &&
                        session.notes!.isNotEmpty
                    ? AppColors.textMain
                    : AppColors.textPlaceholder,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Cancel session sheet (P-32) ─────────────────────────────────────────────

class _CancelSessionSheet extends StatefulWidget {
  const _CancelSessionSheet({
    required this.session,
    required this.onConfirm,
  });

  final SessionModel session;
  final Future<void> Function(String? reason) onConfirm;

  @override
  State<_CancelSessionSheet> createState() =>
      _CancelSessionSheetState();
}

class _CancelSessionSheetState
    extends State<_CancelSessionSheet> {
  final _reasonController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding:
          EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Cancel Session',
              style: AppTextStyles.heading1
                  .copyWith(color: AppColors.textMain)),
          const SizedBox(height: 8),
          Text(
            'Are you sure you want to cancel this session?\n${_formatDateShort(widget.session.scheduledAt)}',
            style: AppTextStyles.body
                .copyWith(color: AppColors.textPlaceholder),
          ),
          const SizedBox(height: 20),
          Text('Reason (optional)',
              style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain)),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: 'Let your therapist know why...',
              hintStyle: AppTextStyles.body
                  .copyWith(color: AppColors.textSubtle),
              filled: true,
              fillColor: AppColors.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Keep Session',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _loading
                      ? null
                      : () async {
                          setState(() => _loading = true);
                          await widget.onConfirm(
                              _reasonController.text.trim());
                        },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.accentRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _loading
                        ? const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2),
                            ),
                          )
                        : Text('Yes, Cancel',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textWhite)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Nav item ─────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        active ? AppColors.primary : AppColors.textMain;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(active ? activeIcon : icon,
              color: color, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.tag.copyWith(
                fontWeight: active
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: color,
              )),
        ],
      ),
    );
  }
}