import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String?> saveExcelBytes(List<int> bytes, String fileName) async {
  final storageStatus = await Permission.storage.request();

  Directory targetDirectory;
  if (Platform.isAndroid && storageStatus.isGranted) {
    final externalDirectory = await getExternalStorageDirectory();
    if (externalDirectory != null) {
      final documentsDirectory = Directory(
        '${externalDirectory.path}${Platform.pathSeparator}Documents',
      );
      if (!await documentsDirectory.exists()) {
        await documentsDirectory.create(recursive: true);
      }
      targetDirectory = documentsDirectory;
    } else {
      targetDirectory = await getApplicationDocumentsDirectory();
    }
  } else {
    targetDirectory = await getApplicationDocumentsDirectory();
  }

  final file = File(
    '${targetDirectory.path}${Platform.pathSeparator}$fileName',
  );
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
