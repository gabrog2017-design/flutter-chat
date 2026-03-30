import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../core/socket.dart';
import '../../core/constants.dart';

class CallScreen extends StatefulWidget {
  final String peerId, peerName;
  final bool isVideo, isCaller;
  const CallScreen({
    required this.peerId,
    required this.peerName,
    required this.isVideo,
    required this.isCaller,
    super.key,
  });
  @override State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  bool _muted = false;
  bool _speakerOn = true;
  bool _connected = false;
  bool _frontCamera = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': widget.isVideo
          ? {'facingMode': 'user', 'width': 640, 'height': 480}
          : false,
    });
    setState(() => _localRenderer.srcObject = _localStream);

    _pc = await createPeerConnection({
      'iceServers': AppConst.iceServers,
      'sdpSemantics': 'unified-plan',
    });

    for (final track in _localStream!.getTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }

    _pc!.onIceCandidate = (c) {
      if (c.candidate != null) {
        SocketService.sendIce(widget.peerId, c.toMap());
      }
    };

    _pc!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        setState(() => _connected = true);
      }
    };

    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        setState(() {
          _remoteStream = event.streams[0];
          _remoteRenderer.srcObject = _remoteStream;
        });
      }
    };

    // ── Signaling ───────────────────────────────────
    SocketService.on('call:answer', (data) async {
      await _pc!.setRemoteDescription(
          RTCSessionDescription(data['sdp'], data['type']));
    });

    SocketService.on('call:ice', (data) async {
      try {
        final c = data['candidate'];
        await _pc!.addCandidate(RTCIceCandidate(
            c['candidate'], c['sdpMid'], c['sdpMLineIndex']));
      } catch (_) {}
    });

    SocketService.on('call:end', (_) => _hangUp(notify: false));
    SocketService.on('call:reject', (_) => _hangUp(notify: false));

    if (widget.isCaller) {
      // Send offer
      final offer = await _pc!.createOffer();
      await _pc!.setLocalDescription(offer);
      SocketService.sendOffer(
          widget.peerId, offer.sdp!, offer.type!, widget.isVideo);
    } else {
      // Callee — wait for offer via socket (already received, create answer)
      SocketService.on('call:offer', (data) async {
        await _pc!.setRemoteDescription(
            RTCSessionDescription(data['sdp'], data['type']));
        final answer = await _pc!.createAnswer();
        await _pc!.setLocalDescription(answer);
        SocketService.sendAnswer(
            widget.peerId, answer.sdp!, answer.type!);
      });
    }

    setState(() {});
  }

  void _hangUp({bool notify = true}) {
    if (notify) SocketService.endCall(widget.peerId);
    _pc?.close();
    _localStream?.dispose();
    _remoteStream?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    if (mounted) Navigator.pop(context);
  }

  void _toggleMute() {
    _localStream?.getAudioTracks().forEach((t) => t.enabled = _muted);
    setState(() => _muted = !_muted);
  }

  void _toggleSpeaker() {
    setState(() => _speakerOn = !_speakerOn);
    // flutter_webrtc handles audio routing via track settings
  }

  Future<void> _flipCamera() async {
    if (!widget.isVideo) return;
    final tracks = _localStream?.getVideoTracks();
    if (tracks != null && tracks.isNotEmpty) {
      await Helper.switchCamera(tracks[0]);
      setState(() => _frontCamera = !_frontCamera);
    }
  }

  @override
  void dispose() {
    SocketService.off('call:answer');
    SocketService.off('call:ice');
    SocketService.off('call:end');
    SocketService.off('call:reject');
    SocketService.off('call:offer');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Stack(children: [
          // Remote video (full screen) or audio avatar
          if (widget.isVideo)
            Positioned.fill(
              child: RTCVideoView(_remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
            )
          else
            Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                CircleAvatar(
                    radius: 52,
                    child: Text(widget.peerName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 40))),
                const SizedBox(height: 20),
                Text(widget.peerName,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(_connected ? 'Connected' : 'Calling...',
                    style: const TextStyle(color: Colors.white60)),
              ]),
            ),

          // Local video (PiP)
          if (widget.isVideo)
            Positioned(
              right: 16, top: 16, width: 90, height: 130,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: RTCVideoView(_localRenderer, mirror: _frontCamera),
              ),
            ),

          // Status
          Positioned(
            top: 16, left: 0, right: 0,
            child: Text(
              _connected ? widget.peerName : 'Calling ${widget.peerName}...',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),

          // Controls
          Positioned(
            bottom: 30, left: 0, right: 0,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _ctrl(
                  icon: _muted ? Icons.mic_off : Icons.mic,
                  label: _muted ? 'Unmute' : 'Mute',
                  onTap: _toggleMute),
              // End call
              GestureDetector(
                onTap: _hangUp,
                child: Container(
                  width: 66, height: 66,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.call_end,
                      color: Colors.white, size: 30),
                ),
              ),
              if (widget.isVideo)
                _ctrl(icon: Icons.flip_camera_ios,
                    label: 'Flip', onTap: _flipCamera)
              else
                _ctrl(
                    icon: _speakerOn ? Icons.volume_up : Icons.volume_down,
                    label: 'Speaker',
                    onTap: _toggleSpeaker),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _ctrl(
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
              color: Colors.white24, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ]),
    );
  }
}
