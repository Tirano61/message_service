import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_service/feactures/categories/presentation/page/category_page.dart';
import 'package:message_service/feactures/conversation/domain/entities/converstion_entity.dart';
import 'package:message_service/feactures/conversation/presentation/bloc/conversation_bloc.dart';


class ConversationPage extends StatelessWidget {
  const ConversationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversaciones')),
      body: BlocBuilder<ConversationBloc, ConversationState>(
        builder: (context, state) {
          if (state is ConversationLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ConversationLoadedState) {
            final List<ConversationEntity> conversations = state.conversations;
            if (conversations.isEmpty) {
              return const Center(child: Text('No tienes conversaciones.'));
            }
            return ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return ListTile(
                  title: Text(conversation.title ?? 'Sin título'),
                  onTap: () {
                    // Navega a la pantalla de mensajes de esta conversación
                  },
                );
              },
            );
          } else if (state is ConversationErrorState) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navega a la página de categorías de productos
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CategoryPage()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Nueva conversación',
      ),
    );
  }
}