// file_upload_field.dart, handles the file uploads

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme.dart';

class FileUploadField extends StatefulWidget {
  final void Function(PlatformFile file)? onUpload;

  const FileUploadField({super.key, this.onUpload});

  @override
  State<FileUploadField> createState() => FileUploadFieldState();
}

class FileUploadFieldState extends State<FileUploadField> {
  PlatformFile? selectedFile;

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        selectedFile = result.files.single;
      });
    }
  }

  void uploadFile() {
    if (selectedFile != null && widget.onUpload != null) {
      widget.onUpload!(selectedFile!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton(
              onPressed: pickFile,
              child: const Text("Choose file"),
            ),
            const SizedBox(width: 38),
            IconButton(
              onPressed: selectedFile == null ? null : uploadFile,
              icon: const Icon(Icons.upload),
              tooltip: "Upload",
              color: AppTheme.weekHighlightLight,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          selectedFile?.name ?? "No file selected",
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).hintColor),
        ),
      ],
    );
  }
}
