import 'package:get/get.dart';
import 'home_controller.dart';
import '../../services/groq_llm_service.dart';
import '../../services/speech_service.dart';
import '../../services/polly_tts_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GroqLLMService>(() => GroqLLMService());
    Get.lazyPut<SpeechService>(() => SpeechService());
    Get.lazyPut<PollyTTSService>(() => PollyTTSService());
    Get.lazyPut<HomeController>(() => HomeController());
  }
}

