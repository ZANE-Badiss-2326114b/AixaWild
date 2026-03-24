import 'package:flutter/material.dart';

import '../../data/api/api_client.dart';
import '../../data/models/subscription.dart';
import '../../data/models/subscription_type.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../widgets/extranet_appbar.dart';

class HomeExtranetPage extends StatefulWidget {
  const HomeExtranetPage({super.key});

  @override
  State<HomeExtranetPage> createState() => _HomeExtranetPageState();
}

class _HomeExtranetPageState extends State<HomeExtranetPage> {
  final SubscriptionRepository _subscriptionRepository =
      SubscriptionRepository(ApiClient());

  late Future<SubscriptionDashboardData> _dashboardFuture;
  String _userEmail = '';
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;

    final routeArgument = ModalRoute.of(context)?.settings.arguments;
    if (routeArgument is String && routeArgument.trim().isNotEmpty) {
      _userEmail = routeArgument.trim();
    }

    _dashboardFuture = _subscriptionRepository.getDashboardData(_userEmail);
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: extranetAppBar(context, title: 'Accueil Extranet'),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return FutureBuilder<SubscriptionDashboardData>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Impossible de charger les abonnements pour $_userEmail.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return const Center(child: Text('Aucune donnée d’abonnement disponible.'));
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              _buildTitle(),
              const SizedBox(height: 8),
              _buildSubtitle(),
              const SizedBox(height: 24),
              _buildCurrentSubscriptionCard(data.currentSubscription),
              const SizedBox(height: 16),
              _buildAvailableTypesCard(data.availableTypes),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _dashboardFuture = _subscriptionRepository.getDashboardData(_userEmail);
    });
    await _dashboardFuture;
  }

  Widget _buildTitle() {
    return const Text(
      'Bienvenue sur l’extranet',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Accédez rapidement à vos actions principales.',
      style: TextStyle(color: Colors.grey[700]),
    );
  }

  Widget _buildCurrentSubscriptionCard(Subscription? current) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Abonnement actuel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (current == null)
              const Text('Aucun abonnement actuel trouvé pour cet utilisateur.')
            else ...[
              Text('Type : ${current.currentTypeLabel}'),
              if (current.status != null) Text('Statut : ${current.status}'),
              if (current.startDate != null)
                Text('Début : ${_formatDate(current.startDate!)}'),
              if (current.endDate != null)
                Text('Fin : ${_formatDate(current.endDate!)}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableTypesCard(List<SubscriptionType> types) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Types d’abonnement disponibles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (types.isEmpty)
              const Text('Aucun type d’abonnement disponible.')
            else
              ...types.map(_buildTypeLine),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeLine(SubscriptionType type) {
    final text = type.description != null && type.description!.isNotEmpty
        ? '${type.name} - ${type.description}'
        : type.name;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(text),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}
