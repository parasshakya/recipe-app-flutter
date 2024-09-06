import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:recipe_flutter_app/components/RecipeCard.dart';
import 'package:recipe_flutter_app/constants.dart';
import 'package:recipe_flutter_app/models/recipe.dart';
import 'package:recipe_flutter_app/models/user.dart';
import 'package:recipe_flutter_app/providers/auth_provider.dart';
import 'package:recipe_flutter_app/providers/recipe_provider.dart';
import 'package:recipe_flutter_app/screens/login_screen.dart';
import 'package:recipe_flutter_app/screens/recipe_detail_screen.dart';
import 'package:recipe_flutter_app/services/api_services.dart';
import 'package:recipe_flutter_app/services/push_notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late AuthProvider authProvider;
  late RecipeProvider recipeProvider;
  ScrollController scrollController = ScrollController();

  bool fetchMoreLoading = false;

  fetchRecipes() async {
    fetchMoreLoading = true;
    setState(() {});

    try {
      recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
      await recipeProvider.fetchAllRecipes();
      if (recipeProvider.hasMore) {
        recipeProvider.currentPage++;
      }
    } catch (e) {
      showSnackbar("Error fetching recipes", context);
    } finally {
      setState(() {
        fetchMoreLoading = false;
      });
    }
  }

  @override
  void initState() {
    PushNotificationService().init();
    fetchRecipes();
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
              scrollController.position.maxScrollExtent &&
          !fetchMoreLoading &&
          recipeProvider.hasMore) {
        print("FETCHING MORE");
        fetchRecipes();
      }
    });
    super.initState();
  }

  logout() async {
    try {
      await authProvider.logout();
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const LoginScreen()));
      }
    } catch (e) {
      showSnackbar(e.toString(), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    authProvider = Provider.of<AuthProvider>(context);
    recipeProvider = Provider.of<RecipeProvider>(context);
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: Text("Home"),
              actions: [
                Text(authProvider.user!.username),
                const SizedBox(
                  width: 8,
                ),
                ElevatedButton(
                    onPressed: () {
                      logout();
                    },
                    child: const Text("Logout"))
              ],
            ),
            body: recipeProvider.recipes.isEmpty
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : recipeProvider.totalRecipeCount == 0
                    ? Center(child: Text("no recipes found "))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: recipeProvider.recipes.length +
                            (recipeProvider.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == recipeProvider.recipes.length) {
                            return SpinKitThreeBounce(
                              color: Colors.red,
                              size: 40,
                            );
                          }

                          final recipe = recipeProvider.recipes[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) =>
                                      RecipeDetailScreen(recipe: recipe)));
                            },
                            child: RecipeCard(
                                name: recipe.name,
                                imageUrl: recipe.image,
                                description: recipe.description),
                          );
                        })));
  }
}
