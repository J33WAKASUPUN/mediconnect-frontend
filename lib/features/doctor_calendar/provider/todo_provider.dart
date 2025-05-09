import 'package:flutter/foundation.dart';
import '../../../core/models/todo_model.dart';
import '../../../core/services/api_service.dart';

class TodoProvider with ChangeNotifier {
  final ApiService _apiService;
  
  List<Todo> _todos = [];
  bool _isLoading = false;
  String? _error;
  
  TodoProvider({required ApiService apiService}) : _apiService = apiService;
  
  List<Todo> get todos => _todos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get todos for a specific date or date range
  Future<void> fetchTodos({required DateTime startDate, DateTime? endDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _todos = await _apiService.getTodos(startDate: startDate, endDate: endDate);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Create new todo
  Future<Todo> createTodo(Todo todo) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final newTodo = await _apiService.createTodo(todo);
      _todos.add(newTodo);
      _isLoading = false;
      notifyListeners();
      return newTodo;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Update existing todo
  Future<Todo> updateTodo(String id, Todo todo) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final updatedTodo = await _apiService.updateTodo(id, todo);
      final index = _todos.indexWhere((t) => t.id == id);
      if (index != -1) {
        _todos[index] = updatedTodo;
      }
      _isLoading = false;
      notifyListeners();
      return updatedTodo;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Delete todo
  Future<void> deleteTodo(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _apiService.deleteTodo(id);
      _todos.removeWhere((todo) => todo.id == id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Toggle todo completion status
  Future<Todo> toggleTodoStatus(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final updatedTodo = await _apiService.toggleTodoStatus(id);
      final index = _todos.indexWhere((t) => t.id == id);
      if (index != -1) {
        _todos[index] = updatedTodo;
      }
      _isLoading = false;
      notifyListeners();
      return updatedTodo;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Get todos for a specific date
  List<Todo> getTodosForDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return _todos.where((todo) {
      return todo.date.isAfter(dayStart) && 
             todo.date.isBefore(dayEnd) ||
             todo.date.isAtSameMomentAs(dayStart);
    }).toList();
  }
}