import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/polaroid_model.dart';
import 'polaroid_widget.dart';
import 'polaroid_dialog.dart';

class DraggablePolaroid extends StatefulWidget {
  final PolaroidModel polaroid;
  final String boardId;
  final Function(PolaroidModel) onUpdate;
  final VoidCallback onDelete;

  const DraggablePolaroid({
    super.key,
    required this.polaroid,
    required this.boardId,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<DraggablePolaroid> createState() => _DraggablePolaroidState();
}

class _DraggablePolaroidState extends State<DraggablePolaroid> {
  late double _x;
  late double _y;
  late double _rotation;
  bool _isDragging = false;
  Offset? _rotationStartPoint;
  double? _startRotation;

  @override
  void initState() {
    super.initState();
    _x = widget.polaroid.position['x'] ?? 100;
    _y = widget.polaroid.position['y'] ?? 100;
    _rotation = widget.polaroid.rotation;
  }

  @override
  void didUpdateWidget(DraggablePolaroid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.polaroid != widget.polaroid) {
      _x = widget.polaroid.position['x'] ?? 100;
      _y = widget.polaroid.position['y'] ?? 100;
      _rotation = widget.polaroid.rotation;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _x += details.delta.dx;
      _y += details.delta.dy;
      _isDragging = true;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() => _isDragging = false);
    
    widget.onUpdate(
      widget.polaroid.copyWith(
        position: {'x': _x, 'y': _y},
      ),
    );
  }

  void _handleRotation(DragUpdateDetails details, Size polaroidSize) {
    if (_rotationStartPoint == null || _startRotation == null) return;
    
    final center = Offset(
      _x + polaroidSize.width / 2,
      _y + polaroidSize.height / 2,
    );
    
    final currentPoint = details.globalPosition;
    
    final angle1 = math.atan2(
      _rotationStartPoint!.dy - center.dy,
      _rotationStartPoint!.dx - center.dx,
    );
    
    final angle2 = math.atan2(
      currentPoint.dy - center.dy,
      currentPoint.dx - center.dx,
    );
    
    final deltaAngle = (angle2 - angle1) * 180 / math.pi;
    
    setState(() {
      _rotation = _startRotation! + deltaAngle;
    });
  }

  void _handleRotationEnd() {
    _rotationStartPoint = null;
    _startRotation = null;
    
    widget.onUpdate(
      widget.polaroid.copyWith(rotation: _rotation),
    );
  }

  void _showPolaroidDialog() {
    showDialog(
      context: context,
      builder: (context) => PolaroidDialog(
        polaroid: widget.polaroid,
        boardId: widget.boardId,
        onUpdate: widget.onUpdate,
        onDelete: widget.onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _x,
      top: _y,
      child: Transform.rotate(
        angle: _rotation * math.pi / 180,
        child: Stack(
          children: [
            GestureDetector(
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              onTap: _showPolaroidDialog,
              child: AnimatedScale(
                scale: _isDragging ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: PolaroidWidget(
                  imageUrl: widget.polaroid.imageUrl,
                  caption: widget.polaroid.caption,
                  filterType: widget.polaroid.filterType,
                  width: 200,
                  height: 250,
                ),
              ),
            ),
            
            // Rotation handle
            Positioned(
              right: -10,
              bottom: -10,
              child: GestureDetector(
                onPanStart: (details) {
                  _rotationStartPoint = details.globalPosition;
                  _startRotation = _rotation;
                },
                onPanUpdate: (details) => _handleRotation(details, const Size(200, 250)),
                onPanEnd: (_) => _handleRotationEnd(),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.rotate_right,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}