import 'package:flutter/material.dart';

/// A custom FloatingActionButtonLocation that positions the FAB
/// at a specific location to avoid overlapping with the navigation bar.
class CustomEndTopFabLocation extends FloatingActionButtonLocation {
  final double offsetY;

  const CustomEndTopFabLocation({this.offsetY = 16.0});

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Calculate the position from the right edge
    final double fabX = scaffoldGeometry.scaffoldSize.width - 
                        scaffoldGeometry.floatingActionButtonSize.width - 
                        16.0; // 16.0 is the standard margin
    
    // Position from the top with the specified offset
    final double fabY = offsetY;
    
    return Offset(fabX, fabY);
  }
}
