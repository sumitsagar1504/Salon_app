import 'package:flutter/material.dart';

import '../theme/salon_theme.dart';

class SalonBrand extends StatelessWidget {
  const SalonBrand({super.key, this.compact = false, this.light = false});

  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : SalonTheme.ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 38 : 48,
          height: compact ? 38 : 48,
          decoration: BoxDecoration(
            color: light
                ? Colors.white.withValues(alpha: .12)
                : SalonTheme.blushSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.content_cut_rounded,
            color: light ? Colors.white : SalonTheme.blush,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'THE SALON',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            letterSpacing: compact ? 2.2 : 3.2,
            fontSize: compact ? 16 : 20,
          ),
        ),
      ],
    );
  }
}

class SalonPage extends StatelessWidget {
  const SalonPage({
    super.key,
    required this.child,
    this.maxWidth = SalonTheme.pageWidth,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: child,
        ),
      ),
    );
  }
}

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.form,
    required this.eyebrow,
    required this.headline,
    required this.description,
  });

  final Widget form;
  final String eyebrow;
  final String headline;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 880;
          final story = Container(
            padding: EdgeInsets.all(wide ? 56 : 28),
            decoration: const BoxDecoration(
              color: SalonTheme.ink,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SalonBrand(light: true),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: const TextStyle(
                        color: SalonTheme.champagne,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      headline,
                      style: Theme.of(
                        context,
                      ).textTheme.displaySmall?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 17,
                      color: SalonTheme.champagne,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Care, crafted around you',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          final formPanel = SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: wide ? 64 : 20,
              vertical: wide ? 48 : 28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: form,
              ),
            ),
          );

          if (wide) {
            return Row(
              children: [
                Expanded(flex: 5, child: story),
                Expanded(flex: 6, child: formPanel),
              ],
            );
          }
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [SalonTheme.blushSoft, SalonTheme.ivory],
                stops: [0, .32],
              ),
            ),
            child: formPanel,
          );
        },
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: SalonTheme.blush,
      fontSize: 11,
      letterSpacing: 1.8,
      fontWeight: FontWeight.w800,
    ),
  );
}

class SalonEmptyState extends StatelessWidget {
  const SalonEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: SalonTheme.blushSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: SalonTheme.blush),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: SalonTheme.taupe),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status.toLowerCase()) {
      'confirmed' => SalonTheme.success,
      'cancelled' => SalonTheme.danger,
      'pending' => SalonTheme.warning,
      _ => SalonTheme.taupe,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: .7,
        ),
      ),
    );
  }
}
