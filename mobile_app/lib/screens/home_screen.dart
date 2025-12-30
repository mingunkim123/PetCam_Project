import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gal/gal.dart';

import '../constants.dart';
import '../providers/photo_provider.dart';
import '../models/pet_photo.dart';
import '../services/ble_service.dart';
import '../services/ai_service.dart';
import '../widgets/image_preview_list.dart';
import '../widgets/control_panel.dart';
import '../widgets/main_drawer.dart';
// 💡 산책 화면 이동을 위해 import 유지
import 'map_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BleService _bleService = BleService();
  final AiService _aiService = AiService();
  
  bool _isConnected = false;
  bool _isProcessing = false;
  int? _confirmedIndex;

  @override
  void initState() {
    super.initState();
    // BLE 연결 상태 감시
    _bleService.onConnectionChanged = (connected) {
      if (mounted) setState(() => _isConnected = connected);
    };

    // BLE로 사진 수신 시 Provider에 저장
    _bleService.onImageReceived = (Uint8List img) {
      if (mounted) {
        context.read<PhotoProvider>().addPhoto(img);
      }
    };
  }

  // AI 업스케일링 처리 로직
  Future<void> _handleAiUpscale(String photoId, Uint8List original) async {
    setState(() => _isProcessing = true);
    
    try {
      final upscaled = await _aiService.upscaleImage(original);
      
      if (upscaled != null && mounted) {
        context.read<PhotoProvider>().updateUpscaledPhoto(photoId, upscaled);
        _showComparisonSheet(original, upscaled);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ AI 서버 응답이 없습니다. 서버 상태를 확인하세요.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ 에러 발생: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // AI 변환 결과 비교 바텀 시트
  void _showComparisonSheet(Uint8List original, Uint8List upscaled) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text("✨ AI 업스케일링 결과", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildCompareLabel("원본 (Low-Res)", Colors.grey),
                    ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(original)),
                    const SizedBox(height: 24),
                    _buildCompareLabel("AI 고화질 (4x Super-Res)", kPrimaryColor),
                    ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(upscaled)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () async {
                  await Gal.putImageBytes(upscaled);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("📸 고화질 사진이 저장되었습니다!")));
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("이 사진 저장하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCompareLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      margin: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: _isConnected ? Colors.green : Colors.red),
          const SizedBox(width: 6),
          Text(
            _isConnected ? "ON" : "OFF",
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _isConnected ? Colors.green : Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pets_rounded, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text("아직 촬영된 사진이 없습니다.", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500)),
          Text("하단 셔터를 눌러 강아지를 찍어보세요!", style: TextStyle(color: Colors.grey[300], fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoProvider = context.watch<PhotoProvider>();
    final photos = photoProvider.photos;

    return Scaffold(
      backgroundColor: kBgColor,
      drawer: const MainDrawer(),
      appBar: AppBar(
        title: const Text("PetCam AI", style: TextStyle(fontWeight: FontWeight.w900, color: kPrimaryColor)),
        centerTitle: true,
        backgroundColor: kBgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: kPrimaryColor),
        actions: [_buildConnectionStatus()],
      ),
      
      // 💡 2. 기기 연결 + 산책 시작 버튼 통합 배치 (FAB 영역)
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 📡 기기 연결 버튼 (복구)
          FloatingActionButton.extended(
            heroTag: "connect_fab", // 💡 고유 태그 필수
            onPressed: () => _bleService.connectToDevice(),
            backgroundColor: _isConnected ? Colors.grey : Colors.blueGrey,
            icon: Icon(
              _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_searching, 
              color: Colors.white
            ),
            label: Text(
              _isConnected ? "연결됨" : "기기 연결", 
              style: const TextStyle(color: Colors.white)
            ),
          ),
          const SizedBox(height: 12), // 버튼 사이 간격
          // 🏃 산책 시작 버튼
          FloatingActionButton.extended(
            heroTag: "walk_fab", // 💡 고유 태그 필수
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MapScreen()),
              );
            },
            backgroundColor: kPrimaryColor,
            icon: const Icon(Icons.directions_walk_rounded, color: Colors.white),
            label: const Text(
              "산책 시작", 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          if (_isProcessing) const LinearProgressIndicator(color: kPrimaryColor, backgroundColor: Colors.transparent),
          Expanded(
            child: photos.isEmpty
                ? _buildEmptyState()
                : ImagePreviewList(
                    photos: photos,
                    recommendedIndex: _confirmedIndex,
                    confirmedIndex: _confirmedIndex,
                    onSelect: (idx) => setState(() => _confirmedIndex = idx),
                    onAiUpscale: (idx) => _handleAiUpscale(photos[idx].id, photos[idx].originalBytes),
                  ),
          ),
          ControlPanel(
            isConnected: _isConnected,
            isProcessing: _isProcessing,
            onSnap: () => _bleService.sendSnapCommand(),
            onBurst: () => _bleService.sendBurstCommand(),
            onConnect: () => _bleService.connectToDevice(),
          ),
        ],
      ),
    );
  }
}