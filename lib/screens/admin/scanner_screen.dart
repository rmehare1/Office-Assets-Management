import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:office_assets_app/providers/asset_provider.dart';
import 'package:office_assets_app/theme/app_theme.dart';

/// Full-screen QR/Barcode scanner for asset registration and lookup.
/// Admin-only screen.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  late AnimationController _animController;
  late Animation<double> _scanLineAnimation;

  bool _isProcessing = false;
  bool _torchOn = false;
  String? _lastScannedCode;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    // Debounce: ignore if same code scanned again
    if (code == _lastScannedCode) return;
    _lastScannedCode = code;

    setState(() => _isProcessing = true);

    // Haptic feedback
    HapticFeedback.mediumImpact();

    _processScannedCode(code);
  }

  Future<void> _processScannedCode(String code) async {
    // Try to parse as JSON (structured QR with all asset data)
    Map<String, dynamic>? assetData;
    try {
      final parsed = jsonDecode(code);
      if (parsed is Map<String, dynamic> &&
          parsed.containsKey('serial_number')) {
        assetData = parsed;
        log('Ser::: ${assetData.toString()}');
      }
    } catch (_) {
      // Not JSON — treat as plain serial number / barcode
    }

    if (assetData != null) {
      // Structured QR code → navigate to asset form with all fields pre-filled
      if (mounted) {
        _scannerController.stop();
        context.go('/assets/new', extra: assetData);
      }
      return;
    }

    // Plain barcode → lookup by serial number
    final provider = context.read<AssetProvider>();
    final asset = await provider.lookupByCode(code);

    if (!mounted) return;

    if (asset != null) {
      // Asset found → navigate to detail
      _scannerController.stop();
      context.go('/assets/${asset.id}');
    } else {
      // Not found → show options bottom sheet
      _showNotFoundSheet(code);
    }
  }

  void _showNotFoundSheet(String code) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  ctx,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: AppTheme.warningColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Asset Not Found',
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No asset matches the scanned code:',
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                code,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _scannerController.stop();
                  // Navigate to form with serial number pre-filled
                  context.go('/assets/new', extra: {'serial_number': code});
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Register New Asset'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _isProcessing = false;
                    _lastScannedCode = null;
                  });
                },
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Scan Again'),
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _lastScannedCode = null;
        });
      }
    });
  }

  void _toggleTorch() {
    _scannerController.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  void _switchCamera() {
    _scannerController.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Scan Asset',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _torchOn ? Colors.amber : Colors.white,
            ),
            onPressed: _toggleTorch,
            tooltip: 'Toggle flashlight',
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
            onPressed: _switchCamera,
            tooltip: 'Switch camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera feed
          MobileScanner(controller: _scannerController, onDetect: _onDetect),

          // Dark overlay with transparent scan area
          _buildScanOverlay(),

          // Bottom instructions
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomPanel()),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Looking up asset...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanAreaSize = constraints.maxWidth * 0.72;
        final left = (constraints.maxWidth - scanAreaSize) / 2;
        final top = (constraints.maxHeight - scanAreaSize) / 2 - 40;

        return Stack(
          children: [
            // Dark overlay
            ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.black54,
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    child: Container(
                      width: scanAreaSize,
                      height: scanAreaSize,
                      decoration: BoxDecoration(
                        color: Colors.red, // Any color works with srcOut
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Corner brackets
            Positioned(
              left: left,
              top: top,
              child: _buildCornerBrackets(scanAreaSize),
            ),

            // Animated scan line
            AnimatedBuilder(
              animation: _scanLineAnimation,
              builder: (context, child) {
                return Positioned(
                  left: left + 16,
                  top:
                      top +
                      16 +
                      (_scanLineAnimation.value * (scanAreaSize - 32)),
                  child: Container(
                    width: scanAreaSize - 32,
                    height: 2.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.secondaryColor.withValues(alpha: 0.0),
                          AppTheme.secondaryColor.withValues(alpha: 0.8),
                          AppTheme.accentColor,
                          AppTheme.secondaryColor.withValues(alpha: 0.8),
                          AppTheme.secondaryColor.withValues(alpha: 0.0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCornerBrackets(double size) {
    const bracketLength = 28.0;
    const bracketWidth = 3.5;
    const color = Colors.white;
    const radius = 20.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Top-left
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: bracketLength,
              height: bracketWidth,
              decoration: const BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(radius),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: bracketWidth,
              height: bracketLength,
              decoration: const BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(radius),
                ),
              ),
            ),
          ),

          // Top-right
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: bracketLength,
              height: bracketWidth,
              decoration: const BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(radius),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: bracketWidth,
              height: bracketLength,
              decoration: const BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(radius),
                ),
              ),
            ),
          ),

          // Bottom-left
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: bracketLength,
              height: bracketWidth,
              decoration: const BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(radius),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: bracketWidth,
              height: bracketLength,
              decoration: const BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(radius),
                ),
              ),
            ),
          ),

          // Bottom-right
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: bracketLength,
              height: bracketWidth,
              decoration: const BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(radius),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: bracketWidth,
              height: bracketLength,
              decoration: const BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(radius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
            Colors.black.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Point camera at QR code or barcode',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Scanned assets will be looked up automatically.\n'
            'If not found, you can register a new asset.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
