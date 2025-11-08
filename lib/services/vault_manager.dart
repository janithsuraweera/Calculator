import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import '../models/calculation_history.dart';
import '../models/vault_file.dart';
import '../models/vault_folder.dart';

/// Enhanced vault manager with files, folders, PIN, and biometric authentication
class VaultManager {
  static const String _vaultKey = 'secure_vault';
  static const String _vaultEnabledKey = 'vault_enabled';
  static const String _pinKey = 'vault_pin';
  static const String _useBiometricKey = 'vault_use_biometric';
  static const String _filesKey = 'vault_files';
  static const String _foldersKey = 'vault_folders';
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if vault is enabled
  static Future<bool> isVaultEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vaultEnabledKey) ?? false;
  }

  /// Enable/disable vault
  static Future<void> setVaultEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vaultEnabledKey, enabled);
  }

  /// Set PIN for vault
  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    // Hash the PIN for security
    final bytes = utf8.encode(pin);
    final hash = sha256.convert(bytes);
    await prefs.setString(_pinKey, hash.toString());
  }

  /// Check if PIN is set
  static Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey) != null;
  }

  /// Verify PIN
  static Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_pinKey);
    if (storedHash == null) return false;

    final bytes = utf8.encode(pin);
    final hash = sha256.convert(bytes);
    return hash.toString() == storedHash;
  }

  /// Set biometric preference
  static Future<void> setUseBiometric(bool use) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useBiometricKey, use);
  }

  /// Check if biometric is enabled
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useBiometricKey) ?? false;
  }

  /// Check if device supports biometric authentication
  static Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate user (PIN or biometric)
  static Future<bool> authenticate({String? pin}) async {
    try {
      final useBiometric = await isBiometricEnabled();
      final biometricAvailable = await isBiometricAvailable();

      // Try biometric first if enabled and available
      if (useBiometric && biometricAvailable) {
        try {
          final authenticated = await _localAuth.authenticate(
            localizedReason: 'Authenticate to access secure vault',
            options: const AuthenticationOptions(
              biometricOnly: false,
              stickyAuth: true,
            ),
          );
          if (authenticated) return true;
        } catch (e) {
          // Biometric failed, fall back to PIN
        }
      }

      // Use PIN if provided or if biometric failed
      if (pin != null) {
        return await verifyPin(pin);
      }

      // If no PIN provided and biometric not available, return false
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get vault directory for storing files
  static Future<Directory> getVaultDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${appDir.path}/vault');
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }
    return vaultDir;
  }

  /// Save file to vault
  static Future<VaultFile?> saveFileToVault(
    File sourceFile,
    String? folderId, {
    bool isHidden = false,
  }) async {
    try {
      final vaultDir = await getVaultDirectory();
      final fileName = sourceFile.path.split('/').last;
      final fileExtension = fileName.split('.').last;
      final fileType = VaultFileTypeExtension.fromExtension(fileExtension);

      // Generate unique ID
      final fileId = DateTime.now().millisecondsSinceEpoch.toString();
      final vaultFilePath = '${vaultDir.path}/$fileId.$fileExtension';

      // Copy file to vault
      final vaultFile = await sourceFile.copy(vaultFilePath);

      final vaultFileModel = VaultFile(
        id: fileId,
        name: fileName,
        path: vaultFilePath,
        type: fileType,
        folderId: folderId,
        createdAt: DateTime.now(),
        size: await vaultFile.length(),
        isHidden: isHidden,
      );

      // Save file metadata
      await _saveFileMetadata(vaultFileModel);

      return vaultFileModel;
    } catch (e) {
      return null;
    }
  }

  /// Save file metadata
  static Future<void> _saveFileMetadata(VaultFile file) async {
    final prefs = await SharedPreferences.getInstance();
    final filesJson = prefs.getString(_filesKey);
    List<VaultFile> files = [];

    if (filesJson != null && filesJson.isNotEmpty) {
      final List<dynamic> jsonList = jsonDecode(filesJson);
      files = jsonList
          .map((json) => VaultFile.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    files.add(file);
    final jsonList = files.map((f) => f.toJson()).toList();
    await prefs.setString(_filesKey, jsonEncode(jsonList));
  }

  /// Get all files in vault
  static Future<List<VaultFile>> getVaultFiles({
    String? folderId,
    VaultFileType? type,
    bool includeHidden = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filesJson = prefs.getString(_filesKey);

      if (filesJson == null || filesJson.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(filesJson);
      List<VaultFile> files = jsonList
          .map((json) => VaultFile.fromJson(json as Map<String, dynamic>))
          .toList();

      // Filter by folder
      if (folderId != null) {
        files = files.where((f) => f.folderId == folderId).toList();
      }

      // Filter by type
      if (type != null) {
        files = files.where((f) => f.type == type).toList();
      }

      // Filter hidden files
      if (!includeHidden) {
        files = files.where((f) => !f.isHidden).toList();
      }

      return files;
    } catch (e) {
      return [];
    }
  }

  /// Delete file from vault
  static Future<bool> deleteFile(String fileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filesJson = prefs.getString(_filesKey);

      if (filesJson == null || filesJson.isEmpty) {
        return false;
      }

      final List<dynamic> jsonList = jsonDecode(filesJson);
      List<VaultFile> files = jsonList
          .map((json) => VaultFile.fromJson(json as Map<String, dynamic>))
          .toList();

      final file = files.firstWhere((f) => f.id == fileId);

      // Delete physical file
      final filePath = File(file.path);
      if (await filePath.exists()) {
        await filePath.delete();
      }

      // Remove from metadata
      files.removeWhere((f) => f.id == fileId);
      final jsonList2 = files.map((f) => f.toJson()).toList();
      await prefs.setString(_filesKey, jsonEncode(jsonList2));

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Create folder
  static Future<VaultFolder?> createFolder(
    String name, {
    String? parentFolderId,
    bool isHidden = false,
  }) async {
    try {
      final folderId = DateTime.now().millisecondsSinceEpoch.toString();
      final folder = VaultFolder(
        id: folderId,
        name: name,
        parentFolderId: parentFolderId,
        createdAt: DateTime.now(),
        isHidden: isHidden,
      );

      await _saveFolderMetadata(folder);
      return folder;
    } catch (e) {
      return null;
    }
  }

  /// Save folder metadata
  static Future<void> _saveFolderMetadata(VaultFolder folder) async {
    final prefs = await SharedPreferences.getInstance();
    final foldersJson = prefs.getString(_foldersKey);
    List<VaultFolder> folders = [];

    if (foldersJson != null && foldersJson.isNotEmpty) {
      final List<dynamic> jsonList = jsonDecode(foldersJson);
      folders = jsonList
          .map((json) => VaultFolder.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    folders.add(folder);
    final jsonList = folders.map((f) => f.toJson()).toList();
    await prefs.setString(_foldersKey, jsonEncode(jsonList));
  }

  /// Get all folders
  static Future<List<VaultFolder>> getVaultFolders({
    String? parentFolderId,
    bool includeHidden = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final foldersJson = prefs.getString(_foldersKey);

      if (foldersJson == null || foldersJson.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(foldersJson);
      List<VaultFolder> folders = jsonList
          .map((json) => VaultFolder.fromJson(json as Map<String, dynamic>))
          .toList();

      // Filter by parent folder
      if (parentFolderId != null) {
        folders = folders
            .where((f) => f.parentFolderId == parentFolderId)
            .toList();
      } else {
        // Get root folders (no parent)
        folders = folders.where((f) => f.parentFolderId == null).toList();
      }

      // Filter hidden folders
      if (!includeHidden) {
        folders = folders.where((f) => !f.isHidden).toList();
      }

      return folders;
    } catch (e) {
      return [];
    }
  }

  /// Delete folder
  static Future<bool> deleteFolder(String folderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final foldersJson = prefs.getString(_foldersKey);

      if (foldersJson == null || foldersJson.isEmpty) {
        return false;
      }

      final List<dynamic> jsonList = jsonDecode(foldersJson);
      List<VaultFolder> folders = jsonList
          .map((json) => VaultFolder.fromJson(json as Map<String, dynamic>))
          .toList();

      // Check if folder has files
      final files = await getVaultFiles(folderId: folderId);
      if (files.isNotEmpty) {
        return false; // Cannot delete folder with files
      }

      // Check if folder has subfolders
      final subfolders = await getVaultFolders(parentFolderId: folderId);
      if (subfolders.isNotEmpty) {
        return false; // Cannot delete folder with subfolders
      }

      // Remove folder
      folders.removeWhere((f) => f.id == folderId);
      final jsonList2 = folders.map((f) => f.toJson()).toList();
      await prefs.setString(_foldersKey, jsonEncode(jsonList2));

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Toggle file visibility
  static Future<bool> toggleFileVisibility(String fileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filesJson = prefs.getString(_filesKey);

      if (filesJson == null || filesJson.isEmpty) {
        return false;
      }

      final List<dynamic> jsonList = jsonDecode(filesJson);
      List<VaultFile> files = jsonList
          .map((json) => VaultFile.fromJson(json as Map<String, dynamic>))
          .toList();

      final index = files.indexWhere((f) => f.id == fileId);
      if (index == -1) return false;

      files[index] = files[index].copyWith(isHidden: !files[index].isHidden);
      final jsonList2 = files.map((f) => f.toJson()).toList();
      await prefs.setString(_filesKey, jsonEncode(jsonList2));

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Toggle folder visibility
  static Future<bool> toggleFolderVisibility(String folderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final foldersJson = prefs.getString(_foldersKey);

      if (foldersJson == null || foldersJson.isEmpty) {
        return false;
      }

      final List<dynamic> jsonList = jsonDecode(foldersJson);
      List<VaultFolder> folders = jsonList
          .map((json) => VaultFolder.fromJson(json as Map<String, dynamic>))
          .toList();

      final index = folders.indexWhere((f) => f.id == folderId);
      if (index == -1) return false;

      folders[index] = folders[index].copyWith(
        isHidden: !folders[index].isHidden,
      );
      final jsonList2 = folders.map((f) => f.toJson()).toList();
      await prefs.setString(_foldersKey, jsonEncode(jsonList2));

      return true;
    } catch (e) {
      return false;
    }
  }

  // Legacy methods for calculation history (backward compatibility)
  /// Save calculation to vault
  static Future<void> saveToVault(String expression, String result) async {
    final authenticated = await authenticate();
    if (!authenticated) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final vaultJson = prefs.getString(_vaultKey);
      List<CalculationHistory> vaultList = [];

      if (vaultJson != null && vaultJson.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(vaultJson);
        vaultList = jsonList
            .map(
              (json) =>
                  CalculationHistory.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }

      final newEntry = CalculationHistory(
        expression: expression,
        result: result,
        timestamp: DateTime.now(),
      );

      vaultList.insert(0, newEntry);

      // Limit vault size
      if (vaultList.length > 50) {
        vaultList.removeRange(50, vaultList.length);
      }

      final jsonList = vaultList.map((e) => e.toJson()).toList();
      await prefs.setString(_vaultKey, jsonEncode(jsonList));
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get vault entries (requires authentication)
  static Future<List<CalculationHistory>> getVaultEntries() async {
    final authenticated = await authenticate();
    if (!authenticated) return [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final vaultJson = prefs.getString(_vaultKey);

      if (vaultJson == null || vaultJson.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(vaultJson);
      return jsonList
          .map(
            (json) => CalculationHistory.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear vault
  static Future<void> clearVault() async {
    final authenticated = await authenticate();
    if (!authenticated) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_vaultKey);
      await prefs.remove(_filesKey);
      await prefs.remove(_foldersKey);

      // Clear vault directory
      final vaultDir = await getVaultDirectory();
      if (await vaultDir.exists()) {
        await vaultDir.delete(recursive: true);
      }
    } catch (e) {
      // Handle error silently
    }
  }
}
