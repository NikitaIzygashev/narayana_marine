import 'package:flutter/material.dart';

import '../../../models/boat.dart';
import '../../../models/tour.dart';
import '../../../services/auth_service.dart';
import '../../../services/content_repository.dart';
import '../../../services/image_upload_service.dart';
import 'content_editor_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, required this.authService});
  final AuthService authService;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _repository = ContentRepository();
  final _images = ImageUploadService();
  late Future<_DashboardData> _data = _load();

  Future<_DashboardData> _load() async => _DashboardData(
        boats: await _repository.fetchAllBoats(),
        tours: await _repository.fetchAllTours(),
      );

  void _reload() => setState(() => _data = _load());

  Future<void> _openBoat([Boat? boat]) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ContentEditorPage(boat: boat)));
    _reload();
  }

  Future<void> _openTour([Tour? tour]) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ContentEditorPage(tour: tour, isBoat: false)));
    _reload();
  }

  Future<void> _deleteBoat(Boat boat) async {
    if (!await _confirm('Delete ${boat.name}? This cannot be undone.')) return;
    try {
      await _repository.saveBoat(boat.copyWith(isPublished: false), isNew: false);
      for (final image in boat.gallery) { await _images.deleteImage(image); }
      await _repository.deleteBoat(boat.id);
      _reload();
    } catch (error) { _message('Delete incomplete. The boat is unpublished and can be retried. $error'); }
  }

  Future<void> _deleteTour(Tour tour) async {
    if (!await _confirm('Delete ${tour.name}? This cannot be undone.')) return;
    try {
      await _repository.saveTour(tour.copyWith(isPublished: false), isNew: false);
      for (final image in tour.gallery) { await _images.deleteImage(image); }
      await _repository.deleteTour(tour.id);
      _reload();
    } catch (error) { _message('Delete incomplete. The experience is unpublished and can be retried. $error'); }
  }

  Future<bool> _confirm(String message) async => await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(title: const Text('Confirm action'), content: Text(message), actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
    ]),
  ) ?? false;

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Narayana Marine Admin'),
        actions: [IconButton(tooltip: 'Refresh', onPressed: _reload, icon: const Icon(Icons.refresh)), TextButton.icon(onPressed: widget.authService.signOut, icon: const Icon(Icons.logout), label: const Text('Logout'))],
        bottom: const TabBar(tabs: [Tab(text: 'Boats'), Tab(text: 'Tours')]),
      ),
      body: FutureBuilder<_DashboardData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Content could not be loaded.'), TextButton(onPressed: _reload, child: const Text('Retry'))]));
          final data = snapshot.data!;
          return TabBarView(children: [
            _ContentList<Boat>(items: data.boats, addLabel: 'Add boat', onAdd: () => _openBoat(), title: (item) => item.name, subtitle: (item) => item.subtitle, isPublished: (item) => item.isPublished, onEdit: _openBoat, onToggle: (item, value) async { await _repository.saveBoat(item.copyWith(isPublished: value), isNew: false); _reload(); }, onMove: (item, offset) async { await _repository.saveBoat(item.copyWith(sortOrder: item.sortOrder + offset), isNew: false); _reload(); }, onDelete: _deleteBoat),
            _ContentList<Tour>(items: data.tours, addLabel: 'Add tour', onAdd: () => _openTour(), title: (item) => item.name, subtitle: (item) => item.shortDescription, isPublished: (item) => item.isPublished, onEdit: _openTour, onToggle: (item, value) async { await _repository.saveTour(item.copyWith(isPublished: value), isNew: false); _reload(); }, onMove: (item, offset) async { await _repository.saveTour(item.copyWith(sortOrder: item.sortOrder + offset), isNew: false); _reload(); }, onDelete: _deleteTour),
          ]);
        },
      ),
    ),
  );
}

class _DashboardData {
  const _DashboardData({required this.boats, required this.tours});
  final List<Boat> boats;
  final List<Tour> tours;
}

class _ContentList<T> extends StatelessWidget {
  const _ContentList({required this.items, required this.addLabel, required this.onAdd, required this.title, required this.subtitle, required this.isPublished, required this.onEdit, required this.onToggle, required this.onMove, required this.onDelete});
  final List<T> items;
  final String addLabel;
  final VoidCallback onAdd;
  final String Function(T item) title;
  final String Function(T item) subtitle;
  final bool Function(T item) isPublished;
  final Future<void> Function(T item) onEdit;
  final Future<void> Function(T item, bool value) onToggle;
  final Future<void> Function(T item, int offset) onMove;
  final Future<void> Function(T item) onDelete;
  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(onPressed: onAdd, icon: const Icon(Icons.add), label: Text(addLabel)),
    body: items.isEmpty ? Center(child: Text('No content yet. Use "$addLabel" to begin.')) : ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          title: Text(title(item)),
          subtitle: Text(subtitle(item).isEmpty ? 'No short description yet' : subtitle(item)),
          leading: Switch(value: isPublished(item), onChanged: (value) => onToggle(item, value)),
          trailing: Wrap(spacing: 2, children: [
            IconButton(tooltip: 'Move earlier', onPressed: index == 0 ? null : () => onMove(item, -10), icon: const Icon(Icons.arrow_upward)),
            IconButton(tooltip: 'Move later', onPressed: index == items.length - 1 ? null : () => onMove(item, 10), icon: const Icon(Icons.arrow_downward)),
            IconButton(tooltip: 'Edit', onPressed: () => onEdit(item), icon: const Icon(Icons.edit_outlined)),
            IconButton(tooltip: 'Delete', onPressed: () => onDelete(item), icon: const Icon(Icons.delete_outline)),
          ]),
          onTap: () => onEdit(item),
        );
      },
    ),
  );
}
