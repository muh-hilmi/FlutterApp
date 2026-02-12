import 'package:logger/logger.dart';

// Minimal logger with [I], [D], [E] style
final logger = Logger(
  printer: SimplePrinter(
    colors: false,
    printTime: false,
  ),
);

final loggerNoStack = Logger(
  printer: SimplePrinter(
    colors: false,
    printTime: false,
  ),
);
