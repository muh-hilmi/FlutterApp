import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/event.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

import '../../bloc/tickets/tickets_bloc.dart';
import '../../bloc/tickets/tickets_state.dart';
import '../../bloc/tickets/tickets_event.dart';
import '../../bloc/qna/qna_bloc.dart';
import '../../bloc/qna/qna_event.dart';
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_event.dart';
import '../../bloc/events/events_state.dart';
import '../../../injection_container.dart' as di;
import '../../../core/services/auth_service.dart';

// Components
import 'package:anigmaa/presentation/widgets/tickets/join_confirmation_ticket.dart';
import '../../widgets/common/flying_emoji.dart';
import 'components/event_action_buttons.dart';
import 'components/event_image_header.dart';
import 'components/event_sticky_header.dart';
import 'widgets/event_content.dart';
import '../../../../presentation/pages/payment/payment_screen.dart';
import '../tickets/ticket_detail_screen.dart';
import '../EXPERIMENTAL/tickets/host_checkin_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen>
    with TickerProviderStateMixin {
  TicketsBloc? _ticketsBloc;
  QnABloc? _qnaBloc;
  EventsBloc? _eventsBloc;
  ScrollController? _scrollController;
  late AuthService _authService;

  // Sheet Controller
  late AnimationController _sheetController;

  // Floating Emojis for Double Tap
  final List<Widget> _floatingEmojis = [];

  bool _showStickyTitle = false;
  bool _showConfirmation = false;
  // ignore: unused_field
  int _currentImageIndex = 0;
  bool _hasUserTicket = false;   // true once we confirm user has a ticket
  bool _viewTicketPressed = false; // true when user explicitly taps "Lihat Tiket"

  @override
  void initState() {
    super.initState();

    // Initialize AuthService
    _authService = di.sl<AuthService>();

    // Only load QnA if this is not a preview event
    if (widget.event.id != 'preview') {
      _qnaBloc = di.sl<QnABloc>()..add(LoadEventQnA(widget.event.id));
    } else {
      _qnaBloc = null;
    }

    _ticketsBloc = di.sl<TicketsBloc>();
    _eventsBloc = di.sl<EventsBloc>();
    _scrollController = ScrollController();

    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 300),
    );

    _scrollController?.addListener(_onScroll);

    // Fetch fresh event data + check if user already has a ticket
    if (widget.event.id != 'preview') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _eventsBloc?.add(LoadEventById(widget.event.id));

        final userId = _authService.userId;
        if (userId != null && userId.isNotEmpty) {
          _ticketsBloc!.add(
            LoadTicketForEvent(userId: userId, eventId: widget.event.id),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _scrollController?.dispose();
    _qnaBloc?.close(); // Safe to call on null
    _ticketsBloc?.close();
    _eventsBloc?.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController != null && _scrollController!.hasClients) {
      if (_scrollController!.offset > 300 && !_showStickyTitle) {
        setState(() {
          _showStickyTitle = true;
        });
      } else if (_scrollController!.offset <= 300 && _showStickyTitle) {
        setState(() {
          _showStickyTitle = false;
        });
      }
    }
  }

  void _triggerJumpingEmoji(Offset tapPosition) {
    // Always resolve the freshest event from state (prefer state over widget)
    final blobState = _eventsBloc?.state;
    final Event eventToLike;
    if (blobState is EventsLoaded) {
      eventToLike = blobState.events
          .where((e) => e.id == widget.event.id)
          .firstOrNull ?? widget.event;
    } else {
      eventToLike = widget.event;
    }

    // Dispatch interest API call
    _eventsBloc?.add(LikeInterestRequested(eventToLike));

    // Always show flying emoji animation — was broken by early return before
    final key = UniqueKey();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final targetPosition = Offset(screenWidth - 60, screenHeight - 120);

    setState(() {
      _floatingEmojis.add(
        FlyingEmoji(
          key: key,
          startPosition: tapPosition - const Offset(25, 25),
          endPosition: targetPosition,
          emoji: '📌',
          size: 50,
          onAnimationComplete: () {
            if (mounted) {
              setState(() {
                _floatingEmojis.removeWhere((element) => element.key == key);
              });
            }
          },
        ),
      );
    });
  }

  void _onJoinPressed() {
    setState(() {
      _showConfirmation = true;
    });
    _sheetController.forward();
  }

  void _onViewTicketPressed() {
    final userId = _authService.userId;
    if (userId == null || userId.isEmpty) return;

    setState(() => _viewTicketPressed = true);
    _ticketsBloc!.add(
      LoadTicketForEvent(userId: userId, eventId: widget.event.id),
    );
  }

  void _onManagePressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            HostCheckInScreen(eventId: widget.event.id),
      ),
    );
  }

  Future<void> _dismissConfirmation() async {
    await _sheetController.reverse();
    if (mounted) {
      setState(() {
        _showConfirmation = false;
      });
    }
  }

  void _confirmJoin() {
    _handleJoin(widget.event);
    _dismissConfirmation();
  }

  void _handleJoin(Event event) {
    // Get actual user data from AuthService
    final userId = _authService.userId;
    final userName = _authService.userName;
    final userEmail = _authService.userEmail;

    if (userId == null || userId.isEmpty) {
      // User not logged in, show error or redirect to login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (event.isFree) {
      // For free events, purchase with amount 0.0
      // The BlocListener will handle success and navigate to ticket detail
      _ticketsBloc!.add(
        PurchaseTicketRequested(
          userId: userId,
          eventId: event.id,
          amount: 0.0,
          customerName: userName ?? 'User',
          customerEmail: userEmail ?? 'user@example.com',
        ),
      );
    } else {
      // For paid events, navigate to payment screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PaymentScreen(event: event)),
      );
    }
  }

  void _onSharePressed() {
    // TODO: Implement actual share logic
    Share.share('Check out this event: ${widget.event.title}');
  }

  void _onReportPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Laporan diterima. Tim kami akan segera cek! 👮'),
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build providers list conditionally - QnABloc can be null for preview events
    final providers = [
      BlocProvider<TicketsBloc>.value(value: _ticketsBloc!),
      BlocProvider<EventsBloc>.value(value: _eventsBloc!),
    ];

    // Only add QnABloc provider if it exists (not a preview event)
    if (_qnaBloc != null) {
      providers.add(BlocProvider<QnABloc>.value(value: _qnaBloc!));
    }

    return MultiBlocProvider(
      providers: providers,
      child: BlocBuilder<EventsBloc, EventsState>(
        builder: (context, state) {
          // Use event from state if available
          final eventFromState = (state is EventsLoaded)
              ? state.events.where((e) => e.id == widget.event.id).firstOrNull
              : null;

          final currentEvent = eventFromState ?? widget.event;

          return MultiBlocListener(
            listeners: [
              BlocListener<TicketsBloc, TicketsState>(
                listener: (context, state) {
                  if (state is TicketPurchased) {
                    setState(() => _hasUserTicket = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Terima kasih! Tiket kamu siap 🎉"),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    _eventsBloc?.add(LoadEventById(widget.event.id));
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TicketDetailScreen(ticket: state.ticket),
                          ),
                        ).then((result) {
                          // If ticket was cancelled, reload event to update isUserAttending
                          if (result == true && mounted) {
                            setState(() => _hasUserTicket = false);
                            _eventsBloc?.add(LoadEventById(widget.event.id));
                          }
                        });
                      }
                    });
                  } else if (state is TicketLoaded) {
                    if (_viewTicketPressed) {
                      // User tapped "Lihat Tiket" — navigate
                      setState(() => _viewTicketPressed = false);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TicketDetailScreen(ticket: state.ticket),
                        ),
                      ).then((result) {
                        // If ticket was cancelled, reload event to update isUserAttending
                        if (result == true && mounted) {
                          setState(() => _hasUserTicket = false);
                          _eventsBloc?.add(LoadEventById(widget.event.id));
                        }
                      });
                    } else {
                      // Initial check on screen open — just update button state
                      setState(() => _hasUserTicket = true);
                    }
                  } else if (state is TicketsError) {
                    if (_viewTicketPressed) {
                      // User tapped "Lihat Tiket" but failed
                      setState(() => _viewTicketPressed = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    // If initial check → silently ignore (user doesn't have ticket)
                  }
                },
              ),
              BlocListener<EventsBloc, EventsState>(
                listener: (context, state) {
                  if (state is EventsLoaded &&
                      state.createErrorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.createErrorMessage!),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  }
                },
              ),
            ],
            child: Scaffold(
              backgroundColor: AppColors.background,
              body: GestureDetector(
                onDoubleTap: () {
                  // Use center of screen as tap position for emoji animation
                  final screenWidth = MediaQuery.of(context).size.width;
                  final screenHeight = MediaQuery.of(context).size.height;
                  _triggerJumpingEmoji(
                    Offset(screenWidth / 2, screenHeight / 3),
                  );
                },
                child: Stack(
                  children: [
                    // 1. Main Content Scrollable
                    CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: EventImageHeader(
                            event: currentEvent,
                            onImageIndexChanged: (index) {
                              setState(() => _currentImageIndex = index);
                            },
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Transform.translate(
                            offset: const Offset(0, -8),
                            child: EventContent(event: currentEvent),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 100),
                        ), // Bottom padding
                      ],
                    ),

                    // 2. Sticky Header / Floating Back Button
                    if (_showStickyTitle)
                      EventStickyHeader(
                        event: currentEvent,
                        onBackPressed: () => Navigator.pop(context),
                        onSharePressed: _onSharePressed,
                        onReportPressed: _onReportPressed,
                      )
                    else
                      _buildFloatingAppBar(),

                    // 3. Floating Emojis Overlay
                    ..._floatingEmojis,

                    // Floating Bottom Action Buttons
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: EventActionButtons(
                        event: currentEvent,
                        isAttending: _hasUserTicket,
                        onJoinPressed: _onJoinPressed,
                        onManagePressed: _onManagePressed,
                        onViewTicketPressed: _onViewTicketPressed,
                        onInterestPressed: () {
                          _eventsBloc?.add(ToggleInterestRequested(currentEvent));
                        },
                      ),
                    ),

                    // Join Confirmation Sheet (Overlay)
                    if (_showConfirmation)
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
                                  onTap: _dismissConfirmation,
                                  child: Container(
                                    color: AppColors.primary.withValues(
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
                                      padding: const EdgeInsets.only(
                                        bottom: 0.0,
                                      ),
                                      child: Transform.translate(
                                        offset: Offset(
                                          0,
                                          500 *
                                              (1.0 -
                                                  CurvedAnimation(
                                                    parent: _sheetController,
                                                    curve: Curves.easeOutBack,
                                                  ).value),
                                        ),
                                        child: JoinConfirmationTicket(
                                          event: widget.event,
                                          onConfirm: _confirmJoin,
                                          onDismiss: _dismissConfirmation,
                                        ),
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
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCircleButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context),
              ),
              PopupMenuButton<String>(
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.white,
                    size: 22,
                  ),
                ),
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: AppColors.surface,
                surfaceTintColor: Colors.transparent,
                onSelected: (value) {
                  if (value == 'share') {
                    _onSharePressed();
                  } else if (value == 'report') {
                    _onReportPressed();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'share',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.share_rounded,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text('Bagikan Event', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.flag_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Laporkan Event',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.white, size: 22),
      ),
    );
  }

}

class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrls[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: AppColors.white),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error, color: AppColors.white),
                  ),
                ),
              );
            },
          ),
          if (widget.imageUrls.length > 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '${_currentIndex + 1} / ${widget.imageUrls.length}',
                style: AppTextStyles.bodyLargeBold.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
