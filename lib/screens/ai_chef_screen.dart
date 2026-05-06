import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../theme.dart';

class AIChefScreen extends StatefulWidget {
  const AIChefScreen({super.key});

  @override
  State<AIChefScreen> createState() => _AIChefScreenState();
}

class _AIChefScreenState extends State<AIChefScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // APIs from .env
  final String _groqApiKey = dotenv.env['GROQ_API_KEY'] ?? "";
  final String _groqApiUrl = "https://api.groq.com/openai/v1/chat/completions";

  // Gemini API for Vision (Pantry Scanner)
  final String _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'ai',
      'text': 'Hi! I am your AI Chef. You can type your ingredients or tap the camera icon to scan your pantry!'
    });
  }

  Future<void> _scanPantry() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (image == null) return;

    setState(() {
      _isLoading = true;
      _messages.add({'role': 'user', 'text': 'Scanning my pantry... 📸'});
    });

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Using stable v1 endpoint and gemini-1.5-flash
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": "List all the food ingredients you see in this image. Only provide the list of ingredients separated by commas, nothing else."},
                {
                  "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": base64Image
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String ingredients = data['candidates'][0]['content']['parts'][0]['text']?.trim() ?? "";

        if (ingredients.isNotEmpty) {
          setState(() {
            _messages.add({'role': 'ai', 'text': 'I found: $ingredients. Generating a recipe for you...'});
          });
          _sendAIRequest(ingredients);
        } else {
          throw Exception("Could not identify any ingredients.");
        }
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint("Gemini Full Error: ${response.body}"); // Log full error for debugging
        final errorMessage = errorData['error']?['message'] ?? "Unknown Error (${response.statusCode})";
        throw Exception("Gemini API Error: $errorMessage");
      }
    } catch (e) {
      debugPrint("Scan Error: $e");
      setState(() {
        _messages.add({'role': 'ai', 'text': 'Scan Error: ${e.toString().replaceAll('Exception: ', '')}'});
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();
    _sendAIRequest(text);
  }

  Future<void> _sendAIRequest(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: {
          "Authorization": "Bearer $_groqApiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system", 
              "content": "You are an expert Chef. Provide a creative recipe name, ingredients, and instructions for ingredients provided. Keep it concise and formatted clearly."
            },
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String aiResponse = data['choices'][0]['message']['content'];
        
        setState(() {
          _messages.add({'role': 'ai', 'text': aiResponse});
        });
      } else {
        throw Exception("Service Error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'text': 'Error: ${e.toString()}'});
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chef & Pantry Scanner', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                bool isAi = msg['role'] == 'ai';
                return Align(
                  alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isAi ? AppTheme.secondaryColor.withValues(alpha: 0.5) : AppTheme.primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isAi ? 0 : 20),
                        bottomRight: Radius.circular(isAi ? 20 : 0),
                      ),
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(color: isAi ? AppTheme.textColor : Colors.white, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator(color: AppTheme.primaryColor)),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _isLoading ? null : _scanPantry,
                  icon: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type ingredients...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: const Icon(Icons.send, color: AppTheme.primaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
