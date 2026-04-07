import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../../models/custom_task_model.dart';
import '../../../services/database_service.dart';

class AdminTasksManagerView extends StatefulWidget {
  const AdminTasksManagerView({super.key});

  @override
  State<AdminTasksManagerView> createState() => _AdminTasksManagerViewState();
}

class _AdminTasksManagerViewState extends State<AdminTasksManagerView> {
  final DatabaseService _db = DatabaseService();
  bool _isLoading = true;
  List<CustomTaskModel> _tasks = [];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _pointsController = TextEditingController(text: '10');
  
  String _category = 'daily';
  String _priority = 'medium';
  String _targetType = 'all';
  final _targetValueController = TextEditingController();
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    
    try {
      final tasks = await _db.listCustomTasks();
      
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    final points = int.tryParse(_pointsController.text) ?? 10;
    
    final nTask = CustomTaskModel(
      id: '',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _category,
      priority: _priority,
      points: points,
      targetType: _targetType,
      targetValue: _targetType == 'all' ? null : _targetValueController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await _db.createCustomTask(nTask.toMap());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task broadcasted successfully!'), backgroundColor: Colors.green),
        );
        _titleController.clear();
        _descController.clear();
        _targetValueController.clear();
        _loadTasks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        backgroundColor: cs.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Task Central', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;
          
          final formPart = SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(LucideIcons.megaphone, color: cs.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('New Task Broadcast', 
                            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: cs.onSurface)),
                          Text('Target specific user segments', 
                            style: GoogleFonts.inter(fontSize: 14, color: cs.onSurface.withOpacity(0.5))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  _buildInputGroup(
                    label: 'CORE DETAILS',
                    cs: cs,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            labelText: 'Task Title',
                            hintText: 'e.g. Community Cleanup #4',
                            prefixIcon: Icon(LucideIcons.type),
                          ),
                          validator: (v) => v!.isEmpty ? 'Title is required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Instructions',
                            hintText: 'Detailed steps for the user...',
                            prefixIcon: Icon(LucideIcons.textCursor),
                            alignLabelWithHint: true,
                          ),
                          validator: (v) => v!.isEmpty ? 'Description is required' : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  _buildInputGroup(
                    label: 'REWARDS & TIMING',
                    cs: cs,
                    child: LayoutBuilder(
                      builder: (context, rowConstraints) {
                        final stackFields = rowConstraints.maxWidth < 500;
                        if (stackFields) {
                          return Column(
                            children: [
                              _buildDropdownField('Category', _category, ['daily', 'weekly', 'monthly'], (v) => setState(() => _category = v!)),
                              const SizedBox(height: 16),
                              _buildDropdownField('Priority', _priority, ['low', 'medium', 'high'], (v) => setState(() => _priority = v!)),
                              const SizedBox(height: 16),
                              _buildPointsField(),
                            ],
                          );
                        }
                        
                        return Row(
                          children: [
                            Expanded(child: _buildDropdownField('Category', _category, ['daily', 'weekly', 'monthly'], (v) => setState(() => _category = v!))),
                            const SizedBox(width: 16),
                            Expanded(child: _buildDropdownField('Priority', _priority, ['low', 'medium', 'high'], (v) => setState(() => _priority = v!))),
                            const SizedBox(width: 16),
                            Expanded(child: _buildPointsField(),),
                          ],
                        );
                      }
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  _buildInputGroup(
                    label: 'TARGET SEGMENTATION',
                    cs: cs,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cs.primary.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _targetType,
                            decoration: const InputDecoration(
                              labelText: 'Target Type',
                              prefixIcon: Icon(LucideIcons.users),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All System Users')),
                              DropdownMenuItem(value: 'community', child: Text('Specific Community')),
                              DropdownMenuItem(value: 'disease', child: Text('Diagnosed Disease')),
                              DropdownMenuItem(value: 'plant', child: Text('Plant Species')),
                            ],
                            onChanged: (v) => setState(() {
                               _targetType = v!;
                               _targetValueController.clear();
                            }),
                          ),
                          if (_targetType != 'all') ...[
                            const SizedBox(height: 16),
                            Consumer<AdminController>(
                              builder: (context, admin, _) {
                                List<String> options = [];
                                if (_targetType == 'community') {
                                  options = admin.communities.map((c) => c.name).toList();
                                  if (options.isEmpty) options = ['Default Community'];
                                } else if (_targetType == 'disease') {
                                  options = admin.existingDiseaseTypes;
                                  if (options.isEmpty) options = ['Diseased', 'Critical Condition', 'Dead / Deceased'];
                                } else if (_targetType == 'plant') {
                                  options = admin.existingPlantSpecies;
                                  if (options.isEmpty) options = ['Rose', 'Neem', 'Mango', 'Banyan', 'Aloe Vera'];
                                }

                                return DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Select Target ${_targetType[0].toUpperCase()}${_targetType.substring(1)}',
                                    prefixIcon: Icon(_getTargetIcon(_targetType)),
                                    border: const OutlineInputBorder(),
                                    filled: true,
                                    fillColor: cs.surface,
                                  ),
                                  value: (options.contains(_targetValueController.text) && _targetValueController.text.isNotEmpty) 
                                      ? _targetValueController.text 
                                      : null,
                                  items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      _targetValueController.text = v!;
                                    });
                                  },
                                  validator: (v) => (_targetType != 'all' && (v == null || v.isEmpty)) ? 'Please select a target' : null,
                                );
                              },
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        elevation: 8,
                        shadowColor: cs.primary.withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(LucideIcons.send, size: 20),
                      label: Text(_isSaving ? 'Broadcasting...' : 'INITIATE BROADCAST', 
                                  style: GoogleFonts.inter(letterSpacing: 1.2, fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: _isSaving ? null : _saveTask,
                    ),
                  )
                ],
              ),
            ),
          );

          final listPart = Container(
            decoration: BoxDecoration(
              color: cs.surface,
              boxShadow: isMobile ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 40, offset: const Offset(-20, 0))],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Row(
                    children: [
                      Text('Active Broadcasts', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
                      const Spacer(),
                      if (!_isLoading) 
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: cs.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text('${_tasks.length} total', style: TextStyle(color: cs.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : _tasks.isEmpty 
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.clipboardList, size: 48, color: cs.onSurface.withOpacity(0.1)),
                              const SizedBox(height: 16),
                              Text('No active tasks', style: TextStyle(color: cs.onSurface.withOpacity(0.3))),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _tasks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final t = _tasks[i];
                            final priorityColor = t.priority == 'high' ? Colors.red : (t.priority == 'medium' ? Colors.orange : cs.primary);
                            
                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: cs.onSurface.withOpacity(0.05)),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: priorityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                  child: Icon(LucideIcons.clipboardCheck, color: priorityColor, size: 20),
                                ),
                                title: Text(t.title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text('${t.targetType.toUpperCase()} • ${t.points} Coins', 
                                  style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
                                trailing: IconButton(
                                  icon: Icon(LucideIcons.trash2, size: 18, color: Colors.red.withOpacity(0.7)),
                                  onPressed: () => _confirmDeleteTask(context, t),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );

          if (isMobile) {
            return Column(
              children: [
                Expanded(flex: 3, child: formPart),
                Container(height: 8, color: cs.onSurface.withOpacity(0.02)),
                Expanded(flex: 2, child: listPart),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: formPart),
              Expanded(flex: 2, child: listPart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInputGroup({required String label, required Widget child, required ColorScheme cs}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: cs.primary)),
        ),
        child,
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildPointsField() {
    return TextFormField(
      controller: _pointsController,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: const InputDecoration(
        labelText: 'Coins Reward',
        prefixIcon: Icon(LucideIcons.coins, color: Colors.amber),
      ),
      validator: (v) => (int.tryParse(v ?? '') == null) ? 'Invalid' : null,
    );
  }



  Future<void> _confirmDeleteTask(BuildContext context, CustomTaskModel task) async {
    // Capture the messenger state before the widget is potentially unmounted
    // during the _loadTasks() setState call.
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Task?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('This will permanently remove "${task.title}" and it will no longer be broadcasted to users.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _db.deleteCustomTask(task.id);
        await _loadTasks();
        
        // Use the captured messenger to show the snackbar safely
        messenger.showSnackBar(const SnackBar(content: Text('Task removed successfully.'), backgroundColor: Colors.green));
      } catch (e) {
        setState(() => _isLoading = false);
        messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  IconData _getTargetIcon(String type) {
    switch (type) {
      case 'community': return LucideIcons.users;
      case 'disease': return LucideIcons.activity;
      case 'plant': return LucideIcons.sprout;
      default: return LucideIcons.globe;
    }
  }
}
