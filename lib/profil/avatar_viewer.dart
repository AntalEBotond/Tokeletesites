part of 'profile_page.dart';

class _AvatarViewer extends StatefulWidget {
  const _AvatarViewer({required this.image});

  final ImageProvider image;

  @override
  State<_AvatarViewer> createState() => _AvatarViewerState();
}

class _AvatarViewerState extends State<_AvatarViewer> {
  final TransformationController _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    final matrix = _controller.value;
    if ((matrix.storage[0] - 1).abs() < 0.01) {
      _controller.value = Matrix4.identity()..scale(2.2);
    } else {
      _controller.value = Matrix4.identity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _toggleZoom,
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  transformationController: _controller,
                  minScale: 1,
                  maxScale: 4,
                  child: Hero(
                    tag: 'profile_avatar_hero',
                    child: ClipOval(
                      child: Image(
                        image: widget.image,
                        width: 320,
                        height: 320,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
