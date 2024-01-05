import 'package:flutter/material.dart';
import 'package:flutter_totp/scan.page.dart';
import 'package:flutter_totp/list.page.dart';
import 'package:flutter_totp/totp_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => TotpProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TOTP Authenticater',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'Authenticator Home Page'),
      routes: {
        '/scan': (context) => const ScanPage(),
        '/list': (context) => const TotpListPage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  MyHomePage({super.key, required this.title});

  final TextEditingController controller = TextEditingController();

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            children: [
              ElevatedButton(
                child: const Text('List TOTP Keys'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TotpListPage(),
                    ),
                  );
                },
              ),
              ElevatedButton(
                child: const Text('Add TOTP Key'),
                onPressed: () {
                  // show a dialog to add a new key
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Add TOTP Key'),
                        content: TextField(
                          controller: widget.controller,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Key',
                          ),
                          onSubmitted: (String value) {
                            Provider.of<TotpProvider>(context, listen: false)
                                .addCode(value);
                            Navigator.pop(context);
                          },
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              String value = widget.controller.text;
                              Provider.of<TotpProvider>(context, listen: false)
                                  .addCode(value);
                              Navigator.pop(context);
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              ElevatedButton(
                onPressed: () {
                  Provider.of<TotpProvider>(context, listen: false)
                      .removeAllCodes();
                },
                child: const Text('Clear All'),
              )
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/scan');
          },
          tooltip: 'Scan QR Code',
          child: const Icon(Icons.qr_code_scanner),
        ));
  }
}
