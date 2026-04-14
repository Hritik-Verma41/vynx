class DataUsageSettingsModel {
  final String? id;
  final String user;
  final bool dataSaver;

  final bool mobilePhotos;
  final bool mobileVideos;
  final bool mobileAudio;
  final bool mobileDocuments;

  final bool wifiPhotos;
  final bool wifiVideos;
  final bool wifiAudio;
  final bool wifiDocuments;

  final bool roamingPhotos;
  final bool roamingVideos;
  final bool roamingAudio;
  final bool roamingDocuments;

  final DateTime updatedAt;

  DataUsageSettingsModel({
    this.id,
    required this.user,
    this.dataSaver = false,
    this.mobilePhotos = true,
    this.mobileVideos = false,
    this.mobileAudio = false,
    this.mobileDocuments = false,
    this.wifiPhotos = true,
    this.wifiVideos = true,
    this.wifiAudio = true,
    this.wifiDocuments = true,
    this.roamingPhotos = false,
    this.roamingVideos = false,
    this.roamingAudio = false,
    this.roamingDocuments = false,
    required this.updatedAt,
  });

  factory DataUsageSettingsModel.fromJson(Map<String, dynamic> json) {
    return DataUsageSettingsModel(
      id: json['_id'],
      user: json['user'] ?? '',
      dataSaver: json['dataSaver'] ?? false,
      mobilePhotos: json['mobilePhotos'] ?? true,
      mobileVideos: json['mobileVideos'] ?? false,
      mobileAudio: json['mobileAudio'] ?? false,
      mobileDocuments: json['mobileDocuments'] ?? false,
      wifiPhotos: json['wifiPhotos'] ?? true,
      wifiVideos: json['wifiVideos'] ?? true,
      wifiAudio: json['wifiAudio'] ?? true,
      wifiDocuments: json['wifiDocuments'] ?? true,
      roamingPhotos: json['roamingPhotos'] ?? false,
      roamingVideos: json['roamingVideos'] ?? false,
      roamingAudio: json['roamingAudio'] ?? false,
      roamingDocuments: json['roamingDocuments'] ?? false,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'dataSaver': dataSaver,
        'mobilePhotos': mobilePhotos,
        'mobileVideos': mobileVideos,
        'mobileAudio': mobileAudio,
        'mobileDocuments': mobileDocuments,
        'wifiPhotos': wifiPhotos,
        'wifiVideos': wifiVideos,
        'wifiAudio': wifiAudio,
        'wifiDocuments': wifiDocuments,
        'roamingPhotos': roamingPhotos,
        'roamingVideos': roamingVideos,
        'roamingAudio': roamingAudio,
        'roamingDocuments': roamingDocuments,
        'updatedAt': updatedAt.toIso8601String(),
      };

  DataUsageSettingsModel copyWith({
    bool? dataSaver,
    bool? mobilePhotos,
    bool? mobileVideos,
    bool? mobileAudio,
    bool? mobileDocuments,
    bool? wifiPhotos,
    bool? wifiVideos,
    bool? wifiAudio,
    bool? wifiDocuments,
    bool? roamingPhotos,
    bool? roamingVideos,
    bool? roamingAudio,
    bool? roamingDocuments,
    DateTime? updatedAt,
  }) {
    return DataUsageSettingsModel(
      id: id,
      user: user,
      dataSaver: dataSaver ?? this.dataSaver,
      mobilePhotos: mobilePhotos ?? this.mobilePhotos,
      mobileVideos: mobileVideos ?? this.mobileVideos,
      mobileAudio: mobileAudio ?? this.mobileAudio,
      mobileDocuments: mobileDocuments ?? this.mobileDocuments,
      wifiPhotos: wifiPhotos ?? this.wifiPhotos,
      wifiVideos: wifiVideos ?? this.wifiVideos,
      wifiAudio: wifiAudio ?? this.wifiAudio,
      wifiDocuments: wifiDocuments ?? this.wifiDocuments,
      roamingPhotos: roamingPhotos ?? this.roamingPhotos,
      roamingVideos: roamingVideos ?? this.roamingVideos,
      roamingAudio: roamingAudio ?? this.roamingAudio,
      roamingDocuments: roamingDocuments ?? this.roamingDocuments,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}