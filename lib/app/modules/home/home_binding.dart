import 'package:get/get.dart';
import 'home_controller.dart';
import '../../services/groq_llm_service.dart';
import '../../services/speech_service.dart';
import '../../services/polly_tts_service.dart';
import '../../controllers/rewarded_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GroqLLMService>(() => GroqLLMService());
    Get.lazyPut<SpeechService>(() => SpeechService());
    Get.lazyPut<PollyTTSService>(() => PollyTTSService());
    Get.lazyPut<RewardedController>(() => RewardedController());
    Get.lazyPut<HomeController>(() => HomeController());
  }
}

