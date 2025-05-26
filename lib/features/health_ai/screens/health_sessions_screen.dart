import 'package:flutter/material.dart';
import 'package:mediconnect/core/models/health_ai_model.dart';
import 'package:mediconnect/features/health_ai/providers/health_ai_provider.dart';
import 'package:mediconnect/features/auth/providers/auth_provider.dart';
import 'package:mediconnect/shared/constants/colors.dart';
import 'package:mediconnect/shared/constants/styles.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'health_chat_screen.dart';

class HealthSessionsScreen extends StatefulWidget {
  const HealthSessionsScreen({Key? key}) : super(key: key);

  @override
  State<HealthSessionsScreen> createState() => _HealthSessionsScreenState();
}

class _HealthSessionsScreenState extends State<HealthSessionsScreen> {
  @override
  void initState() {
    super.initState();
    // Load sessions on screen open
    Future.microtask(() {
      Provider.of<HealthAIProvider>(context, listen: false).loadSessions();
      Provider.of<HealthAIProvider>(context, listen: false).loadSampleTopics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<HealthAIProvider>(context, listen: false)
                  .loadSessions();
            },
          ),
        ],
      ),
      body: Consumer<HealthAIProvider>(
        builder: (context, provider, child) {
          // Show loading indicator if loading and no sessions available
          if (provider.isLoading && provider.sessions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error message if there's an error and no sessions available
          if (provider.error != null && provider.sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${provider.error}',
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadSessions(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // If no sessions, show welcome screen
          if (provider.sessions.isEmpty) {
            return _buildWelcomeScreen(context, provider);
          }

          // Show list of sessions
          return ListView.builder(
            itemCount: provider.sessions.length,
            itemBuilder: (context, index) {
              final session = provider.sessions[index];
              return _buildSessionCard(context, session);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewSession(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, HealthSession session) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _openSession(context, session.id),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.health_and_safety, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      session.title,
                      style: AppStyles.heading1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    session.formattedDate,
                    style: AppStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (session.lastMessagePreview.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  session.lastMessagePreview,
                  style: AppStyles.bodyText2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(BuildContext context, HealthAIProvider provider) {
    // Get user role from auth provider
    final userRole =
        Provider.of<AuthProvider>(context, listen: false).user?.role ??
            'patient';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Icon(
              Icons.health_and_safety,
              size: 96,
              color: AppColors.primary.withOpacity(0.8),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to Health Assistant',
              style: TextStyle(
                fontSize: AppStyles.heading1.fontSize,
                fontWeight: AppStyles.heading1.fontWeight,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              userRole == 'patient'
                  ? 'Get answers to your health questions and analyze medical images with our AI assistant'
                  : 'Access medical information to assist with patient care and analyze medical documents',
              style: AppStyles.bodyText1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _createNewSession(context),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Start New Conversation'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 48),
            if (provider.sampleTopics.isNotEmpty) ...[
              Text(
                'Try asking about:',
                style: AppStyles.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...provider.sampleTopics.take(5).map(
                  (topic) => _buildSampleTopicCard(context, topic, userRole)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSampleTopicCard(
      BuildContext context, String topic, String userRole) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _createNewSessionWithTopic(context, topic, userRole),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.primary.withOpacity(0.7),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  topic,
                  style: AppStyles.bodyText2,
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createNewSession(BuildContext context) async {
    final userRole =
        Provider.of<AuthProvider>(context, listen: false).user?.role ??
            'patient';
    final provider = Provider.of<HealthAIProvider>(context, listen: false);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final session = await provider.createSession(
          userType: userRole == 'doctor' ? 'professional' : 'patient');

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to chat if session was created
      if (session != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HealthChatScreen(sessionId: session.id),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create session: $e')),
        );
      }
    }
  }

  Future<void> _createNewSessionWithTopic(
      BuildContext context, String topic, String userRole) async {
    final provider = Provider.of<HealthAIProvider>(context, listen: false);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final session = await provider.createSession(
          userType: userRole == 'doctor' ? 'professional' : 'patient');

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to chat if session was created
      if (session != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HealthChatScreen(
              sessionId: session.id,
              initialMessage: topic,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create session: $e')),
        );
      }
    }
  }

  void _openSession(BuildContext context, String sessionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HealthChatScreen(sessionId: sessionId),
      ),
    );
  }
}
