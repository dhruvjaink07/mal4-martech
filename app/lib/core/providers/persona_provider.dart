import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mock_persona.dart';

class PersonaNotifier extends StateNotifier<MockPersona> {
  PersonaNotifier() : super(MockPersona.defaultPersona);

  void selectPersona(MockPersona persona) {
    state = persona;
  }
}

final currentPersonaProvider = StateNotifierProvider<PersonaNotifier, MockPersona>((ref) {
  return PersonaNotifier();
});

