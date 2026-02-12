import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../repositories/event_repository.dart';

class UploadImage {
  final EventRepository repository;

  UploadImage(this.repository);

  Future<Either<Failure, String>> call(File file) {
    return repository.uploadImage(file);
  }
}
