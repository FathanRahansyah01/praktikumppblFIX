import 'dart:async';
import 'package:flutter/material.dart';
import '../services/passcode_service.dart';

/// Screen untuk memasukkan passcode saat membuka app
class PasscodeLockScreen extends StatefulWidget {
  const PasscodeLockScreen({super.key});

  @override
  State<PasscodeLockScreen> createState() => _PasscodeLockScreenState();
}

class _PasscodeLockScreenState extends State<PasscodeLockScreen> {
  final _passcodeService = PasscodeService.instance;
  String _passcode = '';
  String _errorMessage = '';
  bool _isLocked = false;
  int _lockSeconds = 0;
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
    // Beri sedikit delay agar UI render dulu
    Future.delayed(const Duration(milliseconds: 500), _tryBiometricAuth);
  }

  Future<void> _tryBiometricAuth() async {
    if (_isLocked) return;
    
    // Cek dulu availability
    final available = await _passcodeService.isBiometricAvailable();
    if (!available) return;

    final authenticated = await _passcodeService.authenticate();
    
    if (authenticated && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }

  void _checkLockStatus() {
    if (_passcodeService.isLocked()) {
      setState(() {
        _isLocked = true;
        _lockSeconds = _passcodeService.getLockRemainingSeconds();
      });
      _startLockTimer();
    }
  }

  void _startLockTimer() {
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _lockSeconds = _passcodeService.getLockRemainingSeconds();
        
        if (_lockSeconds <= 0) {
          _isLocked = false;
          timer.cancel();
          _passcode = '';
          _errorMessage = '';
        }
      });
    });
  }

  void _onNumberPressed(String number) {
    if (_isLocked) return;

    setState(() {
      _errorMessage = '';
      
      if (_passcode.length < 4) {
        _passcode += number;
        
        // Auto-verify jika sudah 4 digit
        if (_passcode.length == 4) {
          _verifyPasscode();
        }
      }
    });
  }

  void _onDeletePressed() {
    if (_isLocked) return;

    setState(() {
      _errorMessage = '';
      if (_passcode.isNotEmpty) {
        _passcode = _passcode.substring(0, _passcode.length - 1);
      }
    });
  }

  Future<void> _verifyPasscode() async {
    final isCorrect = await _passcodeService.verifyPasscode(_passcode);
    
    if (isCorrect && mounted) {
      Navigator.of(context).pop(true);
    } else {
      final attempts = _passcodeService.getFailedAttempts();
      final remaining = PasscodeService.maxAttempts - attempts;
      
      setState(() {
        _passcode = '';
        
        if (_passcodeService.isLocked()) {
          _isLocked = true;
          _lockSeconds = _passcodeService.getLockRemainingSeconds();
          _errorMessage = '';
          _startLockTimer();
        } else if (remaining > 0) {
          _errorMessage = 'PIN salah. $remaining percobaan tersisa.';
        }
      });
    }
  }

  Future<void> _showResetDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset PIN?'),
        content: const Text(
          'Mereset PIN akan menghapus semua data aplikasi. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _passcodeService.removePasscode();
      Navigator.of(context).pop(false); // Return false to trigger setup
    }
  }

  String _formatLockTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[700],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(
                _isLocked ? Icons.lock_clock : Icons.lock_outline,
                size: 80,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                _isLocked ? 'Aplikasi Terkunci' : 'Masukkan PIN',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                _isLocked
                    ? 'Terlalu banyak percobaan gagal'
                    : 'Masukkan PIN untuk membuka aplikasi',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Lock Timer or PIN Dots
              if (_isLocked)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Coba lagi dalam:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatLockTime(_lockSeconds),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) => _buildPinDot(index < _passcode.length),
                  ),
                ),
              
              const SizedBox(height: 16),

              // Error Message
              if (_errorMessage.isNotEmpty && !_isLocked)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 40),

              // Numeric Keypad
              if (!_isLocked) _buildNumericKeypad(),

              const SizedBox(height: 20),

              // Forgot PIN button
              TextButton(
                onPressed: _showResetDialog,
                child: Text(
                  'Lupa PIN?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinDot(bool filled) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? Colors.white : Colors.transparent,
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        const SizedBox(height: 16),
        _buildKeypadRow(['4', '5', '6']),
        const SizedBox(height: 16),
        _buildKeypadRow(['7', '8', '9']),
        const SizedBox(height: 16),
        _buildKeypadRow(['fps', '0', 'del']),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((num) {
        if (num.isEmpty) {
          return const SizedBox(width: 70, height: 70);
        }
        
        if (num == 'del') {
          return _buildKeypadButton(
            child: const Icon(Icons.backspace_outlined, color: Colors.white),
            onPressed: _onDeletePressed,
          );
        }

        if (num == 'fps') {
           return _buildKeypadButton(
            child: const Icon(Icons.fingerprint, color: Colors.white, size: 32),
            onPressed: _tryBiometricAuth,
          );
        }

        return _buildKeypadButton(
          child: Text(
            num,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          onPressed: () => _onNumberPressed(num),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton({
    required Widget child,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}
