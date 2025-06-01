import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mediconnect/core/models/health_ai_model.dart';
import 'package:mediconnect/features/health_ai/providers/health_ai_provider.dart';
import 'package:mediconnect/features/auth/providers/auth_provider.dart';
import 'package:mediconnect/shared/constants/colors.dart';
import 'package:provider/provider.dart';
import 'health_chat_screen.dart';

class HealthSessionsScreen extends StatefulWidget {
  const HealthSessionsScreen({Key? key}) : super(key: key);

  @override
  State<HealthSessionsScreen> createState() => _HealthSessionsScreenState();
}

class _HealthSessionsScreenState extends State<HealthSessionsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
    _loadInitialData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final showButton = _scrollController.offset > 300;
      if (showButton != _showScrollToTop) {
        setState(() => _showScrollToTop = showButton);
      }
    });
  }

  void _loadInitialData() {
    Future.microtask(() {
      final provider = Provider.of<HealthAIProvider>(context, listen: false);
      provider.loadSessions();
      provider.loadSampleTopics();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(context),
          _buildMainContent(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showScrollToTop)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton.small(
                heroTag: "scroll_to_top",
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                elevation: 2,
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Icon(Icons.keyboard_arrow_up),
              ),
            ),
          FloatingActionButton.extended(
            heroTag: "new_session",
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            onPressed: () => _createNewSession(context),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('New Chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Health Assistant',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                right: 50,
                top: 50,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Consumer<HealthAIProvider>(
          builder: (context, provider, child) {
            return IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh, color: Colors.white),
              ),
              onPressed: provider.isLoading
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      provider.loadSessions();
                    },
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMainContent() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Consumer<HealthAIProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.sessions.isEmpty) {
                return _buildLoadingState();
              }

              if (provider.error != null && provider.sessions.isEmpty) {
                return _buildErrorState(provider);
              }

              if (provider.sessions.isEmpty) {
                return _buildWelcomeScreen(context, provider);
              }

              return _buildSessionsList(provider);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Loading your conversations...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(HealthAIProvider provider) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                provider.error ?? 'Unknown error occurred',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  provider.loadSessions();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionsList(HealthAIProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            children: [
              Text(
                'Recent Conversations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${provider.sessions.length}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: provider.sessions.length,
          itemBuilder: (context, index) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 200 + (index * 50)),
              curve: Curves.easeOut,
              child: _buildSessionCard(context, provider.sessions[index], index),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSessionCard(BuildContext context, HealthSession session, int index) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        20,
        index == 0 ? 8 : 4,
        20,
        8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 4),
            blurRadius: 15,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            _openSession(context, session.id);
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Hero(
                      tag: 'session_icon_${session.id}',
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.1),
                              AppColors.primary.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.health_and_safety,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatSessionTime(session),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        session.formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (session.lastMessagePreview.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            session.lastMessagePreview,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(BuildContext context, HealthAIProvider provider) {
    final userRole = Provider.of<AuthProvider>(context, listen: false).user?.role ?? 'patient';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Hero(
            tag: 'welcome_icon',
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.health_and_safety,
                size: 80,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Welcome to Health Assistant',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            userRole == 'patient'
                ? 'Get personalized health insights and medical guidance from our AI assistant'
                : 'Access comprehensive medical resources and assist with patient consultations',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () => _createNewSession(context),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Start Your First Conversation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: AppColors.primary.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 60),
          if (provider.sampleTopics.isNotEmpty) ...[
            Text(
              'Popular Topics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ...provider.sampleTopics.take(4).map(
              (topic) => _buildSampleTopicCard(context, topic, userRole),
            ),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSampleTopicCard(BuildContext context, String topic, String userRole) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 4),
            blurRadius: 15,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            _createNewSessionWithTopic(context, topic, userRole);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    topic,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatSessionTime(HealthSession session) {
    // You would implement proper time formatting here
    // This is a placeholder - you should format based on session.timestamp
    return "2 hours ago";
  }

  Future<void> _createNewSession(BuildContext context) async {
    final userRole = Provider.of<AuthProvider>(context, listen: false).user?.role ?? 'patient';
    final provider = Provider.of<HealthAIProvider>(context, listen: false);

    _showLoadingDialog(context, 'Creating new session...');

    try {
      final session = await provider.createSession(
        userType: userRole == 'doctor' ? 'professional' : 'patient',
      );

      if (context.mounted) Navigator.pop(context);

      if (session != null && context.mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                HealthChatScreen(sessionId: session.id),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      _showErrorSnackBar(context, 'Failed to create session: $e');
    }
  }

  Future<void> _createNewSessionWithTopic(
      BuildContext context, String topic, String userRole) async {
    final provider = Provider.of<HealthAIProvider>(context, listen: false);

    _showLoadingDialog(context, 'Creating session with topic...');

    try {
      final session = await provider.createSession(
        userType: userRole == 'doctor' ? 'professional' : 'patient',
      );

      if (context.mounted) Navigator.pop(context);

      if (session != null && context.mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                HealthChatScreen(
              sessionId: session.id,
              initialMessage: topic,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      _showErrorSnackBar(context, 'Failed to create session: $e');
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.red.shade600,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _openSession(BuildContext context, String sessionId) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            HealthChatScreen(sessionId: sessionId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
      ),
    );
  }
}