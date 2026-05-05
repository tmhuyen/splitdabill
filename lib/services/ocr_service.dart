import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OCRService {
  final TextRecognizer? _textRecognizer =
      kIsWeb ? null : TextRecognizer(script: TextRecognitionScript.latin);
  final _imagePicker = ImagePicker();

  /// Pick image and extract text
  Future<String> extractTextFromImage() async {
    try {
      if (kIsWeb || _textRecognizer == null) {
        return '';
      }

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile == null) return '';

      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      return recognizedText.text;
    } catch (e) {
      return '';
    }
  }

  /// Extract likely final payable amount from receipt text.
  /// Prioritizes lines containing TOTAL / AMOUNT DUE / GRAND TOTAL.
  static double? extractAmount(String text, {String? currencyCode}) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) return null;

    final candidates = <_AmountCandidate>[];
    for (final line in lines) {
      final amount = _extractBestNumberFromLine(line);
      if (amount == null || amount <= 0) continue;

      final score = _scoreLine(line, amount, currencyCode: currencyCode);
      candidates.add(_AmountCandidate(amount: amount, score: score));
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.first.amount;
  }

  static int _scoreLine(String line, double amount, {String? currencyCode}) {
    final lower = line.toLowerCase();
    var score = 0;

    if (lower.contains('grand total')) score += 120;
    if (lower.contains('amount due')) score += 110;
    if (lower.contains('total due')) score += 110;
    if (lower.contains('total')) score += 90;
    if (lower.contains('balance due')) score += 100;

    if (lower.contains('subtotal')) score -= 45;
    if (lower.contains('tax')) score -= 30;
    if (lower.contains('discount')) score -= 35;
    if (lower.contains('change')) score -= 70;
    if (lower.contains('cash')) score -= 20;
    if (lower.contains('tip')) score -= 20;

    if (_containsCurrencyHint(line, currencyCode)) score += 12;

    // Favor plausible totals.
    if (amount >= 1 && amount <= 100000) score += 8;
    if (amount >= 5) score += 5;

    return score;
  }

  static bool _containsCurrencyHint(String line, String? currencyCode) {
    if (currencyCode == null || currencyCode.isEmpty) return false;
    final lower = line.toLowerCase();
    final code = currencyCode.toLowerCase();
    if (lower.contains(code)) return true;

    switch (currencyCode.toUpperCase()) {
      case 'USD':
      case 'SGD':
      case 'CAD':
      case 'AUD':
        return line.contains(r'$');
      case 'EUR':
        return lower.contains('eur');
      case 'GBP':
        return lower.contains('gbp');
      case 'JPY':
        return lower.contains('jpy');
      case 'INR':
        return lower.contains('inr');
      case 'IDR':
        return lower.contains('idr') || lower.contains('rp');
      case 'MYR':
        return lower.contains('myr') || lower.contains('rm');
      default:
        return false;
    }
  }

  static double? _extractBestNumberFromLine(String line) {
    final matches = RegExp(r'([0-9][0-9.,]*)').allMatches(line);
    if (matches.isEmpty) return null;

    double? best;
    for (final match in matches) {
      final raw = match.group(1);
      if (raw == null || raw.isEmpty) continue;
      final value = _parseFlexibleNumber(raw);
      if (value == null) continue;
      if (best == null || value > best) {
        best = value;
      }
    }
    return best;
  }

  static double? _parseFlexibleNumber(String value) {
    var input = value.trim();
    if (input.isEmpty) return null;

    input = input.replaceAll(RegExp(r'[^0-9,\.]'), '');
    if (input.isEmpty) return null;

    final lastComma = input.lastIndexOf(',');
    final lastDot = input.lastIndexOf('.');

    if (lastComma >= 0 && lastDot >= 0) {
      // Use the last separator as decimal mark.
      if (lastComma > lastDot) {
        input = input.replaceAll('.', '');
        input = input.replaceAll(',', '.');
      } else {
        input = input.replaceAll(',', '');
      }
    } else if (lastComma >= 0) {
      // If single comma and 1-2 digits after it, treat as decimal.
      final tail = input.length - lastComma - 1;
      if (tail == 1 || tail == 2) {
        input = input.replaceAll(',', '.');
      } else {
        input = input.replaceAll(',', '');
      }
    } else if (lastDot >= 0) {
      // Keep dot as decimal if plausible, otherwise remove as thousand sep.
      final tail = input.length - lastDot - 1;
      if (tail != 1 && tail != 2) {
        input = input.replaceAll('.', '');
      }
    }

    return double.tryParse(input);
  }

  /// Extract items from receipt text
  static List<String> extractItems(String text) {
    final lines = text.split('\n');
    final items = <String>[];

    for (var line in lines) {
      line = line.trim();
      if (line.isNotEmpty && line.length > 3) {
        items.add(line);
      }
    }

    return items;
  }

  void dispose() {
    _textRecognizer?.close();
  }
}

class _AmountCandidate {
  final double amount;
  final int score;

  const _AmountCandidate({required this.amount, required this.score});
}
