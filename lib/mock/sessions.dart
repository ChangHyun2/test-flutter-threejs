class Session {
  final String sessionId;
  final String thumbnailPath;
  final String modelPath;
  final String redImagePath;
  final String redHeatImagePath;
  final String rgbImagePath;
  final DateTime date;
  final String title;
  final String description;

  Session({
    required this.sessionId,
    required this.thumbnailPath,
    required this.modelPath,
    required this.redImagePath,
    required this.redHeatImagePath,
    required this.rgbImagePath,
    required this.date,
    required this.title,
    required this.description,
  });
}

// 세션 목 데이터
final List<Session> mockSessions = [
  Session(
    sessionId: '1',
    thumbnailPath: 'assets/1/Rgb_F.jpg',
    modelPath: 'assets/1/model.obj',
    redImagePath: 'assets/1/Red_F.jpg',
    redHeatImagePath: 'assets/1/Red_heat_F.jpg',
    rgbImagePath: 'assets/1/Rgb_F.jpg',
    date: DateTime(2025, 11, 8, 10, 30),
    title: '세션 1',
    description: '첫 번째 스캔 세션',
  ),
  Session(
    sessionId: '2',
    thumbnailPath: 'assets/2/Rgb_F.jpg',
    modelPath: 'assets/2/model.obj',
    redImagePath: 'assets/2/Red_F.jpg',
    redHeatImagePath: 'assets/2/Red_heat_F.jpg',
    rgbImagePath: 'assets/2/Rgb_F.jpg',
    date: DateTime(2025, 11, 9, 14, 20),
    title: '세션 2',
    description: '두 번째 스캔 세션',
  ),
  Session(
    sessionId: '3',
    thumbnailPath: 'assets/3/Rgb_F.jpg',
    modelPath: 'assets/3/model.obj',
    redImagePath: 'assets/3/Red_F.jpg',
    redHeatImagePath: 'assets/3/Red_heat_F.jpg',
    rgbImagePath: 'assets/3/Rgb_F.jpg',
    date: DateTime(2025, 11, 10, 9, 15),
    title: '세션 3',
    description: '세 번째 스캔 세션',
  ),
];
