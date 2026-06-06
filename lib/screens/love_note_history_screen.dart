import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/couple.dart';
import '../models/love_note.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/love_note_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// "Note journal" (feature love-note-history): an append-only timeline of every
/// love note the couple has ever sent each other, newest-first. The Home card
/// still shows only the latest note; this screen is the kept archive.
///
/// Reads from [LoveNoteProvider.watchHistory] (a Firestore stream, or the local
/// Hive fallback). Each entry is a solid white card with the author's name, the
/// words, and the date — dark text on a light surface for readability.
class LoveNoteHistoryScreen extends StatelessWidget {
  const LoveNoteHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final couple = context.read<CoupleProvider>().couple;
    final myUid = context.read<AuthProvider>().currentUser?.id ?? '';

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.secondaryGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              LucideIcons.chevronLeft,
              size: 24,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            l10n.loveNoteHistoryTitle,
            style: AppTheme.displaySerif(
              size: 20,
              weight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.1,
              letterSpacing: -0.2,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: StreamBuilder<List<LoveNote>>(
            stream: context.read<LoveNoteProvider>().watchHistory(),
            builder: (context, snapshot) {
              final entries = snapshot.data ?? const <LoveNote>[];
              if (snapshot.connectionState == ConnectionState.waiting &&
                  entries.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.accentRose),
                  ),
                );
              }
              if (entries.isEmpty) {
                return _EmptyState(l10n: l10n);
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                itemCount: entries.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        l10n.loveNoteHistorySubtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    );
                  }
                  final note = entries[index - 1];
                  return _HistoryCard(
                    note: note,
                    isMine: note.authorUserId == myUid,
                    authorName: _authorName(couple, note.authorUserId, l10n),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String _authorName(Couple? couple, String authorUserId, AppLocalizations l10n) {
    if (couple == null) {
      return l10n.posterNameFallback;
    }
    final name = authorUserId == couple.createdByUserId
        ? couple.person1Name
        : couple.person2Name;
    final trimmed = name.trim();
    return trimmed.isNotEmpty ? trimmed : l10n.posterNameFallback;
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.note,
    required this.isMine,
    required this.authorName,
  });

  final LoveNote note;
  final bool isMine;
  final String authorName;

  @override
  Widget build(BuildContext context) {
    final when = note.updatedAt;
    final dateLabel = when == null
        ? ''
        : DateFormat.yMMMMd(Localizations.localeOf(context).toString())
            .add_Hm()
            .format(when);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentRose.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isMine ? LucideIcons.feather : LucideIcons.heart,
                size: 16,
                color: AppColors.accentRose,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  authorName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (dateLabel.isNotEmpty)
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            note.text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.cardSurface.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.mailOpen,
                size: 30,
                color: AppColors.accentRose,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.loveNoteHistoryEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
