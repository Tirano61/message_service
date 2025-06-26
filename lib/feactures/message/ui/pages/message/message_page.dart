

import 'package:flutter/material.dart';

class MessagePage extends StatelessWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 6,
        title: const Text('Messages'),
      ),
      body: const Center(
        child: Text('No messages yet!'),
      ),
    );
  }
}