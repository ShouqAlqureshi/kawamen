import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../features/Treatment/CBT_therapy/screen/CBT_therapy_page.dart';
import '../../features/Treatment/bloc/emotion_bloc.dart';
import '../../features/Treatment/deep_breathing/screen/deep_breathing_page.dart';
import '../../firebase_options.dart';
import 'Notification_service.dart';

class NotificationTestButton extends StatelessWidget {
  const NotificationTestButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () => _showEmotionPicker(context),
          child: const Text('Test Emotion Notification'),
        ),
      ],
    );
  }

  void _showEmotionPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Test Emotion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEmotionButton(context, 'Anger', 0.8),
            const SizedBox(height: 8),
            _buildEmotionButton(context, 'Sadness', 0.7),
            const SizedBox(height: 8),
            _buildEmotionButton(context, 'Fear', 0.6),
            const SizedBox(height: 8),
            _buildEmotionButton(context, 'Anxiety', 0.75),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionButton(BuildContext context, String emotion, double intensity) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          final emotionId = DateTime.now().millisecondsSinceEpoch.toString();
          NotificationService().bloc.add(
            ShowEmotionNotification(emotion, intensity, emotionId)
          );
          Navigator.of(context).pop();
        },
        child: Text(emotion),
      ),
    );
  }
}

 // Make sure you have this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService().initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kawamen Emotion App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<EmotionBloc>(
            create: (context) => EmotionBloc(),
          ),
        ],
        child: HomeScreen(),
      ),
      routes: {
        '/deep-breathing': (context) => DeepBreathingPage(),
        '/cbt-therapy': (context) => CBTTherapyPage(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late EmotionBloc _emotionBloc;

  @override
  void initState() {
    super.initState();
    _emotionBloc = BlocProvider.of<EmotionBloc>(context);
    
    // Connect notification service to emotion bloc
    NotificationService().connectToEmotionBloc(_emotionBloc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kawamen Emotion App'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Listen for navigation events from notification bloc
          TreatmentNavigator(),
          
          // Emotion state display
          BlocBuilder<EmotionBloc, EmotionState>(
            builder: (context, state) {
              if (state is EmotionProcessed) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Current Emotion: ${state.emotion}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Intensity: ${(state.intensity * 100).toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const Center(
                child: Text('No emotions detected yet'),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          // Test notification button
          const NotificationTestButton(),
        ],
      ),
    );
  }
}
