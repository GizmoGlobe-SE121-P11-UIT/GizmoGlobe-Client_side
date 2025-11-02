class Speed {
  int readMbps;
  int writeMbps;

  Speed({
    required this.readMbps,
    required this.writeMbps,
  });

  factory Speed.fromJson(Map<String, dynamic> json) => Speed(
        readMbps: (json['readMbps'] is num)
            ? (json['readMbps'] as num).toInt()
            : int.tryParse(json['readMbps']?.toString() ?? '') ?? 0,
        writeMbps: (json['writeMbps'] is num)
            ? (json['writeMbps'] as num).toInt()
            : int.tryParse(json['writeMbps']?.toString() ?? '') ?? 0,
      );
}