import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'bet_model.dart';
import 'database_helper.dart';
import 'notification_service.dart';
import 'screens/add_edit_bet_screen.dart';
import 'screens/bet_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  await DatabaseHelper().database; // Ensure DB is initialized
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Singleplayer Bets',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Bet>> _betsFuture;
  late Future<double?> _scoreFuture;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _refreshData();
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isDenied) {
      // You can show a dialog to the user explaining why the permission is needed.
      print("Notification permission was denied.");
    }
  }

  void _refreshData() {
    setState(() {
      _betsFuture = DatabaseHelper().getBets();
      _scoreFuture = DatabaseHelper().calculateAverageLogLoss();
    });
  }

  void _navigateAndRefresh(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => screen),
    ).then((_) => _refreshData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 150.0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Theme.of(context).primaryColor,
                child: Center(
                  child: _buildScoreCard(),
                ),
              ),
            ),
          ),
          _buildBetList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateAndRefresh(AddEditBetScreen(onSave: _refreshData)),
        tooltip: 'New Bet',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildScoreCard() {
    return FutureBuilder<double?>(
      future: _scoreFuture,
      builder: (context, snapshot) {
        Widget content;
        if (snapshot.connectionState == ConnectionState.waiting) {
          content = const CircularProgressIndicator(color: Colors.white);
        } else if (snapshot.hasError) {
          content = const Text('Error', style: TextStyle(color: Colors.white));
        } else if (snapshot.hasData && snapshot.data != null) {
          final score = -snapshot.data!;
          content = Text(
            (-score).toStringAsFixed(2),
            style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
          );
        } else {
          content = const Text(
            'No bets resolved yet',
            style: TextStyle(color: Colors.white, fontSize: 18),
          );
        }
        return Card(
          color: Theme.of(context).primaryColorDark,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('AVG LOG LOSS', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                content,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBetList() {
    return FutureBuilder<List<Bet>>(
      future: _betsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError) {
          return const SliverFillRemaining(child: Center(child: Text('Error loading bets.')));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverFillRemaining(child: Center(child: Text('No bets yet. Add one!')));
        } else {
          final bets = snapshot.data!;
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final bet = bets[index];
                return BetListItem(
                  bet: bet,
                  onTap: () => _navigateAndRefresh(
                    BetDetailScreen(bet: bet, onUpdate: _refreshData),
                  ),
                );
              },
              childCount: bets.length,
            ),
          );
        }
      },
    );
  }
}

class BetListItem extends StatelessWidget {
  final Bet bet;
  final VoidCallback onTap;

  const BetListItem({Key? key, required this.bet, required this.onTap}) : super(key: key);

  Color _getBetColor() {
    if (bet.resolvedStatus == 1) return Colors.green;
    if (bet.resolvedStatus == 0) return Colors.red;
    return Colors.yellow;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: _getBetColor(),
      child: ListTile(
        onTap: onTap,
        title: Text(bet.content, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Resolves: ${DateFormat.yMMMd().format(bet.resolveDate)}'),
        trailing: Text(
          '${(bet.probability * 100).toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}