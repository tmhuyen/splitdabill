// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;

Future<String?> saveExcelBytes(List<int> bytes, String fileName) async {
  final base64Data = base64Encode(bytes);
  final dataUrl =
      'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$base64Data';

  final anchor = html.AnchorElement(href: dataUrl)
    ..setAttribute('download', fileName)
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();

  return fileName;
}
