import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/event.dart';
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_event.dart';
import '../../bloc/events/events_state.dart';
import '../../pages/event_detail/event_detail_screen.dart';
import '../common/jumping_emoji.dart';
import '../events/modern_event_mini_card.dart';
import '../common/find_matches_modal.dart';

class EventAttachment extends StatefulWidget {
  final Post post;

  const EventAttachment({super.key, required this.post});

  @override
  State<EventAttachment> createState() => _EventAttachmentState();
}

class _EventAttachmentState extends State<EventAttachment> {
  bool _showAnimation = false;

  void _handleDoubleTap() {
    if (widget.post.attachedEvent != null) {
      setState(() {
        _showAnimation = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.post.attachedEvent == null) return const SizedBox.shrink();

    // Use a Selector to only rebuild if this specific event changes
    return BlocSelector<EventsBloc, EventsState, Event?>(
      selector: (state) {
        final eventId = widget.post.attachedEvent!.id;

        if (state is EventsLoaded) {
          return state.events.where((e) => e.id == eventId).firstOrNull ??
              state.nearbyEvents.where((e) => e.id == eventId).firstOrNull ??
              state.filteredEvents.where((e) => e.id == eventId).firstOrNull;
        }
        return null;
      },
      builder: (context, updatedEvent) {
        final displayEvent = updatedEvent ?? widget.post.attachedEvent!;

        return GestureDetector(
          onDoubleTap: _handleDoubleTap,
          onTap: () {
            // Navigate to event detail - pass the latest event data
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailScreen(event: displayEvent),
              ),
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                child: ModernEventMiniCard(
                  event: displayEvent,
                  onJoin: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Mantap! Lo udah ikutan event ini. Cek "Cari Temen" yuk!',
                          style: GoogleFonts.plusJakartaSans(),
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: const Color(0xFFBBC863),
                      ),
                    );
                  },
                  onFindMatches: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => DraggableScrollableSheet(
                        initialChildSize: 0.7,
                        minChildSize: 0.5,
                        maxChildSize: 0.9,
                        builder: (context, scrollController) =>
                            FindMatchesModal(
                              eventId: displayEvent.id,
                              eventTitle: displayEvent.title,
                            ),
                      ),
                    );
                  },
                ),
              ),
              if (_showAnimation)
                Positioned.fill(
                  child: Center(
                    child: JumpingEmoji(
                      onAnimationComplete: () {
                        if (mounted) {
                          // Double-tap = LIKE ONLY (TikTok/Instagram style)
                          // Use displayEvent which has the latest data from state
                          context.read<EventsBloc>().add(
                            LikeInterestRequested(displayEvent),
                          );
                          setState(() {
                            _showAnimation = false;
                          });
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
