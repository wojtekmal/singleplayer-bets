import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../bet_model.dart';
import '../database_helper.dart';
import '../notification_service.dart';

class BetDetailScreen extends StatelessWidget {
  final Bet bet;
  final VoidCallback onUpdate;

  const BetDetailScreen({Key? key, required this.bet, required this.onUpdate}) : super(key: key);

  Future<void> _resolveBet(BuildContext context, int status) async {
    bet.resolvedStatus = status;
    await DatabaseHelper().updateBet(bet);
    await NotificationService().cancelBetNotifications(bet.id!);
    onUpdate();
    Navigator.of(context).pop();
  }

  Future<void> _changeResolution(BuildContext context) async {
    bet.resolvedStatus = (bet.resolvedStatus == 1) ? 0 : 1;
    await DatabaseHelper().updateBet(bet);
    onUpdate();
    Navigator.of(context).pop();
  }
  
  Future<void> _deleteBet(BuildContext context) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Do you want to permanently delete this bet?'),
        actions: [
          TextButton(
            child: const Text('Back'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper().deleteBet(bet.id!);
      await NotificationService().cancelBetNotifications(bet.id!);
      onUpdate();
      Navigator.of(context).pop();
    }
  }

  Color _getBetColor(Bet bet) {
    if (bet.resolvedStatus == 1) return Colors.green.shade100;
    if (bet.resolvedStatus == 0) return Colors.red.shade100;
    return Colors.yellow.shade100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bet Details'),
        backgroundColor: _getBetColor(bet).withOpacity(0.5),
      ),
      body: Container(
        color: _getBetColor(bet),
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              bet.content,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (bet.description.isNotEmpty) ...[
              Text(
                bet.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
            ],
            const Divider(),
            ListTile(
              title: const Text('Probability'),
              trailing: Text(
                '${(bet.probability * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              title: const Text('Created On'),
              trailing: Text(DateFormat.yMd().format(bet.createdDate)),
            ),
            ListTile(
              title: const Text('Resolves On'),
              trailing: Text(DateFormat.yMd().format(bet.resolveDate)),
            ),
            const Divider(),
            const SizedBox(height: 20),
            if (bet.resolvedStatus == null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _resolveBet(context, 1),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('YES'),
                  ),
                  ElevatedButton(
                    onPressed: () => _resolveBet(context, 0),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('NO'),
                  ),
                ],
              )
            else
              Center(
                child: ElevatedButton(
                  onPressed: () => _changeResolution(context),
                  child: const Text('Change Resolution'),
                ),
              ),
            const SizedBox(height: 40),
            Center(
              child: TextButton.icon(
                onPressed: () => _deleteBet(context),
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Delete Bet', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}