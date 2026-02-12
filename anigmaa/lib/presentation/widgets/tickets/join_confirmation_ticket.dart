import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../domain/entities/event.dart';

class JoinConfirmationTicket extends StatefulWidget {
  final Event event;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  const JoinConfirmationTicket({
    super.key,
    required this.event,
    required this.onConfirm,
    required this.onDismiss,
  });

  @override
  State<JoinConfirmationTicket> createState() => _JoinConfirmationTicketState();
}

class _JoinConfirmationTicketState extends State<JoinConfirmationTicket>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isConsentGiven = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Requirements text (fallback if empty)
    final String requirementsText =
        widget.event.requirements?.isNotEmpty == true
        ? widget.event.requirements!
        : "Peserta diharapkan membawa laptop sendiri, sepeda dan perlengkapan olahraga jika diperlukan, pakaian nyaman sesuai aktivitas, serta dokumen identitas untuk check-in.";

    return Material(
      color: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: ClipPath(
        clipper: _TicketClipper(),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600), // Max height cap
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === HEADER Section ===
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Image or Pulsing Pin
                      if (widget.event.fullImageUrls.isNotEmpty)
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFBBC863),
                              width: 2,
                            ),
                            image: DecorationImage(
                              image: CachedNetworkImageProvider(
                                widget.event.fullImageUrls.first,
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFBBC863,
                              ).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.push_pin_rounded,
                              color: Color(0xFFBBC863),
                              size: 20,
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.event.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildInfoRow(
                              Icons.calendar_today_rounded,
                              DateFormat(
                                'MMM d, yyyy • HH:mm',
                              ).format(widget.event.startTime.toLocal()),
                            ),
                            const SizedBox(height: 4),
                            _buildInfoRow(
                              Icons.location_on_rounded,
                              widget.event.location.name,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // === CUT-OUT LINE ===
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: List.generate(
                      24,
                      (index) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: Container(height: 1, color: Colors.grey[300]),
                        ),
                      ),
                    ),
                  ),
                ),

                // === BODY Section ===
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Special message for free events
                      if (widget.event.isFree)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBBC863).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFBBC863).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFBBC863).withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.card_giftcard_rounded,
                                  color: Color(0xFFBBC863),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  "Yeay! Event ini GRATIS. Tinggal klaim tiket kamu!",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF556018),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Requirements
                      _buildSectionTitle("Requirements"),
                      // const SizedBox(height: 4),
                      Text(
                        requirementsText,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Safety & Guidelines (Horizontal Icons)
                      _buildSectionTitle("Safety & Guidelines"),

                      Row(
                        children: [
                          _buildSafetyItem(Icons.verified_user_outlined, ""),
                          const SizedBox(width: 12),
                          _buildSafetyItem(
                            Icons.health_and_safety_outlined,
                            "Safety First",
                          ),
                          const SizedBox(width: 12),
                          _buildSafetyItem(Icons.block_outlined, "No Weapons"),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Terms & Consent
                      _buildSectionTitle("Terms & Data Consent"),
                      Text(
                        "Dengan bergabung, kamu setuju dengan Syarat & Ketentuan serta Kebijakan Refund.",
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black26),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _isConsentGiven,
                                activeColor: const Color(0xFFBBC863),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _isConsentGiven = val ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Saya setuju data saya digunakan oleh penyelenggara untuk kelancaran event.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // === ACTION Section ===
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      if (!_isConsentGiven)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            widget.event.isFree
                                ? "Centang kotak di atas dulu ya!"
                                : "Pastikan Anda sudah siap sebelum Confirm",
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isConsentGiven ? widget.onConfirm : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFBBC863),
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: Colors.black26,
                            disabledForegroundColor: Colors.black54,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            widget.event.isFree
                                ? "Klaim Tiket Gratis"
                                : "Proceed to Payment",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: widget.onDismiss,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black54,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text("Maybe Later"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        color: Colors.black,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.black54),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.black87, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black87),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double radius = 16.0;
    double notchRadius = 8.0;
    // Notch adjusted for header height approx (Header ~80-90px)
    double notchY = 90.0;

    path.moveTo(radius, 0);
    // Top Edge
    path.lineTo(size.width - radius, 0);
    path.arcToPoint(
      Offset(size.width, radius),
      radius: Radius.circular(radius),
    );

    // Right Side to Notch
    path.lineTo(size.width, notchY - notchRadius);
    path.arcToPoint(
      Offset(size.width, notchY + notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    // Right Side to Bottom
    path.lineTo(size.width, size.height - radius);
    path.arcToPoint(
      Offset(size.width - radius, size.height),
      radius: Radius.circular(radius),
    );

    // Bottom Edge
    path.lineTo(radius, size.height);
    path.arcToPoint(
      Offset(0, size.height - radius),
      radius: Radius.circular(radius),
    );

    // Left Side to Notch
    path.lineTo(0, notchY + notchRadius);
    path.arcToPoint(
      Offset(0, notchY - notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    // Left Side to Top
    path.lineTo(0, radius);
    path.arcToPoint(Offset(radius, 0), radius: Radius.circular(radius));

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
