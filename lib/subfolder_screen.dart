import 'package:file_manager/helper/folder_model.dart';
import 'package:file_manager/helper/db_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

class subFolder extends StatefulWidget {
  final Folder folder;

  subFolder({required this.folder});

  @override
  subFolderState createState() => subFolderState();
}

class subFolderState extends State<subFolder> {
  List<Folder> children = [];

  Set<Folder> selectedFiles = {};
  bool multiSelectMode = false;

  Folder? selectedFolder;
  List<Folder> folders = [];

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    children = await DatabaseHelper.instance.getFolders(parentId: widget.folder.id);

    children.sort((a, b) {
      if (a.isFile == b.isFile) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return a.isFile ? 1 : -1;
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final onlyFolders = children.where((item) => !item.isFile).toList();
    final onlyFiles = children.where((item) => item.isFile).toList();

    final showFolderLabel = onlyFolders.isNotEmpty;
    final showFileLabel = onlyFiles.isNotEmpty;
    final itemCount =
        (showFolderLabel ? 1 : 0) +
            onlyFolders.length +
            (showFileLabel ? 1 : 0) +
            onlyFiles.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: Text(widget.folder.name),
      ),
      body: ListView.builder(
        itemCount: itemCount,
        itemBuilder: (context, index) {
          int i = 0;

          if (showFolderLabel) {
            if (index == i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "FOLDERS",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (multiSelectMode)
                      IconButton(
                        icon: Icon(Icons.clear, color: Colors.black),
                        tooltip: 'Clear selection',
                        onPressed: () {
                          setState(() {
                            selectedFiles.clear();
                            multiSelectMode = false;
                          });
                        },
                      ),
                  ],
                ),
              );
            }
            i++;
          }

          if (index < i + onlyFolders.length) {
            final folder = onlyFolders[index - i];
            final isSelected = selectedFiles.contains(folder);
            return _buildFolderCard(folder, isSelected, index - i);
          }
          i += onlyFolders.length;

          if (showFileLabel) {
            if (index == i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                child: Text(
                  "FILES",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              );
            }
            i++;
          }

          final file = onlyFiles[index - i];
          final isSelected = selectedFiles.contains(file);
          return _buildFolderCard(file, isSelected, index - i);
        },
      ),
      floatingActionButton: customFAB(),
    );
  }


  Widget _buildFolderCard(Folder folder, bool isSelected, int index) {
    final isFile = folder.isFile;
    final isMultiSelected = multiSelectMode && selectedFiles.contains(folder);

    Widget tile = _buildListTile(folder);

    if (isFile) {
      return Card(
        key: ValueKey(folder.name + folder.createdAt.toString()),
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        color: isMultiSelected
            ? Colors.blue.shade100
            : (isSelected ? Colors.grey.shade300 : Colors.white),
        child: GestureDetector(
          onTap: () {
            if (multiSelectMode) {
              setState(() {
                if (selectedFiles.contains(folder)) {
                  selectedFiles.remove(folder);
                  if (selectedFiles.isEmpty) multiSelectMode = false;
                } else {
                  selectedFiles.add(folder);
                }
              });
            } else {
              if (folder.filePath != null) {
                OpenFilex.open(folder.filePath!);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => subFolder(folder: folder),
                  ),
                );
              }
            }
          },
          onLongPress: () {
            setState(() {
              multiSelectMode = true;
              selectedFiles.add(folder);
            });
          },
          child: Draggable<List<Folder>>(
            data: isMultiSelected ? selectedFiles.toList() : [folder],
            feedback: _buildDragFeedback(isMultiSelected ? selectedFiles : {folder}),
            childWhenDragging: Opacity(opacity: 0.2, child: tile),
            child: tile,
          ),
        ),
      );
    } else {
      return Card(
        key: ValueKey(folder.name + folder.createdAt.toString()),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        color: Colors.white,
        child: DragTarget<List<Folder>>(
          onWillAcceptWithDetails: (details) => _canAcceptDrop(folder, details.data),
          onAcceptWithDetails: (details) async {
            List<Folder> draggedFiles = details.data;
            for (var file in draggedFiles) {
              file.parentId = folder.id;
              await DatabaseHelper.instance.updateFolder(file);
            }
            selectedFiles.clear();
            multiSelectMode = false;
            await _loadChildren();
          },

          builder: (context, candidateData, rejectedData) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => subFolder(folder: folder),
                  ),
                );
              },
              child: Draggable<List<Folder>>(
                data: [folder],
                feedback: _buildDragFeedback({folder}),
                childWhenDragging: Opacity(opacity: 0.2, child: tile),
                child: Container(
                  decoration: BoxDecoration(
                    border: candidateData.isNotEmpty
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
                  ),
                  child: tile,
                ),
              ),
            );
          },
        ),
      );
    }

  }
  bool _canAcceptDrop(Folder target, List<Folder> dragged) {
    return dragged.every((f) =>
    f.id != target.id &&
        f.parentId != target.id
    );
  }

  Widget _buildListTile(Folder folder) {
    return ListTile(
      leading: Icon(
        folder.isFile ? Icons.insert_drive_file : Icons.folder,
        color: folder.isFile ? Colors.grey.shade400 : Colors.grey,
        size: 40,
      ),
      title: Text(folder.name),
      subtitle: Text('${_timeAgo(folder.createdAt)} ago'),
      trailing:  multiSelectMode && folder.isFile
          ? Icon(
        selectedFiles.contains(folder)
            ? Icons.check_box
            : Icons.check_box_outline_blank,
        color: Colors.blue,
      )
          : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
            onSelected: (value) {
              if (value == 'rename') {
                renameDialog(folder);
              } else if (value == 'delete') {
                deleteDialog(folder);
              }
            },
          )
        ],
      ),

      onTap: () {
        if (multiSelectMode) {
          setState(() {
            if (selectedFiles.contains(folder)) {
              selectedFiles.remove(folder);
              if (selectedFiles.isEmpty) multiSelectMode = false;
            } else {
              selectedFiles.add(folder);
            }
          });
        } else {
          if (folder.isFile && folder.filePath != null) {
            OpenFilex.open(folder.filePath!);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => subFolder(folder: folder),
              ),
            );
          }
        }
      },
    );
  }
  Widget _buildDragFeedback(Set<Folder> selectedFiles) {
    final count = selectedFiles.length;
    final displayText = count == 1 ? selectedFiles.first.name : "$count files selected";

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade400),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 4),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: Icon(Icons.insert_drive_file, size: 28, color: Colors.grey),
          title: Text(
            displayText,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(Icons.more_vert, size: 16, color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget customFAB() {
    return Container(
      margin: EdgeInsets.only(right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              _pickAndAddFile();
            },
            child: Icon(Icons.file_present_sharp, color: Colors.white),
          ),
          Container(
            height: 26,
            width: 2,
            margin: EdgeInsets.symmetric(horizontal: 12),
            color: Colors.grey.shade300,
          ),
          GestureDetector(
            onTap: () {
              _showCreateFolderDialog();
            },
            child: Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void renameDialog(Folder folder) {
    TextEditingController _controller = TextEditingController(text: folder.name);
    bool showError = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text('Rename Folder'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter a new name for the folder:',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Folder name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: showError ? 'Folder name cannot be empty' : null,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('CANCEL', style: TextStyle(color: Colors.blue)),
              ),
              TextButton(
                onPressed: () async {
                  String newName = _controller.text.trim();
                  if (newName.isEmpty) {
                    setState(() => showError = true);
                  } else {
                    folder.name = newName;
                    await DatabaseHelper.instance.updateFolder(folder);
                    Navigator.pop(context);
                    await _loadChildren();
                  }
                },

                child: Text('RENAME', style: TextStyle(color: Colors.blue)),
              ),

            ],
          ),
        );
      },
    );
  }

  void deleteDialog(Folder folder) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('Delete Folder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete this folder?',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              ),
              SizedBox(height: 12),
              Text(
                folder.name,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () async {
                await DatabaseHelper.instance.deleteFolder(folder.id!);
                Navigator.pop(context);
                _loadChildren();
              },
              child: Text('DELETE', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showCreateFolderDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('New Folder'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCEL')),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Folder newFolder = Folder(
                  name: name,
                  createdAt: DateTime.now(),
                  isFile: false,
                  parentId: widget.folder.id,
                );
                await DatabaseHelper.instance.insertFolder(newFolder);
                Navigator.pop(context);
                await _loadChildren();
              }
            },
            child: Text('CREATE'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndAddFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      Folder newFile = Folder(
        name: file.name,
        createdAt: DateTime.now(),
        isFile: true,
        filePath: file.path!,
        parentId: widget.folder.id,
      );
      await DatabaseHelper.instance.insertFolder(newFile);
      await _loadChildren();
    }
  }
  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "0 minutes";
    if (diff.inHours < 1) return "${diff.inMinutes} minutes";
    if (diff.inDays < 1) return "${diff.inHours} hours";
    if (diff.inDays < 7) return "${diff.inDays} days";
    return "${(diff.inDays / 7).floor()} week";
  }
}
