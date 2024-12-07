import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'services/proto/CompteService.pbgrpc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'gRPC Flutter Test',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        cardColor: Colors.teal.shade50,
        dialogBackgroundColor: Colors.teal.shade100,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final channel = ClientChannel(
    'localhost', // Replace with your server address
    port: 9090, // Replace with your server port
    options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
  );

  late final CompteServiceClient stub;

  List<Compte> comptes = [];

  @override
  void initState() {
    super.initState();
    stub = CompteServiceClient(channel);
  }

  Future<void> fetchAllComptes() async {
    try {
      final request = GetAllComptesRequest();
      final response = await stub.allComptes(request);
      setState(() {
        comptes = response.comptes;
      });
    } catch (e) {
      setState(() {
        comptes = [];
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to fetch comptes: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> addCompte(CompteRequest compteRequest) async {
    try {
      final request = SaveCompteRequest(compte: compteRequest);
      final response = await stub.saveCompte(request);
      setState(() {
        comptes.add(response.compte);
      });
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to add compte: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> removeCompte(int id) async {
    try {
      final request = DeleteCompteRequest(id: id);
      await stub.deleteCompte(request);
      setState(() {
        comptes.removeWhere((compte) => compte.id == id);
      });
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to delete compte: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void showAddCompteDialog() {
    final soldeController = TextEditingController();
    final dateController = TextEditingController();
    TypeCompte? selectedType;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Compte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: soldeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Solde'),
            ),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: 'Date Creation'),
            ),
            DropdownButton<TypeCompte>(
              value: selectedType,
              hint: const Text('Select Type'),
              items: TypeCompte.values
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.toString().split('.').last),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final solde = double.tryParse(soldeController.text) ?? 0.0;
              final dateCreation = dateController.text;
              if (selectedType != null) {
                final compteRequest = CompteRequest(
                  solde: solde,
                  dateCreation: dateCreation,
                  type: selectedType!,
                );
                addCompte(compteRequest);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('gRPC Flutter Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: comptes.length,
                  itemBuilder: (context, index) {
                    final compte = comptes[index];
                    return Card(
                      color: Theme.of(context).cardColor,
                      child: ListTile(
                        title: Text('ID: ${compte.id}, Solde: ${compte.solde}',
                            style: TextStyle(color: Colors.teal.shade800)),
                        subtitle: Text(
                          'Type: ${compte.type}, Date: ${compte.dateCreation}',
                          style: TextStyle(color: Colors.teal.shade700),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => removeCompte(compte.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: fetchAllComptes,
                child: const Text('Fetch All Comptes'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: showAddCompteDialog,
                child: const Text('Add Compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    channel.shutdown();
    super.dispose();
  }
}
