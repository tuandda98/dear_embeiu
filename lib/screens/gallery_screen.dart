import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/photo_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/masonry_gallery.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<PhotoProvider>().loadPhotos();
    });
  }

  Future<void> _pickAndAddPhoto() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      if (mounted) {
        final captionController = TextEditingController();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Thêm chú thích (tùy chọn)'),
            content: TextField(
              controller: captionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nhập chú thích cho ảnh này...',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  context.read<PhotoProvider>().addPhoto(
                    pickedFile.path,
                    caption: captionController.text.isNotEmpty
                        ? captionController.text
                        : null,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Thêm ảnh thành công!')),
                  );
                },
                child: Text('Lưu'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _pickMultiplePhotos() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      for (var file in pickedFiles) {
        if (mounted) {
          await context.read<PhotoProvider>().addPhoto(file.path);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm ${pickedFiles.length} ảnh!'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Thư Viện Ảnh'),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Consumer<PhotoProvider>(
        builder: (context, photoProvider, _) {
          return Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(12),
                child: MasonryGallery(
                  photos: photoProvider.sortedPhotos,
                  onDeletePhoto: (photoId) {
                    photoProvider.deletePhoto(photoId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã xóa ảnh')),
                    );
                  },
                ),
              ),
              // Add Photo Button
              Positioned(
                bottom: 24,
                right: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Add multiple photos button
                    FloatingActionButton.extended(
                      onPressed: _pickMultiplePhotos,
                      backgroundColor: AppColors.accentCoral,
                      icon: Icon(Icons.photo_album),
                      label: Text('Thêm Nhiều'),
                    ),
                    SizedBox(height: 12),
                    // Add single photo button
                    FloatingActionButton(
                      onPressed: _pickAndAddPhoto,
                      backgroundColor: AppColors.accentRose,
                      child: Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

