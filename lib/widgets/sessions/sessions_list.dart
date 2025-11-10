import 'package:flutter/material.dart';
import '../../mock/sessions.dart';
import 'session_card.dart';

class SessionsList extends StatelessWidget {
  final List<Session> sessions;

  const SessionsList({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const Center(
        child: Text(
          '세션이 없습니다',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SessionCard(session: sessions[index]),
        );
      },
    );
  }
}
