import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/recipe.dart';
import '../theme.dart';
import 'reviews_screen.dart';
import 'edit_recipe_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _isSaved = false;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;
  bool _isYoutube = false;
  bool _isPlaying = false;
  bool _hasError = false;

  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  int _currentStepIndex = -1;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastWords = '';

  Timer? _activeTimer;
  int _remainingSeconds = 0;

  int _servings = 1;

  List<String> _aiInstructions = [];
  bool _isAILoading = false;
  StateSetter? _modalSetState;

  final String _groqApiKey = dotenv.env['GROQ_API_KEY'] ?? "";
  final String _groqApiUrl = "https://api.groq.com/openai/v1/chat/completions";

  final ScrollController _modalScrollController = ScrollController();
  final List<GlobalKey> _stepKeys = [];

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
    if (widget.recipe.videoUrl.contains('youtube.com') || widget.recipe.videoUrl.contains('youtu.be')) {
      _isYoutube = true;
    }
    _initTts();
    _initSpeech();
  }

  void _initTts() {
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
      _modalSetState?.call(() {});
      if (_currentStepIndex != -1) {
         _startListeningForCommands();
      }
    });
  }

  Future<void> _initSpeech() async {
    try {
      await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
            _modalSetState?.call(() {});
          }
        },
        onError: (error) => debugPrint('Speech error: $error'),
      );
    } catch (e) {
      debugPrint('Speech init error: $e');
    }
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    await _stopListening();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
    if (mounted) setState(() => _isSpeaking = true);
    _modalSetState?.call(() {});
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    if (mounted) setState(() => _isSpeaking = false);
    _modalSetState?.call(() {});
  }

  Future<void> _startListeningForCommands() async {
    if (_isSpeaking) return;
    
    var status = await Permission.microphone.status;
    if (status.isDenied) { await Permission.microphone.request(); }
    
    if (!_isListening && _speech.isAvailable) {
      if (mounted) setState(() => _isListening = true);
      _modalSetState?.call(() {});
      
      _speech.listen(
        onResult: (val) {
          if (val.finalResult) {
            _lastWords = val.recognizedWords.toLowerCase();
            debugPrint('Voice Command: $_lastWords');
            _handleVoiceCommand(_lastWords);
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(partialResults: false),
      );
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) setState(() => _isListening = false);
    _modalSetState?.call(() {});
  }

  void _handleVoiceCommand(String command) {
    if (command.contains("next") || command.contains("continue")) {
      _goToNextStep();
    } else if (command.contains("previous") || command.contains("back")) {
      _goToPreviousStep();
    } else if (command.contains("repeat") || command.contains("again")) {
      if (_currentStepIndex != -1) { _speak(_aiInstructions[_currentStepIndex]); }
    } else if (command.contains("stop") || command.contains("cancel")) {
      _stopSpeaking(); _stopListening();
    }
  }

  void _goToNextStep() {
    if (_currentStepIndex < _aiInstructions.length - 1) {
      if (mounted) setState(() { _currentStepIndex++; });
      _modalSetState?.call(() {});
      _speak(_aiInstructions[_currentStepIndex]);
      _scrollToCurrentStep();
    }
  }

  void _goToPreviousStep() {
    if (_currentStepIndex > 0) {
      if (mounted) setState(() { _currentStepIndex--; });
      _modalSetState?.call(() {});
      _speak(_aiInstructions[_currentStepIndex]);
      _scrollToCurrentStep();
    }
  }

  void _scrollToCurrentStep() {
    if (_currentStepIndex >= 0 && _currentStepIndex < _stepKeys.length) {
      final context = _stepKeys[_currentStepIndex].currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.3,
        );
      }
    }
  }

  int? _extractMinutes(String text) {
    final regExp = RegExp(r'(\d+)\s*(minutes|minute|mins|min)', caseSensitive: false);
    final match = regExp.firstMatch(text);
    if (match != null) { return int.tryParse(match.group(1)!); }
    return null;
  }

  void _startStepTimer(int minutes, int stepIndex, StateSetter setModalState) {
    _activeTimer?.cancel();
    _remainingSeconds = minutes * 60;
    _activeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) setState(() => _remainingSeconds--);
        setModalState(() {});
      } else {
        _activeTimer?.cancel();
        _speak("Timer finished for step ${stepIndex + 1}");
        setModalState(() {});
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _scaleIngredient(String ingredient) {
    if (_servings == 1) return ingredient;
    final RegExp numRegExp = RegExp(r'^(\d+\.?\d*)\s*');
    final match = numRegExp.firstMatch(ingredient);
    if (match != null) {
      double originalValue = double.parse(match.group(1)!);
      double scaledValue = originalValue * _servings;
      String displayValue = scaledValue % 1 == 0 ? scaledValue.toInt().toString() : scaledValue.toStringAsFixed(1);
      return ingredient.replaceFirst(match.group(1)!, displayValue);
    }
    return ingredient;
  }

  Future<void> _fetchAISteps() async {
    if (mounted) setState(() => _isAILoading = true);
    try {
      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: { "Authorization": "Bearer $_groqApiKey", "Content-Type": "application/json", },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            { "role": "system", "content": "You are a professional chef. Given a recipe title and ingredients, generate a clear, step-by-step cooking guide. Output ONLY the steps as a JSON list of strings under the key 'steps'." },
            { "role": "user", "content": "Title: ${widget.recipe.title}\nIngredients: ${widget.recipe.ingredients.join(', ')}" }
          ],
          "response_format": {"type": "json_object"}
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = jsonDecode(data['choices'][0]['message']['content']);
        final List<dynamic> steps = content['steps'] ?? content.values.firstWhere((e) => e is List);
        _aiInstructions = steps.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
      } else { throw Exception("Failed to load AI steps: ${response.statusCode}"); }
    } catch (e) {
      debugPrint("AI Error: $e");
      _aiInstructions = widget.recipe.description.split('.').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    } finally {
      if (mounted) setState(() {
        _isAILoading = false;
        _stepKeys.clear();
        for (int i = 0; i < _aiInstructions.length; i++) { _stepKeys.add(GlobalKey()); }
      });
    }
  }

  void _showInventoryAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cooking Done? 🍳'),
        content: const Text('Do you want to update your inventory and log your nutrition for today?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _handleFinishCooking(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, minimumSize: const Size(120, 44)),
            child: const Text('Update & Log'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFinishCooking() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).collection('cooked_history').add({
      'title': widget.recipe.title, 'calories': widget.recipe.calories, 'protein': widget.recipe.protein, 'carbs': widget.recipe.carbs, 'servings': _servings, 'timestamp': FieldValue.serverTimestamp(),
    });
    for (var rawIng in widget.recipe.ingredients) {
      String cleanIng = rawIng.toLowerCase();
      List<String> keywords = [
        'milk',
        'egg',
        'onion',
        'tomato',
        'meat',
        'garlic',
        'sugar',
        'flour',
        'salt'
      ];
      String? foundItem;
      for (var kw in keywords) {
        if (cleanIng.contains(kw)) {
          foundItem = kw;
          break;
        }
      }
      if (foundItem != null) {
        final pantryDocs = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('pantry')
            .where('name', isGreaterThanOrEqualTo: foundItem)
            .where('name', isLessThanOrEqualTo: '$foundItem\uf8ff')
            .get();
        if (pantryDocs.docs.isNotEmpty) {
          for (var doc in pantryDocs.docs) {
            await doc.reference.delete();
          }
        }
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('shopping_list')
            .add({
          'name': foundItem,
          'isBought': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Nutrition logged and pantry updated!'),
        backgroundColor: Colors.green));
  }

  void _startCookingMode() async {
    if (_aiInstructions.isEmpty) {
      await _fetchAISteps();
    }
    
    if (_aiInstructions.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to generate steps. Please try again.")));
       return;
    }

    if (mounted) setState(() { _currentStepIndex = 0; });
    _speak(_aiInstructions[_currentStepIndex]);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            _modalSetState = setModalState;
            double progress = _aiInstructions.isEmpty ? 0 : (_currentStepIndex + 1) / _aiInstructions.length;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('AI Cooking Assistant', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                                Text('Say "Next Step" to continue', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: _isListening ? Colors.redAccent.withValues(alpha: 0.1) : Colors.grey[100], shape: BoxShape.circle),
                              child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.redAccent : Colors.grey, size: 28),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[200],
                            color: AppTheme.primaryColor,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Step ${_currentStepIndex + 1} of ${_aiInstructions.length}', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                        if (_activeTimer != null && _activeTimer!.isActive)
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer, color: Colors.redAccent, size: 18),
                                const SizedBox(width: 8),
                                Text('Timer: ${_formatDuration(_remainingSeconds)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                GestureDetector(onTap: () { _activeTimer?.cancel(); setModalState(() {}); if (mounted) setState(() {}); }, child: const Icon(Icons.cancel, color: Colors.redAccent, size: 18))
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _modalScrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      itemCount: _aiInstructions.length,
                      itemBuilder: (context, index) {
                        bool isCurrent = _currentStepIndex == index;
                        int? stepMinutes = _extractMinutes(_aiInstructions[index]);
                        return Container(
                          key: _stepKeys[index],
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isCurrent ? AppTheme.primaryColor.withValues(alpha: 0.08) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isCurrent ? AppTheme.primaryColor : Colors.grey[200]!, width: isCurrent ? 2 : 1),
                            boxShadow: isCurrent ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))] : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: isCurrent ? AppTheme.primaryColor : Colors.grey[300],
                                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      _aiInstructions[index],
                                      style: TextStyle(
                                        fontSize: 16,
                                        height: 1.5,
                                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                                        color: isCurrent ? AppTheme.textColor : Colors.black87
                                      )
                                    )
                                  ),
                                ],
                              ),
                              if (stepMinutes != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 44, top: 12),
                                  child: ElevatedButton.icon(
                                    onPressed: () => _startStepTimer(stepMinutes, index, setModalState),
                                    icon: const Icon(Icons.timer_outlined, size: 18),
                                    label: Text('Start $stepMinutes min Timer'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.secondaryColor,
                                      foregroundColor: AppTheme.primaryColor,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      minimumSize: const Size(0, 40),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                                    ),
                                  ),
                                )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _currentStepIndex > 0 ? () { _goToPreviousStep(); } : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryColor,
                              foregroundColor: AppTheme.primaryColor,
                              minimumSize: const Size(0, 56),
                              elevation: 0,
                            ),
                            child: const Text('Previous'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                               if (_currentStepIndex < _aiInstructions.length - 1) { 
                                 _goToNextStep(); 
                               } else { 
                                 Navigator.pop(context); 
                                 _showInventoryAlert(); 
                               }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 56),
                              elevation: 2,
                            ),
                            child: Text(_currentStepIndex < _aiInstructions.length - 1 ? 'Next Step' : 'Finish Cooking'),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _modalSetState = null;
      _stopSpeaking();
      _stopListening();
      if (mounted) setState(() { _currentStepIndex = -1; });
    });
  }

  Future<void> _startVideo() async {
    final videoUrl = widget.recipe.videoUrl.trim();
    if (videoUrl.isEmpty) return;
    if (mounted) setState(() { _isPlaying = true; _hasError = false; });
    try {
      if (_isYoutube) {
        final videoId = YoutubePlayer.convertUrlToId(videoUrl);
        if (videoId != null) { _youtubeController = YoutubePlayerController(initialVideoId: videoId, flags: const YoutubePlayerFlags(autoPlay: true, mute: false, useHybridComposition: true)); }
      } else {
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        await _videoPlayerController!.initialize();
        _chewieController = ChewieController(videoPlayerController: _videoPlayerController!, autoPlay: true, looping: false, aspectRatio: _videoPlayerController!.value.aspectRatio);
      }
      if (mounted) setState(() {});
    } catch (e) { if (mounted) setState(() => _hasError = true); }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose(); _chewieController?.dispose(); _youtubeController?.dispose();
    _activeTimer?.cancel(); _flutterTts.stop(); _speech.stop(); _modalScrollController.dispose();
    super.dispose();
  }

  Future<void> _checkIfSaved() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('saved_recipes').doc(user.uid).get();
      if (doc.exists) {
        final savedIds = List<String>.from(doc.data()?['recipeIds'] ?? []);
        if (mounted) setState(() => _isSaved = savedIds.contains(widget.recipe.title));
      }
    }
  }

  Future<void> _toggleLike(bool currentlyLiked) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final likeRef = _firestore.collection('recipes').doc(widget.recipe.id).collection('likes').doc(user.uid);
    final recipeDoc = await _firestore.collection('recipes').doc(widget.recipe.id).get();
    final chefId = recipeDoc.data()?['userId'];
    if (currentlyLiked) {
      await likeRef.delete();
      if (chefId != null) { await _firestore.collection('users').doc(chefId).update({'totalRecipeLikes': FieldValue.increment(-1)}); }
    } else {
      await likeRef.set({'timestamp': FieldValue.serverTimestamp()});
      if (chefId != null) { await _firestore.collection('users').doc(chefId).update({'totalRecipeLikes': FieldValue.increment(1)}); }
    }
  }

  Future<void> _toggleSaveRecipe() async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (mounted) setState(() => _isSaved = !_isSaved);
    final docRef = _firestore.collection('saved_recipes').doc(user.uid);
    if (_isSaved) {
      await docRef.set({'userId': user.uid, 'recipeIds': FieldValue.arrayUnion([widget.recipe.title])}, SetOptions(merge: true));
    } else {
      await docRef.update({'recipeIds': FieldValue.arrayRemove([widget.recipe.title])});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final bool isOwner = user?.email == widget.recipe.authorEmail;
    Widget mainContent = _isPlaying ? _buildMediaHeader() : _buildPreviewStack();
    if (_isYoutube && _isPlaying && _youtubeController != null) { mainContent = YoutubePlayerBuilder(player: YoutubePlayer(controller: _youtubeController!), builder: (context, player) => player); }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isAILoading ? null : _startCookingMode,
        backgroundColor: AppTheme.primaryColor,
        icon: _isAILoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.psychology, color: Colors.white),
        label: Text(_isAILoading ? 'Preparing AI Steps...' : 'Start AI Cooking Mode', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300, pinned: true, backgroundColor: Colors.white, elevation: 0,
            leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.textColor), onPressed: () => Navigator.pop(context)),
            flexibleSpace: FlexibleSpaceBar(background: _hasError ? Container(color: Colors.black, child: const Center(child: Text("Error playing video", style: TextStyle(color: Colors.white)))) : mainContent),
            actions: [
              if (isOwner) _buildActionCircle(Icons.edit, () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditRecipeScreen(recipe: widget.recipe)))),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('recipes').doc(widget.recipe.id).collection('likes').snapshots(),
                builder: (context, snapshot) {
                  bool isLiked = snapshot.hasData && snapshot.data!.docs.any((doc) => doc.id == user?.uid);
                  return _buildActionCircle(isLiked ? Icons.favorite : Icons.favorite_border, () => _toggleLike(isLiked), color: isLiked ? Colors.red : AppTheme.textColor);
                }
              ),
              _buildActionCircle(_isSaved ? Icons.bookmark : Icons.bookmark_border, _toggleSaveRecipe, color: _isSaved ? AppTheme.primaryColor : AppTheme.textColor),
              _buildActionCircle(Icons.share_outlined, () => Share.share("Check out ${widget.recipe.title} on DishDash!")),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.recipe.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textColor)), const SizedBox(height: 4), Text('By ${widget.recipe.author}', style: const TextStyle(color: Colors.grey, fontSize: 14))])),
                      GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReviewsScreen(recipe: widget.recipe))), child: Row(children: [const Icon(Icons.star, color: Colors.orange, size: 18), const SizedBox(width: 4), Text(widget.recipe.rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const Icon(Icons.chevron_right, color: Colors.grey, size: 18)])),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildInfoItem(Icons.timer_outlined, widget.recipe.time), _buildInfoItem(Icons.local_fire_department_outlined, widget.recipe.calories), _buildInfoItem(Icons.restaurant_outlined, 'Easy')]),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ingredients', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppTheme.secondaryColor, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            IconButton(icon: const Icon(Icons.remove, size: 18, color: AppTheme.primaryColor), onPressed: _servings > 1 ? () => setState(() => _servings--) : null, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                            const SizedBox(width: 8), Text('$_servings Servings', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)), const SizedBox(width: 8),
                            IconButton(icon: const Icon(Icons.add, size: 18, color: AppTheme.primaryColor), onPressed: () => setState(() => _servings++), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...widget.recipe.ingredients.map((ing) => _buildIngredientItem(_scaleIngredient(ing))).toList(),
                  const SizedBox(height: 32),
                  const Text('Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
                  const SizedBox(height: 12),
                  Text(widget.recipe.description, style: const TextStyle(color: Colors.black87, height: 1.6, fontSize: 15)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStack() { return Stack(fit: StackFit.expand, children: [_buildRecipeImage(widget.recipe.image), if (widget.recipe.videoUrl.isNotEmpty) Center(child: GestureDetector(onTap: _startVideo, child: Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle), child: const Icon(Icons.play_arrow, color: Colors.white, size: 40))))]); }
  Widget _buildMediaHeader() { if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) { return Chewie(controller: _chewieController!); } else { return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)); } }
  Widget _buildActionCircle(IconData icon, VoidCallback onTap, {Color? color}) { return Container(margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: IconButton(icon: Icon(icon, color: color ?? AppTheme.textColor, size: 20), onPressed: onTap)); }
  
  Widget _buildRecipeImage(String imageStr) {
    if (imageStr.isEmpty) return Container(color: Colors.grey[200], child: const Icon(Icons.image));
    
    if (imageStr.startsWith('http')) {
      return Image.network(
        imageStr,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
      );
    } else if (imageStr.startsWith('data:image')) {
       try {
        final base64Str = imageStr.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
          width: double.infinity,
        );
      } catch (e) {
        return Container(color: Colors.grey[200], child: const Icon(Icons.error));
      }
    }
    return Container(color: Colors.grey[200], child: const Icon(Icons.image));
  }

  Widget _buildInfoItem(IconData icon, String label) { return Column(children: [Icon(icon, color: AppTheme.primaryColor), const SizedBox(height: 4), Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey))]); }
  Widget _buildIngredientItem(String ingredient) { return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)), child: Text(ingredient, style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textColor))); }
}
