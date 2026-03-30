class AppConst {
  static const baseUrl = 'https://chat.easybrand.website';
  static const apiUrl  = '$baseUrl/api';
  static const wsUrl   = baseUrl;

  static const iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
  ];
}
