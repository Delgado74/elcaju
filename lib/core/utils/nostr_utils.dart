/// Utilidades para conversión de claves Nostr (npub/nsec/hex)
///
/// Formatos soportados:
/// - npub1... (clave pública Nostr en bech32)
/// - nsec1... (clave privada Nostr en bech32)
/// - hex (64 caracteres hexadecimales)
/// - nostr:npub1... (URI de Nostr)
library;

import 'dart:typed_data';
import 'package:bech32/bech32.dart';

class NostrUtils {
  static const _npubHrp = 'npub';
  static const _nsecHrp = 'nsec';

  // ============ HEX -> BECH32 ============

  /// Convierte hex (64 chars) a npub
  static String hexToNpub(String hex) {
    final bytes = _hexToBytes(hex);
    final converted = _convertBits(bytes, 8, 5, true);
    final bech32Data = Bech32(_npubHrp, converted);
    return const Bech32Codec().encode(bech32Data);
  }

  /// Convierte hex (64 chars) a nsec
  static String hexToNsec(String hex) {
    final bytes = _hexToBytes(hex);
    final converted = _convertBits(bytes, 8, 5, true);
    final bech32Data = Bech32(_nsecHrp, converted);
    return const Bech32Codec().encode(bech32Data);
  }

  // ============ BECH32 -> HEX ============

  /// Convierte npub a hex
  static String? npubToHex(String npub) {
    try {
      print('[NostrUtils] npubToHex: decoding "$npub"');
      final decoded = const Bech32Codec().decode(npub);
      print('[NostrUtils] npubToHex: hrp=${decoded.hrp}, data length=${decoded.data.length}');
      if (decoded.hrp != _npubHrp) {
        print('[NostrUtils] npubToHex: hrp mismatch, expected $_npubHrp');
        return null;
      }
      final bytes = _convertBits(decoded.data, 5, 8, false);
      print('[NostrUtils] npubToHex: converted bytes length=${bytes.length}');
      final hex = _bytesToHex(Uint8List.fromList(bytes));
      print('[NostrUtils] npubToHex: result hex length=${hex.length}');
      return hex;
    } catch (e) {
      print('[NostrUtils] npubToHex error: $e');
      return null;
    }
  }

  /// Convierte nsec a hex
  static String? nsecToHex(String nsec) {
    try {
      final decoded = const Bech32Codec().decode(nsec);
      if (decoded.hrp != _nsecHrp) return null;
      final bytes = _convertBits(decoded.data, 5, 8, false);
      return _bytesToHex(Uint8List.fromList(bytes));
    } catch (e) {
      return null;
    }
  }

  // ============ NORMALIZACIÓN ============

  /// Normaliza input a hex (acepta npub, hex, nostr:npub)
  /// Retorna null si el input no es válido
  static String? normalizeToHex(String input) {
    input = input.trim();
    print('[NostrUtils] normalizeToHex input: "$input" (length: ${input.length})');

    // Remover prefijo nostr: si existe
    if (input.startsWith('nostr:')) {
      input = input.substring(6);
      print('[NostrUtils] Removed nostr: prefix, now: "$input"');
    }

    // Si es npub → convertir a hex
    if (input.startsWith('npub1')) {
      print('[NostrUtils] Detected npub, converting...');
      final result = npubToHex(input);
      print('[NostrUtils] npubToHex result: $result');
      return result;
    }

    // Si es hex válido (64 caracteres) → usar directo
    if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(input)) {
      print('[NostrUtils] Valid hex detected');
      return input.toLowerCase();
    }

    print('[NostrUtils] Invalid input - not npub nor valid hex');
    return null;
  }

  // ============ P2PK (SEC1 COMPRESSED) ============

  /// Normaliza input a clave pública comprimida SEC1 (66 hex chars)
  /// Cashu P2PK usa claves comprimidas de 33 bytes (prefijo 02 o 03)
  /// Acepta: npub, hex 64 chars (x-only), hex 66 chars (compressed)
  static String? normalizeToCompressedHex(String input) {
    input = input.trim();
    print('[NostrUtils] normalizeToCompressedHex input: "$input" (length: ${input.length})');

    // Remover prefijo nostr: si existe
    if (input.startsWith('nostr:')) {
      input = input.substring(6);
    }

    // Si ya es hex comprimido (66 chars con prefijo 02 o 03)
    if (RegExp(r'^0[23][0-9a-fA-F]{64}$').hasMatch(input)) {
      print('[NostrUtils] Already compressed SEC1 format');
      return input.toLowerCase();
    }

    // Si es npub → convertir a hex x-only → añadir prefijo 02
    if (input.startsWith('npub1')) {
      final xOnlyHex = npubToHex(input);
      if (xOnlyHex != null) {
        print('[NostrUtils] npub → x-only → adding 02 prefix');
        return '02$xOnlyHex';
      }
      return null;
    }

    // Si es hex x-only (64 chars) → añadir prefijo 02
    if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(input)) {
      print('[NostrUtils] x-only hex → adding 02 prefix');
      return '02${input.toLowerCase()}';
    }

    print('[NostrUtils] Invalid input for P2PK');
    return null;
  }

  /// Valida si un input es válido para P2PK
  static bool isValidP2PKPubkey(String input) {
    return normalizeToCompressedHex(input) != null;
  }

  // ============ VALIDACIÓN ============

  /// Valida si un input es una pubkey válida (npub o hex)
  static bool isValidPubkey(String input) {
    final hex = normalizeToHex(input);
    return hex != null && hex.length == 64;
  }

  /// Valida si es un nsec válido
  static bool isValidNsec(String input) {
    if (input.startsWith('nostr:')) input = input.substring(6);
    return input.startsWith('nsec1') && nsecToHex(input) != null;
  }

  /// Valida si es un npub válido
  static bool isValidNpub(String input) {
    if (input.startsWith('nostr:')) input = input.substring(6);
    return input.startsWith('npub1') && npubToHex(input) != null;
  }

  // ============ HELPERS PRIVADOS ============

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return result;
  }

  static String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Convierte bits entre bases (5 <-> 8) para bech32
  static List<int> _convertBits(
    List<int> data,
    int fromBits,
    int toBits,
    bool pad,
  ) {
    var acc = 0;
    var bits = 0;
    final result = <int>[];
    final maxv = (1 << toBits) - 1;

    for (final value in data) {
      acc = (acc << fromBits) | value;
      bits += fromBits;
      while (bits >= toBits) {
        bits -= toBits;
        result.add((acc >> bits) & maxv);
      }
    }

    if (pad && bits > 0) {
      result.add((acc << (toBits - bits)) & maxv);
    }

    return result;
  }
}
