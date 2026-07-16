#include <iostream>
#include <vector>
#include <cmath>

// Struct to represent a 2D Rectangle (Window Geometry)
struct WindowGeometry {
    int x;
    int y;
    int width;
    int height;
};

extern "C" {

    // Calculates tiling layout coordinates for a specific window index in a grid
    // Returns a WindowGeometry struct
    WindowGeometry calculate_tiling_grid(
        int screen_width,
        int screen_height,
        int taskbar_height,
        int window_count,
        int gap,
        int window_index
    ) {
        WindowGeometry geom = {0, 0, 0, 0};
        if (window_count <= 0 || window_index < 0 || window_index >= window_count) {
            return geom;
        }

        // Adjust height for taskbar (placed at the bottom)
        int usable_height = screen_height - taskbar_height;

        // Calculate columns and rows
        int cols = std::ceil(std::sqrt(window_count));
        int rows = std::ceil(static_cast<double>(window_count) / cols);

        // Grid dimensions
        int col_width = (screen_width - (gap * (cols + 1))) / cols;
        int row_height = (usable_height - (gap * (rows + 1))) / rows;

        // Calculate position
        int col_idx = window_index % cols;
        int row_idx = window_index / cols;

        geom.x = gap + col_idx * (col_width + gap);
        geom.y = gap + row_idx * (row_height + gap);
        geom.width = col_width;
        geom.height = row_height;

        // Handle the last row window sizing if window_count is not a perfect grid
        if (row_idx == rows - 1) {
            int remaining_wins = window_count - (row_idx * cols);
            if (remaining_wins < cols) {
                // Stretch to fill space nicely
                col_width = (screen_width - (gap * (remaining_wins + 1))) / remaining_wins;
                geom.x = gap + col_idx * (col_width + gap);
                geom.width = col_width;
            }
        }

        return geom;
    }

    // Calculates the window snapping geometries based on mouse drag region
    // Snap Directions:
    // 1 = Left, 2 = Right, 3 = Top-Left, 4 = Top-Right, 5 = Bottom-Left, 6 = Bottom-Right, 7 = Fullscreen
    WindowGeometry calculate_snap_geometry(
        int screen_width,
        int screen_height,
        int taskbar_height,
        int direction
    ) {
        WindowGeometry geom = {0, 0, screen_width, screen_height - taskbar_height};
        int half_w = screen_width / 2;
        int half_h = (screen_height - taskbar_height) / 2;

        switch (direction) {
            case 1: // Left Half
                geom.width = half_w;
                break;
            case 2: // Right Half
                geom.x = half_w;
                geom.width = half_w;
                break;
            case 3: // Top-Left Quarter
                geom.width = half_w;
                geom.height = half_h;
                break;
            case 4: // Top-Right Quarter
                geom.x = half_w;
                geom.width = half_w;
                geom.height = half_h;
                break;
            case 5: // Bottom-Left Quarter
                geom.y = half_h;
                geom.width = half_w;
                geom.height = half_h;
                break;
            case 6: // Bottom-Right Quarter
                geom.x = half_w;
                geom.y = half_h;
                geom.width = half_w;
                geom.height = half_h;
                break;
            case 7: // Fullscreen
            default:
                break;
        }

        return geom;
    }
}
