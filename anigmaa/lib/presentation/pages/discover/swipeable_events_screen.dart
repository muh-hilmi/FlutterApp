import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/event.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_event.dart';
import '../../bloc/events/events_state.dart';
import '../../bloc/tickets/tickets_bloc.dart';
import '../../bloc/tickets/tickets_event.dart';
import '../event_detail/event_detail_screen.dart';
import '../payment/payment_screen.dart';
import '../../widgets/tickets/join_confirmation_ticket.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/empty_state_widget.dart';

/// Single-file implementation of Swipeable Events with Decoupled Feedback
class SwipeableEventsScreen extends StatefulWidget {
  const SwipeableEventsScreen({super.key});

  @override
  State<SwipeableEventsScreen> createState() => _SwipeableEventsScreenState();
}

class _SwipeableEventsScreenState extends State<SwipeableEventsScreen>
    with TickerProviderStateMixin {
  // Local state to manage the stack of events
  List<Event> _events = [];
  int _currentIndex = 0;
  bool _isFinished = false;

  // Join Confirmation State
  Event? _pendingJoinEvent;
  late AnimationController _sheetController;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<EventsBloc>();
    if (bloc.state is! EventsLoaded) {
      bloc.add(LoadEvents());
    }
    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  // Helper function to convert technical errors to user-friendly messages
  String _getUserFriendlyError(String technicalError) {
    final lowerError = technicalError.toLowerCase();

    if (lowerError.contains('network') ||
        lowerError.contains('connection') ||
        lowerError.contains('socket')) {
      return 'Koneksi internet bermasalah.\nCek koneksi kamu ya! 📡';
    } else if (lowerError.contains('timeout')) {
      return 'Server lagi lelet nih.\nCoba lagi yuk! ⏱️';
    } else if (lowerError.contains('404') || lowerError.contains('not found')) {
      return 'Data ga ketemu.\nMungkin udah dihapus 🤔';
    } else if (lowerError.contains('500') ||
        lowerError.contains('server') ||
        lowerError.contains('unexpected')) {
      return 'Server lagi bermasalah.\nTunggu sebentar ya! 🔧';
    } else if (lowerError.contains('unauthorized') ||
        lowerError.contains('401')) {
      return 'Sesi kamu habis.\nYuk login lagi! 🔐';
    } else {
      return 'Ada kendala nih.\nCoba lagi ya! 😅';
    }
  }

  void _onSwipeComplete(SwipeDirection direction, Event event) {
    if (direction == SwipeDirection.up) {
      // Swipe up = LIKE ONLY (TikTok/Instagram style)
      context.read<EventsBloc>().add(LikeInterestRequested(event));
    } else if (direction == SwipeDirection.down) {
      // Join - Show Confirmation Sheet instead of immediate join
      _showJoinConfirmation(event);
    }
    // Left/Right just skip

    setState(() {
      _currentIndex++;
    });

    if (_currentIndex >= _events.length) {
      setState(() {
        _isFinished = true;
      });
    }
  }

  void _showJoinConfirmation(Event event) {
    setState(() {
      _pendingJoinEvent = event;
    });
    _sheetController.forward();
  }

  Future<void> _dismissJoinConfirmation() async {
    await _sheetController.reverse();
    setState(() {
      _pendingJoinEvent = null;
    });
  }

  void _confirmJoin() {
    if (_pendingJoinEvent != null) {
      _handleJoin(_pendingJoinEvent!);
      _dismissJoinConfirmation();
    }
  }

  void _handleJoin(Event event) {
    if (event.isFree) {
      context.read<TicketsBloc>().add(
        PurchaseTicketRequested(
          userId: 'current_user',
          eventId: event.id,
          amount: 0.0,
          customerName: 'User',
          customerEmail: 'user@example.com',
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Joined Event! 🎟️"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green[700],
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PaymentScreen(event: event)),
      );
    }
  }

  Widget _buildConfirmationSheet() {
    return JoinConfirmationTicket(
      event: _pendingJoinEvent!,
      onConfirm: _confirmJoin,
      onDismiss: _dismissJoinConfirmation,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<EventsBloc, EventsState>(
        builder: (context, state) {
          if (state is EventsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFBBC863)),
            );
          }
          if (state is EventsError) {
            return ErrorStateWidget(
              message: _getUserFriendlyError(state.message),
              onRetry: () => context.read<EventsBloc>().add(LoadEvents()),
            );
          }
          if (state is EventsLoaded) {
            // Sync local events with bloc state
            // Only update if the filtered events list has changed
            if (_events.isEmpty ||
                _events.length != state.filteredEvents.length ||
                _events.first.id != state.filteredEvents.first.id) {
              _events = List.from(state.filteredEvents);
              // Reset indices when events are refreshed
              _currentIndex = 0;
              _isFinished = false;
            }

            if (_events.isEmpty || _isFinished) {
              return _buildEmptyState();
            }

            final safeIndex = _currentIndex;
            final nextIndex = safeIndex + 1;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Background
                const Positioned.fill(child: ColoredBox(color: Colors.white)),

                // 2. The Join Confirmation Sheet (Non-blocking Overlay)

                // Next Card (Behind)
                if (nextIndex < _events.length)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Transform.scale(
                        scale: 0.95,
                        child: _EventCardFace(event: _events[nextIndex]),
                      ),
                    ),
                  ),

                // Top Card (Draggable)
                if (safeIndex < _events.length)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _SwipeableCard(
                        key: ValueKey(_events[safeIndex].id),
                        event: _events[safeIndex],
                        onSwipe: (dir) =>
                            _onSwipeComplete(dir, _events[safeIndex]),
                      ),
                    ),
                  ),

                // 2. The Join Confirmation Sheet (Non-blocking Overlay) - Topmost Z-Index
                if (_pendingJoinEvent != null)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _sheetController,
                      builder: (context, child) {
                        final value = CurvedAnimation(
                          parent: _sheetController,
                          curve: Curves.easeOut,
                        ).value;

                        return Stack(
                          children: [
                            // Background Barrier
                            GestureDetector(
                              onTap: _dismissJoinConfirmation,
                              child: Container(
                                color: Colors.black.withValues(
                                  alpha: 0.5 * value,
                                ),
                              ),
                            ),
                            // Confirmation Sheet
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 0,
                              child: SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Transform.translate(
                                    offset: Offset(
                                      0,
                                      200 *
                                          (1.0 -
                                              CurvedAnimation(
                                                parent: _sheetController,
                                                curve: Curves.easeOutBack,
                                              ).value),
                                    ),
                                    child: _buildConfirmationSheet(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.done_all_rounded,
      title: "Sudah Habis!",
      subtitle: "Tidak ada event lagi buat kamu saat ini.",
      action: ElevatedButton(
        onPressed: () {
          setState(() {
            _currentIndex = 0;
            _isFinished = false;
          });
          context.read<EventsBloc>().add(LoadEvents());
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFBBC863),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: const Text(
          "Coba Lagi",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

enum SwipeDirection { left, right, up, down }

class _SwipeableCard extends StatefulWidget {
  final Event event;
  final Function(SwipeDirection) onSwipe;

  const _SwipeableCard({
    required Key key,
    required this.event,
    required this.onSwipe,
  }) : super(key: key);

  @override
  State<_SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<_SwipeableCard>
    with TickerProviderStateMixin {
  late AnimationController _cardController; // For exit animations
  late AnimationController _pinController; // For interest pin animation
  late AnimationController _resetController; // For snapping back
  late AnimationController _snapController; // For weighted snap & squash

  // Drag state
  Offset _dragOffset = Offset.zero;
  double _angle = 0.0;
  bool _isDragging = false;
  Size _screenSize = Size.zero;

  // Animation State
  bool _isInterestAnimating = false;
  bool _isCardLeaving = false;
  bool _isSnapAnimating = false; // For Join sequence

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100), // Short snap
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.of(context).size;
  }

  @override
  void dispose() {
    _cardController.dispose();
    _pinController.dispose();
    _resetController.dispose();
    _snapController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isInterestAnimating || _isSnapAnimating) return;
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isInterestAnimating || _isSnapAnimating) return;
    setState(() {
      // Apply progressive resistance for Downward drag
      // "Movement slows as drag distance increases"
      if (_dragOffset.dy > 0 && details.delta.dy > 0) {
        // Resistance formula: delta * (1 / (1 + current_dist / constant))
        double resistance = 1.0 / (1.0 + (_dragOffset.dy / 300));
        _dragOffset += Offset(details.delta.dx, details.delta.dy * resistance);
      } else {
        _dragOffset += details.delta;
      }

      // Calculate rotation
      // "No rotation on Swipe Down"
      if (_dragOffset.dy > 20 && _dragOffset.dy.abs() > _dragOffset.dx.abs()) {
        _angle = 0.0; // STRICTLY NO ROTATION
      } else {
        _angle = (_dragOffset.dx / _screenSize.width) * 0.4;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isInterestAnimating || _isSnapAnimating) return;
    setState(() {
      _isDragging = false;
    });

    final xThreshold = _screenSize.width * 0.3;
    final yThreshold = _screenSize.height * 0.15;

    SwipeDirection? swipeDir;

    // Vertical dominance
    if (_dragOffset.dy.abs() > _dragOffset.dx.abs()) {
      if (_dragOffset.dy < -yThreshold) {
        swipeDir = SwipeDirection.up; // INTEREST
      } else if (_dragOffset.dy > yThreshold) {
        swipeDir = SwipeDirection.down; // JOIN
      }
    } else {
      if (_dragOffset.dx.abs() > xThreshold) {
        swipeDir = _dragOffset.dx > 0
            ? SwipeDirection.right
            : SwipeDirection.left;
      }
    }

    if (swipeDir != null) {
      if (swipeDir == SwipeDirection.up) {
        _animateInterestSequence();
      } else if (swipeDir == SwipeDirection.down) {
        _animateJoinSequence();
      } else {
        _animateOut(swipeDir);
      }
    } else {
      _resetPosition();
    }
  }

  void _resetPosition() {
    final startOffset = _dragOffset;
    final startAngle = _angle;

    _resetController.reset();
    final animation = CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeOutBack,
    );

    animation.addListener(() {
      setState(() {
        final val = 1.0 - animation.value;
        _dragOffset = Offset(startOffset.dx * val, startOffset.dy * val);
        _angle = startAngle * val;
      });
    });

    _resetController.forward();
  }

  // Standard animation for Skip
  void _animateOut(SwipeDirection direction) {
    Offset endOffset = Offset.zero;
    if (direction == SwipeDirection.left) {
      endOffset = Offset(-_screenSize.width * 1.5, _dragOffset.dy);
    } else if (direction == SwipeDirection.right) {
      endOffset = Offset(_screenSize.width * 1.5, _dragOffset.dy);
    }
    // Up and Down have special handlers now

    final startOffset = _dragOffset;
    _cardController.duration = const Duration(milliseconds: 300);
    _cardController.reset();
    final animation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOut,
    );

    animation.addListener(() {
      setState(() {
        _dragOffset = Offset.lerp(startOffset, endOffset, animation.value)!;
      });
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onSwipe(direction);
      }
    });

    _cardController.forward();
  }

  // Weighted Join Animation (Swipe Down) + Squash
  Future<void> _animateJoinSequence() async {
    setState(() {
      _isSnapAnimating = true; // Use this to lock interactions
    });

    // 1. Short, weighted snap downward (minimal overshoot ~6px) + SQUASH
    final startOffset = _dragOffset;
    final snapOffset = Offset(
      startOffset.dx,
      startOffset.dy + 6.0, // Minimal overshoot
    );

    _snapController.duration = const Duration(
      milliseconds: 80,
    ); // Short duration
    _snapController.reset();
    final snapAnim = CurvedAnimation(
      parent: _snapController,
      curve: Curves.easeOutQuad,
    );

    // Animate snap (position) is handled via dragOffset updates
    // Squash (scale) is handled via _snapController value in build()

    snapAnim.addListener(() {
      setState(() {
        _dragOffset = Offset.lerp(startOffset, snapOffset, snapAnim.value)!;
      });
    });

    await _snapController.forward();

    // 2. Hold snap position briefly (~100ms) - Squash is MAX applied here
    await Future.delayed(const Duration(milliseconds: 100));

    // 3. Commit & exit (straight down, confident ease-out) + UNSQUASH
    if (!mounted) return;

    final exitStart = _dragOffset;
    final exitEnd = Offset(exitStart.dx, _screenSize.height * 1.5);

    _cardController.duration = const Duration(milliseconds: 350); // 300-350ms
    _cardController.reset();
    final exitAnim = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOut,
    );

    exitAnim.addListener(() {
      setState(() {
        _dragOffset = Offset.lerp(exitStart, exitEnd, exitAnim.value)!;
      });
    });

    // Note: build() uses _cardController to lerp squash back to normal

    exitAnim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) widget.onSwipe(SwipeDirection.down);
      }
    });

    _cardController.forward();
  }

  // Sequential Interest Animation (Swipe Up)
  Future<void> _animateInterestSequence() async {
    setState(() {
      _isInterestAnimating = true;
    });

    // 1. Reset to center
    if (_dragOffset != Offset.zero) {
      final startOffset = _dragOffset;
      final startAngle = _angle;
      _resetController.reset();
      final resetAnim = CurvedAnimation(
        parent: _resetController,
        curve: Curves.easeOut,
      );

      resetAnim.addListener(() {
        setState(() {
          final val = 1.0 - resetAnim.value;
          _dragOffset = Offset(startOffset.dx * val, startOffset.dy * val);
          _angle = startAngle * val;
        });
      });

      await _resetController.forward();
      setState(() {
        _dragOffset = Offset.zero;
        _angle = 0.0;
      });
    }

    // 2. Play Pin Animation
    _pinController.reset();
    await _pinController.forward();

    // 3. Play Card Exit (Fade + Slide Up)
    setState(() {
      _isCardLeaving = true;
    });

    _cardController.duration = const Duration(milliseconds: 500);
    _cardController.reset();
    await _cardController.forward();

    // 4. Update State
    if (mounted) {
      widget.onSwipe(SwipeDirection.up);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTap: () {
        if (!_isInterestAnimating && !_isSnapAnimating) {
          // Debug log to compare event data
          print(
            '[SwipeableEventsScreen] Navigating to detail with event: ${widget.event.id}',
          );
          print(
            '[SwipeableEventsScreen] interestedCount: ${widget.event.interestedCount}',
          );
          print(
            '[SwipeableEventsScreen] interestedUserIds: ${widget.event.interestedUserIds}',
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(event: widget.event),
            ),
          );
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. The Card (Rotatable)
          AnimatedBuilder(
            animation: Listenable.merge([_cardController, _snapController]),
            builder: (context, child) {
              // Squash Logic for Join (Snap)
              double scaleX = 1.0;
              double scaleY = 1.0;

              if (_isSnapAnimating) {
                // Phase 1: Squashing (Snap)
                if (!_cardController.isAnimating) {
                  double squashVal = _snapController.value;
                  // Stronger Squash: X=1.05, Y=0.9
                  scaleX = 1.0 + (0.05 * squashVal);
                  scaleY = 1.0 - (0.1 * squashVal);
                }
                // Phase 2: Unsquashing (Exit)
                else {
                  double exitVal = _cardController.value;
                  scaleX = 1.05 - (0.05 * exitVal);
                  scaleY = 0.9 + (0.1 * exitVal);
                }
              }

              if (_isCardLeaving && _isInterestAnimating) {
                final val = CurvedAnimation(
                  parent: _cardController,
                  curve: Curves.easeIn,
                ).value;
                double dy = _dragOffset.dy - (val * _screenSize.height);
                double opacity = (1.0 - val).clamp(0.0, 1.0);

                return Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(_dragOffset.dx, dy),
                    child: Transform.rotate(angle: _angle, child: child),
                  ),
                );
              }
              return Transform.translate(
                offset: _dragOffset,
                child: Transform.rotate(
                  angle: _angle,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(scaleX, scaleY, 1.0),
                    child: child,
                  ),
                ),
              );
            },
            child: _EventCardFace(event: widget.event),
          ),

          // 2. The Overlays
          if (_isDragging && !_isInterestAnimating && !_isSnapAnimating)
            _buildDragOverlays(),

          // 3. The Specific Interest Pin Animation
          if (_isInterestAnimating)
            AnimatedBuilder(
              animation: _pinController,
              builder: (context, child) {
                final t = CurvedAnimation(
                  parent: _pinController,
                  curve: Curves.easeInOut,
                ).value;
                return Align(
                  alignment: Alignment.lerp(
                    Alignment.center,
                    Alignment.topRight,
                    t,
                  )!,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Transform.scale(
                      scale:
                          1.0 - (_isCardLeaving ? _cardController.value : 0.0),
                      child: const Text("📌", style: TextStyle(fontSize: 64)),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDragOverlays() {
    Widget? content;
    Color? bgColor;
    Alignment alignment = Alignment.center;

    // Down = JOIN
    if (_dragOffset.dy > 50 && _dragOffset.dy.abs() > _dragOffset.dx.abs()) {
      content = const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_activity_rounded, size: 48, color: Colors.green),
          Text(
            "JOIN",
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
        ],
      );
      alignment = Alignment.center;
      bgColor = Colors.white.withValues(alpha: 0.8);
    }
    // Up = Interest Prompt
    else if (_dragOffset.dy < -50 &&
        _dragOffset.dy.abs() > _dragOffset.dx.abs()) {
      content = const Text("📌", style: TextStyle(fontSize: 64));
      alignment = Alignment.center;
    }
    // Horizontal = SKIP
    else if (_dragOffset.dx.abs() > 50) {
      content = const Icon(Icons.close, size: 64, color: Colors.red);
      bgColor = Colors.white.withValues(alpha: 0.8);
    }

    if (content == null) return const SizedBox.shrink();

    double opacity = (_dragOffset.distance / 200).clamp(0.0, 1.0);

    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _EventCardFace extends StatelessWidget {
  final Event event;
  const _EventCardFace({required this.event});

  @override
  Widget build(BuildContext context) {
    // Debug logging for swipeable card time display
    final localTime = event.startTime.toLocal();
    print('[SwipeableCard] ===== CARD TIME DISPLAY =====');
    print('[SwipeableCard] Event: ${event.title}');
    print(
      '[SwipeableCard] startTime raw: ${event.startTime} (isUtc: ${event.startTime.isUtc})',
    );
    print('[SwipeableCard] startTime.toLocal(): $localTime');
    print(
      '[SwipeableCard] Display time: ${DateFormat('MMM d, HH:mm').format(localTime)}',
    );
    print(
      '[SwipeableCard] Expected: If 12:00 UTC, should show 19:00 in WIB (UTC+7)',
    );
    print('[SwipeableCard] ===== END CARD DIAGNOSTICS =====');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full Image
            if (event.fullImageUrls.isNotEmpty)
              CachedNetworkImage(
                imageUrl: event.fullImageUrls.first,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: const Color(0xFFBBC863),
                  child: const Center(
                    child: Icon(Icons.event, size: 80, color: Colors.black),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFFBBC863),
                  child: const Center(
                    child: Icon(Icons.event, size: 80, color: Colors.black),
                  ),
                ),
              )
            else
              Container(
                color: const Color(0xFFBBC863),
                child: const Center(
                  child: Icon(Icons.event, size: 80, color: Colors.black),
                ),
              ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.4, 0.7, 1.0],
                ),
              ),
            ),

            // Content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Category & Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBBC863),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            event.category.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        // Stats Badges
                        Row(
                          children: [
                            // Joined Count
                            _buildStatBadge(
                              icon: Icons.people_alt_rounded,
                              count: event.currentAttendees,
                              color: Colors.greenAccent[400]!,
                            ),
                            const SizedBox(width: 8),
                            // Interest Count
                            _buildStatBadge(
                              label: "📌",
                              count: event.interestedCount,
                              color: Colors.blueAccent[100]!,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Date & Location
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat(
                            'MMM d, HH:mm',
                          ).format(event.startTime.toLocal()),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location.name,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Price
                    Row(
                      children: [
                        Text(
                          event.isFree
                              ? "FREE"
                              : CurrencyFormatter.format(
                                  event.price?.round() ?? 0,
                                ),
                          style: const TextStyle(
                            color: Color(0xFFBBC863),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (!event.isFree)
                          const Text(
                            " /person",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),

                        const Spacer(),

                        const Text(
                          "Tap for details",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (event.isStartingSoon)
              Positioned(
                top: 24,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.timer, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        "Starting Soon",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    IconData? icon,
    String? label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, color: color, size: 14),
          if (label != null) Text(label, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            "$count",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
