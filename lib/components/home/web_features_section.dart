import 'package:flutter/material.dart';

class WebFeaturesSection extends StatelessWidget {
  const WebFeaturesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80),
      child: Row(
        children: [
          Expanded(
            child: _buildFeature(
              context,
              Icons.local_shipping_outlined,
              'Free Shipping',
              'On orders over \$99',
            ),
          ),
          Expanded(
            child: _buildFeature(
              context,
              Icons.verified_user_outlined,
              '2-Year Warranty',
              'On all products',
            ),
          ),
          Expanded(
            child: _buildFeature(
              context,
              Icons.support_agent_outlined,
              '24/7 Support',
              'Expert assistance',
            ),
          ),
          Expanded(
            child: _buildFeature(
              context,
              Icons.lock_outline,
              'Secure Payment',
              'SSL encrypted',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(
      BuildContext context, IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: Theme.of(context).colorScheme.onPrimary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
