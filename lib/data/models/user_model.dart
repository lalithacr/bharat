class UserModel {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final String role;
  final double trustScore;
  final int rewardPoints;
  final String preferredLang;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.avatarUrl,
    this.role = 'citizen',
    this.trustScore = 0.5,
    this.rewardPoints = 0,
    this.preferredLang = 'en',
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id:            j['id']?.toString()           ?? '',
        name:          j['name']?.toString()         ?? 'Citizen',
        phone:         j['phone']?.toString(),
        email:         j['email']?.toString(),
        avatarUrl:     j['avatar_url']?.toString(),
        role:          j['role']?.toString()         ?? 'citizen',
        trustScore:    (j['trust_score'] as num?)?.toDouble() ?? 0.5,
        rewardPoints:  (j['reward_points'] as num?)?.toInt() ?? 0,
        preferredLang: j['preferred_lang']?.toString() ?? 'en',
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id':             id,
        'name':           name,
        'phone':          phone,
        'email':          email,
        'avatar_url':     avatarUrl,
        'role':           role,
        'trust_score':    trustScore,
        'reward_points':  rewardPoints,
        'preferred_lang': preferredLang,
        'created_at':     createdAt?.toIso8601String(),
      };
}
