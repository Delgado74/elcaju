/// Modelo de clave P2PK
///
/// Representa una clave pública/privada para bloquear/desbloquear tokens Cashu
library;

import '../core/utils/nostr_utils.dart';

class P2PKKey {
  /// ID único de la clave
  final String id;

  /// Clave pública en formato hex (64 caracteres)
  final String publicKey;

  /// Clave privada en formato hex (64 caracteres)
  final String privateKey;

  /// true si fue derivada del mnemonic (NIP-06)
  final bool isDerived;

  /// Etiqueta para identificar la clave (ej: "Principal", "Mi Nostr")
  final String label;

  /// Fecha de creación
  final DateTime createdAt;

  const P2PKKey({
    required this.id,
    required this.publicKey,
    required this.privateKey,
    required this.isDerived,
    required this.label,
    required this.createdAt,
  });

  // ============ GETTERS PARA FORMATOS NOSTR ============

  /// Clave pública en formato npub (Nostr)
  String get npub => NostrUtils.hexToNpub(publicKey);

  /// Clave privada en formato nsec (Nostr)
  String get nsec => NostrUtils.hexToNsec(privateKey);

  // ============ SERIALIZACIÓN ============

  Map<String, dynamic> toJson() => {
        'id': id,
        'publicKey': publicKey,
        'privateKey': privateKey,
        'isDerived': isDerived,
        'label': label,
        'createdAt': createdAt.toIso8601String(),
      };

  factory P2PKKey.fromJson(Map<String, dynamic> json) => P2PKKey(
        id: json['id'] as String,
        publicKey: json['publicKey'] as String,
        privateKey: json['privateKey'] as String,
        isDerived: json['isDerived'] as bool,
        label: json['label'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  // ============ UTILIDADES ============

  P2PKKey copyWith({String? label}) => P2PKKey(
        id: id,
        publicKey: publicKey,
        privateKey: privateKey,
        isDerived: isDerived,
        label: label ?? this.label,
        createdAt: createdAt,
      );

  @override
  String toString() => 'P2PKKey(id: $id, label: $label, isDerived: $isDerived)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is P2PKKey &&
          runtimeType == other.runtimeType &&
          publicKey == other.publicKey;

  @override
  int get hashCode => publicKey.hashCode;
}
