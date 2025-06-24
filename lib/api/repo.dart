import 'dart:convert';
import 'package:http/http.dart' as http;

class RepoRequest {
  static Future<List<Map<String, dynamic>>> fetchRepos() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/search/repositories?q=org:AppManager-Repo&sort=stars&order=desc&per_page=100'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['items']);
      } else {
        throw Exception('Failed to load repositories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching repositories: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> searchRepos(String query) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/search/repositories?q=org:AppManager-Repo+$query&sort=stars&order=desc&per_page=100'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['items']);
      } else {
        throw Exception('Failed to search repositories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching repositories: $e');
    }
  }

  static Future<String> fetchAppsJson(String repoName) async {
    try {
      final response = await http.get(
        Uri.parse('https://raw.githubusercontent.com/AppManager-Repo/$repoName/main/apps.json'),
      );
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to fetch apps.json: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching apps.json: $e');
    }
  }
}