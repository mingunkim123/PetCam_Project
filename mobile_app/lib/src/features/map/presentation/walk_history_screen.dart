import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/constants.dart';
import '../data/walk_repository.dart';
import '../domain/walk_session.dart';
import 'walk_detail_screen.dart';

class WalkHistoryScreen extends ConsumerStatefulWidget {
  const WalkHistoryScreen({super.key});

  @override
  ConsumerState<WalkHistoryScreen> createState() => _WalkHistoryScreenState();
}

class _WalkHistoryScreenState extends ConsumerState<WalkHistoryScreen> {
  late Future<List<WalkSession>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _refreshHistory();
  }

  void _refreshHistory() {
    setState(() {
      _historyFuture = ref.read(walkRepositoryProvider).getWalkSessions();
    });
  }

  Future<void> _deleteSession(String id) async {
    await ref.read(walkRepositoryProvider).deleteWalkSession(id);
    _refreshHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Walk Gallery",
          style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: kPrimaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<WalkSession>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final sessions = snapshot.data ?? [];

          if (sessions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_walk_rounded,
                    size: 60,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No walks recorded yet.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final duration = session.duration;
              final dateStr = DateFormat(
                'yyyy.MM.dd HH:mm',
              ).format(session.startTime);

              return Dismissible(
                key: Key(session.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.redAccent,
                  child: const Icon(Icons.delete_forever, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Delete Record"),
                      content: const Text(
                        "Are you sure you want to delete this walk?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) => _deleteSession(session.id),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF2F2F7), width: 1),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              WalkDetailScreen(session: session),
                        ),
                      );
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kAppBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        color: kSecondaryColor,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      dateStr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: kTextPrimary,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Text(
                            "${duration.inMinutes}분 산책",
                            style: const TextStyle(
                              fontSize: 14,
                              color: kTextSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(width: 1, height: 10, color: kTextTertiary),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.favorite_rounded,
                            size: 14,
                            color: kErrorColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${session.maxBpm} BPM",
                            style: const TextStyle(
                              fontSize: 14,
                              color: kTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: kTextTertiary,
                      size: 20,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
