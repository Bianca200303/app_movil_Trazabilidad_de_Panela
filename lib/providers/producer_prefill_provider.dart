import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProducerPreFill {
  final String dni;
  final String firstName;
  final String lastName;

  const ProducerPreFill({
    required this.dni,
    required this.firstName,
    required this.lastName,
  });
}

final producerPreFillProvider = StateProvider<ProducerPreFill?>((ref) => null);
