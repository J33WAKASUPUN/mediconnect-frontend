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
  Future<void> fetchTodos(
      {required DateTime startDate, DateTime? endDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final todos =
          await _apiService.getTodos(
            startDate: startDate, 
            endDate: endDate ?? DateTime(startDate.year, startDate.month + 1, 0)
          );

      // Log todos to see what's coming back
      print('Fetched todos: ${todos.length}');
      todos.forEach((todo) => print('Todo: ${todo.title} - ${todo.date}'));

      // Update the state
      _todos = todos;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching todos: $e');
      // If API call fails but we already have todos, keep them
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      // Don't rethrow, just log
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
      print('Error creating todo: $e');
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      
      // Return a fallback todo with a temporary ID
      final fallbackTodo = Todo(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        doctorId: todo.doctorId,
        date: todo.date,
        title: todo.title,
        description: todo.description,
        priority: todo.priority,
        completed: todo.completed,
        time: todo.time,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Add to local state even though server failed
      _todos.add(fallbackTodo);
      notifyListeners();
      
      return fallbackTodo;
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
      print('Error updating todo: $e');
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      
      // Apply the update locally even though server failed
      final index = _todos.indexWhere((t) => t.id == id);
      if (index != -1) {
        // Create a new local todo with the updates but preserve the ID
        final updatedTodo = Todo(
          id: id,
          doctorId: todo.doctorId,
          date: todo.date,
          title: todo.title,
          description: todo.description,
          priority: todo.priority,
          completed: todo.completed,
          time: todo.time,
          createdAt: _todos[index].createdAt,
          updatedAt: DateTime.now(),
        );
        _todos[index] = updatedTodo;
        notifyListeners();
        return updatedTodo;
      }
      
      // If we couldn't find the todo to update, return the original
      return todo;
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
      print('Error deleting todo: $e');
      _isLoading = false;
      _error = e.toString();
      
      // Remove from local state even if server call failed
      _todos.removeWhere((todo) => todo.id == id);
      notifyListeners();
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
      print('Error toggling todo status: $e');
      _isLoading = false;
      _error = e.toString();
      
      // Toggle status locally even if server call failed
      final index = _todos.indexWhere((t) => t.id == id);
      if (index != -1) {
        final currentTodo = _todos[index];
        final updatedTodo = Todo(
          id: currentTodo.id,
          doctorId: currentTodo.doctorId,
          date: currentTodo.date,
          title: currentTodo.title,
          description: currentTodo.description,
          priority: currentTodo.priority,
          completed: !currentTodo.completed, // Toggle the status
          time: currentTodo.time,
          createdAt: currentTodo.createdAt,
          updatedAt: DateTime.now(),
        );
        _todos[index] = updatedTodo;
        notifyListeners();
        return updatedTodo;
      }
      
      notifyListeners();
      throw Exception('Todo not found');
    }
  }

  // Get todos for a specific date
  List<Todo> getTodosForDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    print('Getting todos for date: $dayStart');
    print('Total todos in state: ${_todos.length}');

    return _todos.where((todo) {
      final todoDate = DateTime(todo.date.year, todo.date.month, todo.date.day);
      print('Comparing todo date: $todoDate with $dayStart');
      
      // Check if todo date is between dayStart and dayEnd (inclusive)
      return todoDate.isAtSameMomentAs(dayStart) || 
             (todoDate.isAfter(dayStart) && todoDate.isBefore(dayEnd)) ||
             todoDate.isAtSameMomentAs(dayEnd);
    }).toList();
  }
}