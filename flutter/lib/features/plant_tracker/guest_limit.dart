import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import 'providers/plant_batch_provider.dart';

/// Guests can keep one plant batch. Asking for a second offers sign-up instead.
///
/// Call before opening the create-batch sheet, so nobody fills in a form only
/// to be turned away.
Future<bool> canCreateBatch(BuildContext context) async {
  if (context.read<AuthProvider>().isAuthenticated) return true;

  final batches = context.read<PlantBatchProvider>();
  if (batches.loading) await batches.loadBatches();
  if (batches.isEmpty || !context.mounted) return true;

  final signUp = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.eco_outlined),
      title: const Text('Create an account to add more plants'),
      content: const Text(
        'As a guest you can track one plant batch. A free account lets you '
        'track as many as you like. It is stored only on this phone, and your '
        'current plant stays.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Create account'),
        ),
      ],
    ),
  );
  if (signUp == true && context.mounted) {
    Navigator.pushNamed(context, '/register');
  }
  return false;
}
