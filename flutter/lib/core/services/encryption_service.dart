import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

class EncryptionService extends GetxService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // AES-256 requires a 32-byte key.
  static const int _keyLength = 32;
  static const String _practiceKeyPrefix = 'practice_key_';

  /// Known verifier string used to check key validity.
  static const String keyVerifierMessage = 'DERMASCAN_VERIFIER';

  /// Generates the encrypted key verifier string for a practice key.
  String generateKeyVerifier({required String base64Key}) {
    return encryptData(plainText: keyVerifierMessage, base64Key: base64Key);
  }

  /// Verifies if [base64Key] correctly decrypts [keyVerifier].
  bool verifyKey({required String keyVerifier, required String base64Key}) {
    if (keyVerifier.isEmpty) return true;
    final String decrypted = decryptData(encryptedText: keyVerifier, base64Key: base64Key);
    return decrypted == keyVerifierMessage;
  }

  /// Generates a new cryptographically secure AES-256 key (base64 encoded).
  String generateKey() {
    final encrypt.Key key = encrypt.Key.fromSecureRandom(_keyLength);
    return key.base64;
  }

  /// Saves the key for a specific practice ID.
  Future<void> savePracticeKey({
    required String practiceId,
    required String base64Key,
  }) async {
    await _secureStorage.write(
      key: '$_practiceKeyPrefix$practiceId',
      value: base64Key,
    );
  }

  /// Retrieves the key for a specific practice ID.
  Future<String?> getPracticeKey({required String practiceId}) async {
    return await _secureStorage.read(key: '$_practiceKeyPrefix$practiceId');
  }

  /// Deletes the key for a specific practice ID.
  Future<void> deletePracticeKey({required String practiceId}) async {
    await _secureStorage.delete(key: '$_practiceKeyPrefix$practiceId');
  }

  /// Encrypts a string (e.g., JSON) using the provided base64 AES-256 key.
  /// Returns a base64 encoded string containing the IV and the encrypted data: "iv:encryptedData"
  String encryptData({required String plainText, required String base64Key}) {
    if (plainText.isEmpty) return plainText;

    final encrypt.Key key = encrypt.Key.fromBase64(base64Key);
    final encrypt.IV iv = encrypt.IV.fromSecureRandom(16); // 16 bytes for AES
    final encrypt.Encrypter encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final encrypt.Encrypted encrypted = encrypter.encrypt(plainText, iv: iv);
    
    // Format: base64(iv):base64(ciphertext)
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts a string that was encrypted by [encryptData].
  String decryptData({required String encryptedText, required String base64Key}) {
    if (encryptedText.isEmpty || !encryptedText.contains(':')) return encryptedText;

    final List<String> parts = encryptedText.split(':');
    if (parts.length != 2) return encryptedText; // Invalid format

    try {
      final encrypt.Key key = encrypt.Key.fromBase64(base64Key);
      final encrypt.IV iv = encrypt.IV.fromBase64(parts[0]);
      final String cipherText = parts[1];

      final encrypt.Encrypter encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      final String decrypted = encrypter.decrypt64(cipherText, iv: iv);

      return decrypted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Decryption error: $e');
      }
      return encryptedText; // Fallback to original text or throw an exception based on needs
    }
  }

  /// Checks if a key is valid by trying to create an AES encrypter with it.
  bool isValidKeyFormat({required String base64Key}) {
    try {
      final encrypt.Key key = encrypt.Key.fromBase64(base64Key);
      return key.bytes.length == _keyLength;
    } catch (e) {
      return false;
    }
  }

  /// Encrypts bytes (e.g., file data) using the provided base64 AES-256 key.
  /// Returns a new Uint8List containing the IV (first 16 bytes) and the encrypted data.
  Uint8List encryptBytes({required Uint8List plainBytes, required String base64Key}) {
    if (plainBytes.isEmpty) return plainBytes;

    final encrypt.Key key = encrypt.Key.fromBase64(base64Key);
    final encrypt.IV iv = encrypt.IV.fromSecureRandom(16);
    final encrypt.Encrypter encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final encrypt.Encrypted encrypted = encrypter.encryptBytes(plainBytes.toList(), iv: iv);

    // Prepend the 16-byte IV to the encrypted bytes
    final Uint8List result = Uint8List(16 + encrypted.bytes.length);
    result.setAll(0, iv.bytes);
    result.setAll(16, encrypted.bytes);

    return result;
  }

  /// Decrypts bytes that were encrypted by [encryptBytes].
  Uint8List decryptBytes({required Uint8List encryptedBytes, required String base64Key}) {
    if (encryptedBytes.length <= 16) return encryptedBytes; // Invalid or empty

    try {
      final encrypt.Key key = encrypt.Key.fromBase64(base64Key);
      final encrypt.IV iv = encrypt.IV(Uint8List.sublistView(encryptedBytes, 0, 16));
      final Uint8List cipherBytes = Uint8List.sublistView(encryptedBytes, 16);

      final encrypt.Encrypter encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      final List<int> decrypted = encrypter.decryptBytes(encrypt.Encrypted(cipherBytes), iv: iv);

      return Uint8List.fromList(decrypted);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Decryption error: $e');
      }
      return encryptedBytes; // Fallback
    }
  }
}
