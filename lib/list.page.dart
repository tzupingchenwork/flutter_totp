import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_totp/totp_provider.dart';
import 'package:provider/provider.dart';

class TotpListPage extends StatefulWidget {
  const TotpListPage({super.key});
  @override
  TotpListPageState createState() => TotpListPageState();
}

class TotpListPageState extends State<TotpListPage> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TOTP List'),
      ),
      body: Consumer<TotpProvider>(builder: (context, totpProvider, child) {
        return ListView.builder(
          itemCount: totpProvider.jsonList.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> codeMap = totpProvider.jsonList[index];
            String type = codeMap['type'];
            String label = codeMap['label'];
            String secret = codeMap['secret'];
            String issuer = codeMap['issuer'];
            String code = codeMap['code'];
            double progress = totpProvider.remainingTime / 30;

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 10.0),
                title: Text(
                  'Label: $label\nType: $type\nIssuer: $issuer\nSecret: $secret\nCode: $code',
                  style: const TextStyle(
                      fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                trailing: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    CircularProgressIndicator(
                      value: progress, // 設置進度條進度
                      backgroundColor: Colors.grey[200],
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    Text('${totpProvider.remainingTime}s'),
                  ],
                ),
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListTile(
                            leading: const Icon(Icons.edit),
                            title: const Text('Edit'),
                            onTap: () {
                              final TextEditingController labelController =
                                  TextEditingController();

                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Edit Label'),
                                    content: TextField(
                                      controller: labelController,
                                      autofocus: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Label',
                                      ),
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
                                          // Update the label
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete),
                            title: const Text('Delete'),
                            onTap: () {
                              var totpProvider = Provider.of<TotpProvider>(
                                  context,
                                  listen: false);
                              // get the key from storage key
                              String key = totpProvider.jsonList[index]['key'];
                              print(key);
                              totpProvider.removeCode(key);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      }),
    );
  }
}
