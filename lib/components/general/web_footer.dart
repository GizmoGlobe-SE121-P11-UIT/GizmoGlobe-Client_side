import 'package:flutter/material.dart';

class WebFooter extends StatelessWidget {
  const WebFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo and Description
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.computer,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'GizmoGlobe',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your trusted source for premium\nPC components and peripherals.',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              // Links Columns
              Expanded(
                child: _buildFooterColumn(context, 'Shop', [
                  'All Products',
                  'Best Sellers',
                  'New Arrivals',
                  'Deals',
                ]),
              ),
              Expanded(
                child: _buildFooterColumn(context, 'Support', [
                  'Help Center',
                  'Contact Us',
                  'Shipping Info',
                  'Returns',
                ]),
              ),
              Expanded(
                child: _buildFooterColumn(context, 'Company', [
                  'About Us',
                  'Careers',
                  'Press',
                  'Blog',
                ]),
              ),
              Expanded(
                child: _buildFooterColumn(context, 'Legal', [
                  'Privacy Policy',
                  'Terms of Service',
                  'Cookie Policy',
                  'Disclaimer',
                ]),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Divider(color: Theme.of(context).dividerColor),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2025 GizmoGlobe. All rights reserved.',
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  _buildSocialIcon(context, Icons.facebook),
                  const SizedBox(width: 12),
                  _buildSocialIcon(context, Icons.camera_alt),
                  const SizedBox(width: 12),
                  _buildSocialIcon(context, Icons.close), // X/Twitter
                  const SizedBox(width: 12),
                  _buildSocialIcon(context, Icons.play_arrow),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterColumn(
      BuildContext context, String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                link,
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildSocialIcon(BuildContext context, IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Icon(icon,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          size: 18),
    );
  }
}
