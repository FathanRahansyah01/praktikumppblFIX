import 'package:flutter/material.dart';
import '../services/passcode_service.dart';

/// Screen untuk setup passcode pertama kali
class PasscodeSetupScreen extends StatefulWidget {
  const PasscodeSetupScreen({super.key});

  @override
  State<PasscodeSetupScreen> createState() => _PasscodeSetupScreenState();
}

class _PasscodeSetupScreenState extends State<PasscodeSetupScreen> {
  final _passcodeService = PasscodeService.instance;
  String _passcode = '';
  String _confirmPasscode = '';
  bool _isConfirming = false;
  String _errorMessage = '';

  void _onNumberPressed(String number) {
    setState(() {
      _errorMessage = '';
      
      if (!_isConfirming) {
        if (_passcode.length < 4) {
          _passcode += number;
          
          // Auto-advance ke konfirmasi jika sudah 4 digit
          if (_passcode.length == 4) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (_passcode.length == 4 && !_isConfirming) {
                setState(() => _isConfirming = true);
              }
            });
          }
        }
      } else {
        if (_confirmPasscode.length < 4) {
          _confirmPasscode += number;
          
          // Auto-verify jika sudah 4 digit
          if (_confirmPasscode.length == 4) {
            _verifyAndSave();
          }
        }
      }
    });
  }

  void _onDeletePressed() {
    setState(() {
      _errorMessage = '';
      
      if (!_isConfirming) {
        if (_passcode.isNotEmpty) {
          _passcode = _passcode.substring(0, _passcode.length - 1);
        }
      } else {
        if (_confirmPasscode.isNotEmpty) {
          _confirmPasscode = _confirmPasscode.substring(0, _confirmPasscode.length - 1);
        }
      }
    });
  }

  void _onBackPressed() {
    if (_isConfirming) {
      setState(() {
        _isConfirming = false;
        _confirmPasscode = '';
        _errorMessage = '';
      });
    }
  }

  Future<void> _verifyAndSave() async {
    if (_passcode != _confirmPasscode) {
      setState(() {
        _errorMessage = 'PIN tidak cocok. Coba lagi.';
        _confirmPasscode = '';
      });
      return;
    }

    final success = await _passcodeService.setPasscode(_passcode);
    
    if (success && mounted) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorMessage = 'Gagal menyimpan PIN. Coba lagi.';
        _passcode = '';
        _confirmPasscode = '';
        _isConfirming = false;
      });
    }
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
                Icons.lock_outline,
                size: 80,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                _isConfirming ? 'Konfirmasi PIN' : 'Buat PIN Baru',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                _isConfirming
                    ? 'Masukkan PIN sekali lagi'
                    : 'Masukkan 4 digit PIN untuk keamanan',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // PIN Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (index) => _buildPinDot(
                    index < (_isConfirming ? _confirmPasscode.length : _passcode.length),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Error Message
              if (_errorMessage.isNotEmpty)
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
              _buildNumericKeypad(),

              const SizedBox(height: 20),

              // Back button (only show when confirming)
              if (_isConfirming)
                TextButton.icon(
                  onPressed: _onBackPressed,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text(
                    'Kembali',
                    style: TextStyle(color: Colors.white),
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
        _buildKeypadRow(['', '0', 'del']),
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
