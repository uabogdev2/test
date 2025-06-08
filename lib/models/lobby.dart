import 'package:cloud_firestore/cloud_firestore.dart';

enum LobbyStatus {
  waiting,    // En attente de joueurs
  starting,   // Décompte avant début
  inProgress, // Partie en cours
  finished    // Partie terminée
}

class Lobby {
  final String id;
  final String code;
  final String hostId;
  final List<String> playerIds;
  final List<String> playerNames;
  final int maxPlayers;
  final bool isPublic;
  final String status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final Map<String, String> roles; // playerId -> role
  final Map<String, int> roleDistribution; // roleId -> count

  const Lobby({
    required this.id,
    required this.code,
    required this.hostId,
    required this.playerIds,
    required this.playerNames,
    required this.maxPlayers,
    required this.isPublic,
    required this.status,
    required this.createdAt,
    this.startedAt,
    required this.roles,
    required this.roleDistribution,
  });

  // Création d'un nouveau lobby
  factory Lobby.create({
    required String hostId,
    required String hostName,
    required int maxPlayers,
    required bool isPublic,
    required String code,
    Map<String, int>? roleDistribution,
  }) {
    return Lobby(
      id: FirebaseFirestore.instance.collection('lobbies').doc().id,
      code: code,
      hostId: hostId,
      playerIds: [hostId],
      playerNames: [hostName],
      maxPlayers: maxPlayers,
      isPublic: isPublic,
      status: LobbyStatus.waiting.toString(),
      createdAt: DateTime.now(),
      roles: {},
      roleDistribution: roleDistribution ?? {},
    );
  }

  // Conversion depuis Firestore
  factory Lobby.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Lobby(
      id: doc.id,
      code: data['code'] ?? '',
      hostId: data['hostId'] ?? '',
      playerIds: List<String>.from(data['playerIds'] ?? []),
      playerNames: List<String>.from(data['playerNames'] ?? []),
      maxPlayers: data['maxPlayers'] ?? 4,
      isPublic: data['isPublic'] ?? false,
      status: data['status'] ?? 'waiting',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: data['startedAt'] != null 
        ? (data['startedAt'] as Timestamp).toDate()
        : null,
      roles: Map<String, String>.from(data['roles'] ?? {}),
      roleDistribution: Map<String, int>.from(data['roleDistribution'] ?? {}),
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'hostId': hostId,
      'playerIds': playerIds,
      'playerNames': playerNames,
      'maxPlayers': maxPlayers,
      'isPublic': isPublic,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'roles': roles,
      'roleDistribution': roleDistribution,
    };
  }

  // Vérifier si le lobby est plein
  bool isFull() => playerIds.length >= maxPlayers;

  // Vérifier si un joueur est dans le lobby
  bool hasPlayer(String playerId) => playerIds.contains(playerId);

  // Vérifier si un joueur est l'hôte
  bool isHost(String playerId) => hostId == playerId;

  // Copier avec modifications
  Lobby copyWith({
    String? id,
    String? code,
    String? hostId,
    List<String>? playerIds,
    List<String>? playerNames,
    int? maxPlayers,
    bool? isPublic,
    String? status,
    DateTime? createdAt,
    DateTime? startedAt,
    Map<String, String>? roles,
    Map<String, int>? roleDistribution,
  }) {
    return Lobby(
      id: id ?? this.id,
      code: code ?? this.code,
      hostId: hostId ?? this.hostId,
      playerIds: playerIds ?? this.playerIds,
      playerNames: playerNames ?? this.playerNames,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      isPublic: isPublic ?? this.isPublic,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      roles: roles ?? this.roles,
      roleDistribution: roleDistribution ?? this.roleDistribution,
    );
  }

  bool canJoin(String userId) => !isFull() && !playerIds.contains(userId);
} 