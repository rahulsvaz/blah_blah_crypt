import 'package:blah_blah_crypt/features/encryption/provider/decrypt_provider.dart';
import 'package:blah_blah_crypt/features/encryption/provider/encrypt_provider.dart';
import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context)=> EncryptProvider()),
        ChangeNotifierProvider(create: (context)=> DecryptProvider()),

      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: EncryptorApp(),
      ),
    );
  }
}


class EncryptorApp extends StatefulWidget {
  const EncryptorApp({super.key});

  @override
  State<EncryptorApp> createState() => _EncryptorAppState();
}

class _EncryptorAppState extends State<EncryptorApp> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _decryptController = TextEditingController();
  String _encryptedText = "";
  String _decryptedText = "";

  final key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows!'); // 32-byte key
  final iv = encrypt.IV.fromLength(16); // 16-byte IV

  /// Convert bytes to HEX string
  String bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Convert HEX string back to bytes
  List<int> hexToBytes(String hex) {
    return List.generate(hex.length ~/ 2, (i) {
      return int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    });
  }

  /// 🔒 Encrypt text
  void encryptText() {
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(_textController.text, iv: iv);

    // Convert both encrypted text & IV to HEX
    String encryptedHex = bytesToHex(encrypted.bytes);
    String ivHex = bytesToHex(iv.bytes);

    setState(() {
      _encryptedText = "$encryptedHex:$ivHex"; // Safe HEX format
    });
  }

  /// 🔓 Decrypt text
  void decryptText() {
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    try {
      String cleanedInput = _decryptController.text.trim().replaceAll("\n", "");

      List<String> parts = cleanedInput.split(":");
      if (parts.length != 2) {
        throw Exception("Invalid format");
      }

      // Convert HEX back to Uint8List
      final encryptedBytes = Uint8List.fromList(hexToBytes(parts[0]));
      final ivBytes = Uint8List.fromList(hexToBytes(parts[1]));

      final decrypted = encrypter.decrypt(
        encrypt.Encrypted(encryptedBytes),
        iv: encrypt.IV(ivBytes),
      );

      setState(() {
        _decryptedText = decrypted;
      });
    } catch (e) {
      setState(() {
        _decryptedText = "Invalid encrypted text!";
      });
    }
  }

  /// 📤 Share encrypted text via WhatsApp
  void shareText() {
    if (_encryptedText.isNotEmpty) {
      Share.share(_encryptedText);
    }
  }

  /// 📋 Copy text to clipboard
  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Copied to clipboard!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AES Encryptor (HEX)")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(labelText: "Enter text to encrypt"),
            ),
            SizedBox(height: 10),
            ElevatedButton(onPressed: encryptText, child: Text("Encrypt")),
            SelectableText("Encrypted: $_encryptedText"),
            Row(
              children: [
                IconButton(onPressed: shareText, icon: Icon(Icons.share)),
                IconButton(onPressed: () => copyToClipboard(_encryptedText), icon: Icon(Icons.copy)),
              ],
            ),
            Divider(),
            TextField(
              controller: _decryptController,
              decoration: InputDecoration(labelText: "Paste encrypted text to decrypt"),
            ),
            SizedBox(height: 10),
            ElevatedButton(onPressed: decryptText, child: Text("Decrypt")),
            SelectableText("Decrypted: $_decryptedText"),
          ],
        ),
      ),
    );
  }
}