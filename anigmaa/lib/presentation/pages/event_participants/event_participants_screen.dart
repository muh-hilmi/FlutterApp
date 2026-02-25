import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/event_attendee.dart';
import '../../../injection_container.dart' as di;
import '../../bloc/event_participants/event_participants_bloc.dart';
import '../../bloc/event_participants/event_participants_event.dart';
import '../../bloc/event_participants/event_participants_state.dart';
import '../../widgets/checkin_dialog.dart';
import '../qr_checkin/qr_checkin_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/common/snackbar_helper.dart';

/// Screen for event hosts to view and manage event attendees
/// Features: attendee list, search, filter, manual check-in, QR scan
///
/// NOTE: This screen is used as a tab in EventManagementDashboard,
/// so it doesn't have its own Scaffold/AppBar. The parent provides them.
class EventParticipantsScreen extends StatefulWidget {
  final String eventId;
  final int? maxAttendees;

  const EventParticipantsScreen({
    super.key,
    required this.eventId,
    this.maxAttendees,
  });

  @override
  State<EventParticipantsScreen> createState() => _EventParticipantsScreenState();
}

class _EventParticipantsScreenState extends State<EventParticipantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late final EventParticipantsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = di.sl<EventParticipantsBloc>();
    // Load attendees when screen initializes
    _bloc.add(LoadEventAttendees(eventId: widget.eventId));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<EventParticipantsBloc, EventParticipantsState>(
        listener: (context, state) {
          if (state is EventParticipantsError) {
            _showErrorSnackBar(context, state.message);
          } else if (state is EventAttendeeCheckedIn) {
            _showSuccessSnackBar(context, '${state.attendee.name} berhasil check-in!');
          }
        },
        child: Stack(
          children: [
            Column(
              children: [
                // Header with check-in count and refresh
                _buildHeader(),
                // Search and filter section
                _buildSearchAndFilter(),
                // Attendees list
                Expanded(
                  child: _buildAttendeesList(),
                ),
              ],
            ),
            // Floating scan QR button
            Positioned(
              right: 16,
              bottom: 16,
              child: _buildScanQRButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      key: const Key('event_participants_header'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFEEEEEE),
            width: 1,
          ),
        ),
      ),
      child: BlocBuilder<EventParticipantsBloc, EventParticipantsState>(
        builder: (context, state) {
          final checkedInCount = state is EventParticipantsLoaded
              ? state.checkedInCount
              : 0;
          final totalCount = widget.maxAttendees ?? (state is EventParticipantsLoaded
              ? state.attendees.length
              : 0);

          return Row(
            children: [
              const Text(
                'Peserta',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFBBC863),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$checkedInCount/$totalCount',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              // Refresh button
              IconButton(
                key: const Key('event_participants_refresh_button'),
                icon: state is EventParticipantsLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFBBC863),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.refresh,
                        color: Color(0xFFBBC863),
                      ),
                onPressed: state is EventParticipantsLoading
                    ? null
                    : () {
                        context.read<EventParticipantsBloc>().add(RefreshEventAttendees(
                              eventId: widget.eventId,
                            ));
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search field
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              key: const Key('event_participants_search_field'),
              controller: _searchController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: (query) {
                context.read<EventParticipantsBloc>().add(SearchAttendees(query));
              },
              decoration: InputDecoration(
                hintText: 'Cari nama peserta...',
                hintStyle: TextStyle(
                  color: AppColors.border,
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.border,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: Color(0xFFBBC863),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          context.read<EventParticipantsBloc>().add(const SearchAttendees(''));
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          BlocBuilder<EventParticipantsBloc, EventParticipantsState>(
            builder: (context, state) {
              final currentFilter = state is EventParticipantsLoaded
                  ? state.currentFilter
                  : null;

              return Row(
                children: [
                  _buildFilterChip(
                    label: 'Semua',
                    isSelected: currentFilter == null,
                    onTap: () {
                      context.read<EventParticipantsBloc>().add(const FilterAttendees(null));
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Belum Check-In',
                    isSelected: currentFilter == 'pending',
                    onTap: () {
                      context.read<EventParticipantsBloc>().add(const FilterAttendees('pending'));
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Sudah Check-In',
                    isSelected: currentFilter == 'confirmed',
                    onTap: () {
                      context.read<EventParticipantsBloc>().add(const FilterAttendees('confirmed'));
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBBC863) : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textEmphasis,
          ),
        ),
      ),
    );
  }

  Widget _buildAttendeesList() {
    return BlocBuilder<EventParticipantsBloc, EventParticipantsState>(
      builder: (context, state) {
        if (state is EventParticipantsLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFFBBC863),
              ),
            ),
          );
        }

        if (state is EventParticipantsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.border,
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<EventParticipantsBloc>().add(LoadEventAttendees(
                          eventId: widget.eventId,
                        ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBBC863),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        if (state is EventParticipantsLoaded) {
          if (state.attendees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppColors.border,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.currentSearch != null
                        ? 'Tidak ada peserta dengan nama "${state.currentSearch}"'
                        : 'Belum ada peserta',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<EventParticipantsBloc>().add(RefreshEventAttendees(
                    eventId: widget.eventId,
                  ));
            },
            color: const Color(0xFFBBC863),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.attendees.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final attendee = state.attendees[index];
                return _buildAttendeeCard(attendee);
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAttendeeCard(EventAttendee attendee) {
    return Container(
      key: Key('attendee_card_${attendee.id}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFBBC863).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: attendee.avatar != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.network(
                      attendee.avatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          color: Color(0xFFBBC863),
                          size: 32,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.person,
                    color: Color(0xFFBBC863),
                    size: 32,
                  ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendee.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.confirmation_number,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        attendee.ticketType,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      attendee.checkedIn ? Icons.check_circle : Icons.schedule,
                      size: 14,
                      color: attendee.checkedIn ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      attendee.checkedIn
                          ? attendee.formattedCheckInTime ?? 'Sudah Check-In'
                          : 'Belum Check-In',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: attendee.checkedIn ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Check-in button
          if (!attendee.checkedIn)
            ElevatedButton(
              key: Key('checkin_button_${attendee.id}'),
              onPressed: () async {
                final confirmed = await CheckinDialog.show(context, attendee);
                if (confirmed == true) {
                  if (!mounted) return;
                  context.read<EventParticipantsBloc>().add(CheckInAttendee(
                        eventId: widget.eventId,
                        userId: attendee.id,
                        ticketId: attendee.ticketId,
                      ));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBBC863),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Check-In',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    attendee.formattedCheckInTime ?? 'Done',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanQRButton() {
    return FloatingActionButton.extended(
      key: const Key('scan_qr_button'),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QRCheckinScreen(eventId: widget.eventId),
          ),
        );
      },
      backgroundColor: const Color(0xFFBBC863),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text(
        'Scan QR',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevation: 4,
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    SnackBarHelper.showError(context, message, actionLabel: 'Tutup');
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    SnackBarHelper.showSuccess(context, message, actionLabel: 'Tutup');
  }
}
