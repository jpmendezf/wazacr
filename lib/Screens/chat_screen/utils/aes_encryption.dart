import 'dart:convert';

import 'package:encrypt/encrypt.dart';

class AESEncryptData {
//for AES Algorithms

  static Encrypted? encrypted;
  static var decrypted;
  static String pad(String s) {
    int l = 16 - utf8.encode(s).length % 16;
    return s + String.fromCharCode(0) * l;
  }

  static String? encryptAES(plainText, privatekey) {
    final key = Key.fromUtf8(privatekey.toString().substring(0, 32));
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    encrypted = encrypter.encrypt(pad(plainText), iv: iv);
    return encrypted!.base64;
  }

  static String? decryptAES(plainText, privatekey) {
    final key = Key.fromUtf8(privatekey.toString().substring(0, 32));
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    decrypted = encrypter.decrypt(Encrypted.from64(plainText), iv: iv);
    return decrypted.replaceAll(String.fromCharCode(0), "");
  }
}
