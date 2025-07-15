



import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_service/feactures/categories/presentation/bloc/category_bloc.dart';
import 'package:message_service/feactures/categories/presentation/page/components_page.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {


  @override
  void initState() {
    context.read<CategoryBloc>().add(CategoryLoadEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Categories'),
      ),
      body:  BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, state) {
          if (state is CategoryLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CategoryLoadedState) {
            return ListView.builder(
              itemCount: state.categoryEntity.length,
              itemBuilder: (context, index) {
                final category = state.categoryEntity[index];
                return ListTile(
                  title: Text(category.name!),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ComponentPage(categoryEntity: category),
                    ));
                  },
                );
              },
            );
          } else if (state is CategoryErrorState) {
            return Center(child: Text(state.message));
          }
          return const Center(child: Text('No categories available'));
        },
      )
    );
    
  }
}