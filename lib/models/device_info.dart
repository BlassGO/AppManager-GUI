class DeviceInfo {
  final String name;
  final String serial;
  final String connection;
  final bool isActive;

  DeviceInfo({
    required this.name,
    required this.serial,
    required this.connection,
    this.isActive = true,
  });
}