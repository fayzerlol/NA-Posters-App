import 'package:flutter/material.dart';
import 'package:na_posters_app/pages/posters_list_page.dart';
import 'package:na_posters_app/pages/welcome_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Garantir que os widgets do Flutter estejam inicializados antes de qualquer outra coisa.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NaPostersApp());
}

class NaPostersApp extends StatefulWidget {
  const NaPostersApp({Key? key}) : super(key: key);

  @override
  State<NaPostersApp> createState() => _NaPostersAppState();
}

class _NaPostersAppState extends State<NaPostersApp> {
  late Future<Widget> _initialPageFuture;

  @override
  void initState() {
    super.initState();
    _initialPageFuture = _determineInitialPage();
  }

  Future<Widget> _determineInitialPage() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userName');
    final groupId = prefs.getInt('userGroupId');

    if (userName != null && userName.isNotEmpty && groupId != null) {
      // Se já temos os dados do usuário, vamos para a lista de cartazes.
      return const PostersListPage();
    } else {
      // Caso contrário, mostramos a tela de boas-vindas.
      return const WelcomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NA Posters',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // O FutureBuilder vai mostrar uma tela de carregamento enquanto
      // decidimos qual é a página inicial correta.
      home: FutureBuilder<Widget>(
        future: _initialPageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Tela de Splash/Carregamento
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasError) {
            // Em caso de erro, mostramos uma mensagem.
            return Scaffold(
              body: Center(
                child: Text('Erro ao inicializar o app: ${snapshot.error}'),
              ),
            );
          } else if (snapshot.hasData) {
            // Quando o futuro estiver completo, mostramos a página correta.
            return snapshot.data!;
          } else {
            // Fallback, embora não deva ser alcançado
            return const Scaffold(
              body: Center(
                child: Text('Algo deu errado.'),
              ),
            );
          }
        },
      ),
    );
  }
}
