import 'dart:convert';
import 'package:http/http.dart' as http;
import 'main.dart';

class GeminiService {
  static const String apiKey =
      '-----------------------------------------------';

  static Future<String> categorizeTask(String task) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                    "Categorize this task into exactly one category: Work, Personal, Study, Health, Finance. Return only the category name.\n\nTask: $task"
              }
            ]
          }
        ]
      }),
    );

    final data = jsonDecode(response.body);

    final candidates = data["candidates"];

    if (candidates == null || candidates.isEmpty) {
      throw Exception("No response from Gemini");
    }

    final text = candidates[0]["content"]?["parts"]?[0]?["text"];

    if (text == null) {
      throw Exception("Invalid Gemini response format");
    }

    return text.toString().trim();
  }

  static Future<List<Task>> searchTasks(
    String query,
    List<Task> tasks,
  ) async {
    final taskData = tasks
        .map((t) => "${t.title} | ${t.category} | ${t.priority} | ${t.isDone}")
        .toList()
        .join("\n");

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text": """
You are a task ranking AI.

User query:
$query

Tasks:
$taskData

Return ONLY the task titles that match the query, ranked best first.
One per line.
"""
              }
            ]
          }
        ]
      }),
    );

    final data = jsonDecode(response.body);

    final text = data["candidates"][0]["content"]["parts"][0]["text"] as String;

    final matchedTitles = text.split("\n").map((e) => e.trim()).toList();

    return tasks.where((t) => matchedTitles.contains(t.title)).toList();
  }
}
