import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

/// Service untuk mengelola sistem keamanan passcode (PIN) aplikasi.
/// Fitur utama:
/// - Hashing passcode dengan SHA-256 untuk keamanan.
/// - Mekanisme penguncian (lockout) setelah beberapa kali percobaan gagal.
/// - Penyimpanan status keamanan menggunakan SharedPreferences.
class PasscodeService {
  static final PasscodeService instance = PasscodeService._internal();
  PasscodeService._internal();

  static const String _passcodeKey = 'app_passcode';
  static const String _failedAttemptsKey = 'failed_attempts';
  static const String _lockUntilKey = 'lock_until';
  static const int maxAttempts = 5;
  static const int lockDurationMinutes = 5;

  SharedPreferences? _prefs;

  /// Inisialisasi SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Hash passcode menggunakan SHA-256
  String _hashPasscode(String passcode) {
    final bytes = utf8.encode(passcode);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Cek apakah passcode sudah di-set
  bool hasPasscode() {
    return _prefs?.getString(_passcodeKey) != null;
  }

  /// Set passcode baru (harus 4 digit)
  Future<bool> setPasscode(String passcode) async {
    if (passcode.length != 4) {
      return false;
    }

    final hashed = _hashPasscode(passcode);
    await _prefs?.setString(_passcodeKey, hashed);
    await resetFailedAttempts();
    return true;
  }

  /// Verifikasi passcode
  Future<bool> verifyPasscode(String passcode) async {
    // Cek apakah sedang di-lock
    if (isLocked()) {
      return false;
    }

    final stored = _prefs?.getString(_passcodeKey);
    if (stored == null) return false;

    final hashed = _hashPasscode(passcode);
    final isCorrect = stored == hashed;

    if (isCorrect) {
      await resetFailedAttempts();
    } else {
      await incrementFailedAttempts();
    }

    return isCorrect;
  }

  /// Hapus passcode
  Future<void> removePasscode() async {
    await _prefs?.remove(_passcodeKey);
    await resetFailedAttempts();
  }

  /// Get jumlah percobaan gagal
  int getFailedAttempts() {
    return _prefs?.getInt(_failedAttemptsKey) ?? 0;
  }

  /// Increment percobaan gagal
  Future<void> incrementFailedAttempts() async {
    final current = getFailedAttempts();
    final newCount = current + 1;
    await _prefs?.setInt(_failedAttemptsKey, newCount);

    // Lock jika sudah mencapai max attempts
    if (newCount >= maxAttempts) {
      final lockUntil = DateTime.now().add(
        Duration(minutes: lockDurationMinutes),
      );
      await _prefs?.setString(_lockUntilKey, lockUntil.toIso8601String());
    }
  }

  /// Reset percobaan gagal
  Future<void> resetFailedAttempts() async {
    await _prefs?.remove(_failedAttemptsKey);
    await _prefs?.remove(_lockUntilKey);
  }

  /// Cek apakah sedang di-lock
  bool isLocked() {
    final lockUntilStr = _prefs?.getString(_lockUntilKey);
    if (lockUntilStr == null) return false;

    final lockUntil = DateTime.parse(lockUntilStr);
    final now = DateTime.now();

    if (now.isBefore(lockUntil)) {
      return true;
    } else {
      // Lock sudah expired, reset
      resetFailedAttempts();
      return false;
    }
  }

  final LocalAuthentication _auth = LocalAuthentication();

  /// Cek apakah device support biometrik & ada data enrollment
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      
      // Kita butuh keduanya: hardware support DAN user sudah register biometrik
      // Seringkali isDeviceSupported return true tapi canCheck return false jika belum ada jari terdaftar
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Eksekusi autentikasi
  Future<bool> authenticate() async {
    try {
      final available = await isBiometricAvailable();
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: 'Scan sidik jari untuk masuk',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true, // Paksa hanya biometrik, tidak boleh PIN HP
        ),
      );
    } catch (e) {
      print('Error biometrik: $e');
      return false;
    }
  }

  /// Get waku tersisa lock (dalam detik)
  int getLockRemainingSeconds() {
    final lockUntilStr = _prefs?.getString(_lockUntilKey);
    if (lockUntilStr == null) return 0;

    final lockUntil = DateTime.parse(lockUntilStr);
    final now = DateTime.now();
    final diff = lockUntil.difference(now);

    return diff.inSeconds > 0 ? diff.inSeconds : 0;
  }
}
