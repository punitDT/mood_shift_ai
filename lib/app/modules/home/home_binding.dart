import 'package:get/get.dart';
import 'home_controller.dart';
import '../../services/ai_service.dart';
import '../../services/speech_service.dart';
import '../../services/tts_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AIService>(() => AIService());
    Get.lazyPut<SpeechService>(() => SpeechService());
    Get.lazyPut<TTSService>(() => TTSService());
    Get.lazyPut<HomeController>(() => HomeController());
  }
}

