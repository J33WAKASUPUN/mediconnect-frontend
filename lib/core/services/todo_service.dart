import 'package:mediconnect/config/api_endpoints.dart';
import '../models/todo_model.dart';
import 'base_api_service.dart';

class TodoService extends BaseApiService {
  String? _authToken;

  // Set auth token
  @override
  void setAuthToken(String token) {
    _authToken = token;
    super.setAuthToken(token);
  }

  Future<List<Todo>> getTodos({required DateTime startDate, DateTime? endDate}) async {
    try {
      Map<String, dynamic> queryParams = {
        'startDate': startDate.toIso8601String(),
      };

      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await get(
        ApiEndpoints.todos,
        queryParams: queryParams,
      );
      
      if (response['success'] == true && response['data'] != null) {
        List<dynamic> todosJson = response['data'];
        return todosJson.map((json) => Todo.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to load todos');
      }
    } catch (e) {
      throw Exception('Failed to load todos: $e');
    }
  }
  
  Future<Todo> createTodo(Todo todo) async {
    try {
      final response = await post(
        ApiEndpoints.todos,
        data: todo.toJson(),
      );
      
      if (response['success'] == true && response['data'] != null) {
        return Todo.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to create todo');
      }
    } catch (e) {
      throw Exception('Failed to create todo: $e');
    }
  }
  
  Future<Todo> updateTodo(String id, Todo todo) async {
    try {
      final response = await put(
        '${ApiEndpoints.todos}/$id',
        data: todo.toJson(),
      );
      
      if (response['success'] == true && response['data'] != null) {
        return Todo.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to update todo');
      }
    } catch (e) {
      throw Exception('Failed to update todo: $e');
    }
  }
  
  Future<void> deleteTodo(String id) async {
    try {
      final response = await delete('${ApiEndpoints.todos}/$id');
      
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to delete todo');
      }
    } catch (e) {
      throw Exception('Failed to delete todo: $e');
    }
  }
  
  Future<Todo> toggleTodoStatus(String id) async {
    try {
      final response = await put('${ApiEndpoints.todos}/$id/toggle');
      
      if (response['success'] == true && response['data'] != null) {
        return Todo.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to toggle todo status');
      }
    } catch (e) {
      throw Exception('Failed to toggle todo status: $e');
    }
  }
}