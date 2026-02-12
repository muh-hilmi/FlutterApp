import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/qna.dart';
import '../../bloc/qna/qna_bloc.dart';
import '../../bloc/qna/qna_event.dart';
import '../../bloc/qna/qna_state.dart';
import '../profile/profile_screen.dart';

/// Screen for event hosts/organizers to manage Q&A
/// Features:
/// - View all questions for an event
/// - Answer unanswered questions
/// - Delete inappropriate questions
/// - Filter by answered/unanswered status
///
/// NOTE: This screen is used as a tab in EventManagementDashboard,
/// so it doesn't have its own Scaffold/AppBar. The parent provides them.
class HostQnAScreen extends StatefulWidget {
  final String eventId;
  final String? eventTitle;

  const HostQnAScreen({
    super.key,
    required this.eventId,
    this.eventTitle,
  });

  @override
  State<HostQnAScreen> createState() => _HostQnAScreenState();
}

class _HostQnAScreenState extends State<HostQnAScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load Q&A when screen is opened
    Future.microtask(() {
      context.read<QnABloc>().add(LoadEventQnA(widget.eventId));
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar for filtering
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFBBC863),
            unselectedLabelColor: Colors.grey[600],
            labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            indicatorColor: const Color(0xFFBBC863),
            tabs: const [
              Tab(text: 'Belum Dijawab'),
              Tab(text: 'Sudah Dijawab'),
            ],
          ),
        ),
        // Content
        Expanded(
          child: BlocBuilder<QnABloc, QnAState>(
            builder: (context, state) {
              if (state is QnALoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFBBC863)),
                );
              }

              if (state is QnAError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<QnABloc>().add(
                            LoadEventQnA(widget.eventId),
                          );
                        },
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                );
              }

              if (state is! QnALoaded) {
                return const SizedBox.shrink();
              }

              final unansweredQuestions = state.questions.where((q) => !q.isAnswered).toList();
              final answeredQuestions = state.questions.where((q) => q.isAnswered).toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildQuestionsList(unansweredQuestions, true),
                  _buildQuestionsList(answeredQuestions, false),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionsList(List<QnA> questions, bool isUnanswered) {
    if (questions.isEmpty) {
      return _buildEmptyState(isUnanswered);
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<QnABloc>().add(
          RefreshEventQnA(widget.eventId),
        );
        await Future.delayed(const Duration(seconds: 1));
      },
      color: const Color(0xFFBBC863),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          return _buildQuestionCard(questions[index], isUnanswered);
        },
      ),
    );
  }

  Widget _buildQuestionCard(QnA qna, bool isUnanswered) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isUnanswered
                      ? Colors.orange.withValues(alpha: 0.1)
                      : const Color(0xFFBBC863).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.help_outline,
                  color: isUnanswered ? Colors.orange[700] : const Color(0xFFBBC863),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      qna.question,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProfileScreen(userId: qna.askedBy.id),
                          ),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            const TextSpan(text: 'Ditanya oleh '),
                            TextSpan(
                              text: qna.askedBy.name,
                              style: const TextStyle(
                                color: Color(0xFFBBC863),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: ' · ${_formatTime(qna.askedAt)}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Answer section (for answered questions)
          if (!isUnanswered && qna.answer != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFCFCFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: Color(0xFFBBC863),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Jawaban Lo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFBBC863),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (qna.answeredAt != null)
                        Text(
                          _formatTime(qna.answeredAt!),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    qna.answer!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Upvote info
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.thumb_up_outlined,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                '${qna.upvotes} ${qna.upvotes == 1 ? 'orang' : 'orang'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Action buttons
          const SizedBox(height: 12),
          Row(
            children: [
              if (isUnanswered)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAnswerDialog(qna.id),
                    icon: const Icon(Icons.reply, size: 18),
                    label: const Text('Jawab'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBBC863),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              if (!isUnanswered) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditAnswerDialog(qna),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Jawaban'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFBBC863),
                      side: const BorderSide(color: Color(0xFFBBC863)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _confirmDelete(qna.id),
                icon: const Icon(Icons.delete_outline),
                color: Colors.red[600],
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isUnanswered) {
    final message = isUnanswered
        ? 'Wah, belum ada pertanyaan nih!\nSemua udah kejawab atau belum ada yang nanya.'
        : 'Belum ada jawaban.\nMasih ada ${isUnanswered ? 'pertanyaan' : 'pertanyaan'} yang belum dijawab.';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isUnanswered ? Icons.inbox_outlined : Icons.check_circle_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isUnanswered ? 'All Clear!' : 'Kosong',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showAnswerDialog(String questionId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Jawab Pertanyaan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tulis jawaban lo di sini...',
            filled: true,
            fillColor: const Color(0xFFFCFCFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final answer = controller.text.trim();
              if (answer.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Jawaban ga boleh kosong!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              context.read<QnABloc>().add(
                AnswerQuestionRequested(
                  questionId: questionId,
                  answer: answer,
                ),
              );

              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Jawaban terkirim! ✅'),
                    ],
                  ),
                  backgroundColor: Color(0xFFBBC863),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBBC863),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Kirim',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditAnswerDialog(QnA qna) {
    final controller = TextEditingController(text: qna.answer);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Edit Jawaban',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Edit jawaban lo di sini...',
            filled: true,
            fillColor: const Color(0xFFFCFCFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final answer = controller.text.trim();
              if (answer.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Jawaban ga boleh kosong!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              context.read<QnABloc>().add(
                AnswerQuestionRequested(
                  questionId: qna.id,
                  answer: answer,
                ),
              );

              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Jawaban diupdate! ✅'),
                    ],
                  ),
                  backgroundColor: Color(0xFFBBC863),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBBC863),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Simpan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String questionId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Hapus Pertanyaan?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
          ),
        ),
        content: const Text(
          'Pertanyaan bakal dihapus permanen. Lo yakin mau hapus?',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<QnABloc>().add(DeleteQuestionRequested(questionId));
              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Pertanyaan dihapus'),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}h lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}j lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m lalu';
    } else {
      return 'Baru saja';
    }
  }
}
