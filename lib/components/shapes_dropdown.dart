import 'package:flutter/material.dart';

enum ShapeType {
  circle,
  square,
  triangle,
  rectangle,
  star,
  arrow,
  heart,
  pentagon,
  hexagon,
}

class ShapesDropdown extends StatelessWidget {
  final Function(ShapeType) onShapeSelected;
  final Offset position;

  const ShapesDropdown({
    Key? key,
    required this.onShapeSelected,
    required this.position,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Select Shape',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildShapeItem(
                    context,
                    ShapeType.circle,
                    'Circle',
                    Icons.circle_outlined,
                  ),
                  _buildShapeItem(
                    context,
                    ShapeType.square,
                    'Square',
                    Icons.square_outlined,
                  ),
                  _buildShapeItem(
                    context,
                    ShapeType.triangle,
                    'Triangle',
                    Icons.change_history,
                  ),
                  _buildShapeItem(
                    context,
                    ShapeType.rectangle,
                    'Rectangle',
                    Icons.rectangle_outlined,
                  ),
                  _buildShapeItem(
                    context,
                    ShapeType.star,
                    'Star',
                    Icons.star_outline,
                  ),
                  _buildShapeItem(
                    context,
                    ShapeType.arrow,
                    'Arrow',
                    Icons.arrow_forward,
                  ),
                  _buildShapeItem(
                    context,
                    ShapeType.heart,
                    'Heart',
                    Icons.favorite_border,
                  ),
                  _buildShapeItem(
                    context,
                    ShapeType.pentagon,
                    'Pentagon',
                    Icons.pentagon_outlined,
                  ),
                  _buildShapeItem(
                    context,
                    ShapeType.hexagon,
                    'Hexagon',
                    Icons.hexagon_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShapeItem(
      BuildContext context,
      ShapeType shapeType,
      String label,
      IconData icon,
      ) {
    return InkWell(
      onTap: () {
        onShapeSelected(shapeType);
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: const Color(0xFF374151),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Shape annotation class to store shape data
class ShapeAnnotation {
  final Offset position;
  final ShapeType shapeType;
  final Size size;
  final Color color;
  final double strokeWidth;

  ShapeAnnotation({
    required this.position,
    required this.shapeType,
    required this.size,
    required this.color,
    required this.strokeWidth,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': position.dx,
      'y': position.dy,
      'shapeType': shapeType.index,
      'width': size.width,
      'height': size.height,
      'color': color.value,
      'strokeWidth': strokeWidth,
    };
  }

  factory ShapeAnnotation.fromJson(Map<String, dynamic> json) {
    return ShapeAnnotation(
      position: Offset(json['x'], json['y']),
      shapeType: ShapeType.values[json['shapeType']],
      size: Size(json['width'], json['height']),
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
    );
  }
}