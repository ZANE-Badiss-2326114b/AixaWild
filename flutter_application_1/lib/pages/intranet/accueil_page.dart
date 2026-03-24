import 'package:flutter/material.dart';

import '../../data/api/api_client.dart';
import '../../data/models/subscription.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../shared/navigation/app_routes.dart';
import '../../widgets/intranet_appbar.dart';

class AccueilIntranetPage extends StatefulWidget {
  const AccueilIntranetPage({super.key});

  @override
  State<AccueilIntranetPage> createState() => _AccueilIntranetPageState();
}

class _AccueilIntranetPageState extends State<AccueilIntranetPage> {
  final SubscriptionRepository _subscriptionRepository =
      SubscriptionRepository(ApiClient());
  
  late Future<Subscription?> _subscriptionFuture;
  String _userEmail = '';
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;

    final routeArgument = ModalRoute.of(context)?.settings.arguments;
    if (routeArgument is String && routeArgument.trim().isNotEmpty) {
      _userEmail = routeArgument.trim();
      _subscriptionFuture = _subscriptionRepository.getCurrentByUser(_userEmail);
    } else {
      _subscriptionFuture = Future.value(null);
    }

    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: intranetAppBar(title: 'AixaWild'),
      body: _buildBody(context),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildUserGreetingHeader(),
          const SizedBox(height: 20),
          _buildWelcomeHeader(),
          const SizedBox(height: 20),
          _buildQuickActionsRow(context),
          const SizedBox(height: 30),
          _buildDiscoveriesHeader(),
          _buildObservationItem('Sanglier', 'Faune', 'Il y a 2h', Icons.pets),
          _buildObservationItem('Olivier', 'Flore', 'Hier', Icons.local_florist),
          _buildObservationItem('Cigale', 'Faune', '28 Fév', Icons.bug_report),
        ],
      ),
    );
  }

  Widget _buildUserGreetingHeader() {
    return FutureBuilder<Subscription?>(
      future: _subscriptionFuture,
      builder: (context, snapshot) {
        final subscription = snapshot.data;
        final subscriptionLabel = subscription?.currentTypeLabel ?? 'Gratuit';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: Colors.blue[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonjour,',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _userEmail.isEmpty ? 'Utilisateur' : _userEmail.split('@').first,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Abonnement: $subscriptionLabel',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[800],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: const Column(
        children: [
          Text(
            'Bienvenue à Aix-en-Provence',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 10),
          Text(
            '12 Observations',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'cette semaine',
            style: TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildQuickAction(Icons.map, 'Carte', Colors.blue),
          const SizedBox(width: 15),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.intranetMesFiches);
            },
            child: _buildQuickAction(Icons.list, 'Mes fiches', Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveriesHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Dernières découvertes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(onPressed: () {}, child: const Text('Voir tout')),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.pushNamed(context, AppRoutes.intranetFormulaire);
      },
      label: const Text('Recenser'),
      icon: const Icon(Icons.add_a_photo),
      backgroundColor: Colors.green[700],
      foregroundColor: Colors.white,
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservationItem(
    String titre,
    String sousTitre,
    String date,
    IconData icon,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green[100],
        child: Icon(icon, color: Colors.green[800]),
      ),
      title: Text(titre, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(sousTitre),
      trailing: Text(
        date,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }
}
