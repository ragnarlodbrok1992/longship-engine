#import "Basic";
#import "GL";
#import "Math";

Color :: struct {
  r : float;
  g : float;
  b : float;
}

IsoTile :: struct {
  // Assumptions
  // Isotiles are put on Y = 0.0 plane
  id : int;

  // Local data
  // @NOTE ragnar: In IsoTile we have a concept of NW/NE/SE/SW coordinates
  // from world coordinates North East South West.
  // We are not keeping this data alone, it's kept inside vertex vertices data buffers.
  // Taken from earlier development we are using this map:
  // [0]  = iso_tile.nw.x;
  // [1]  = iso_tile.nw.y;
  // [2]  = iso_tile.nw.z;
  // [3]  = iso_tile.sw.x;
  // [4]  = iso_tile.sw.y;
  // [5]  = iso_tile.sw.z;
  // [6]  = iso_tile.ne.x;
  // [7]  = iso_tile.ne.y;
  // [8]  = iso_tile.ne.z;
  // [9]  = iso_tile.se.x;
  // [10] = iso_tile.se.y;
  // [11] = iso_tile.se.z;

  // Same stuff goes for color data and for line that wraps around whole isotile

  vertex_buffer_vertices_data : [12]GLfloat;
  vertex_buffer_colors_data   : [12]GLfloat;
  line_buffer_colors_data     : [12]GLfloat;
  line_buffer_vertices_data   : [12]GLfloat;

  // OpenGL bindings
  vertex_buffer_vertices : GLuint;
  vertex_buffer_colors   : GLuint;
  line_buffer_vertices   : GLuint;
  line_buffer_colors     : GLuint;
}

create_iso_tile_buffers :: (iso_tile: *IsoTile) {
  // REAL BUFFERS
  glGenBuffers(1, *iso_tile.vertex_buffer_vertices);
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_vertices);
  glBufferData(GL_ARRAY_BUFFER, size_of(type_of(iso_tile.vertex_buffer_vertices_data)), *iso_tile.vertex_buffer_vertices_data, GL_STATIC_DRAW);

  // REAL BUFFERS
  glGenBuffers(1, *iso_tile.vertex_buffer_colors);
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_colors);
  glBufferData(GL_ARRAY_BUFFER, size_of(type_of(iso_tile.vertex_buffer_colors_data)), *iso_tile.vertex_buffer_colors_data, GL_STATIC_DRAW);

  // Line buffer - vertices
  glGenBuffers(1, *iso_tile.line_buffer_vertices);
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.line_buffer_vertices);
  glBufferData(GL_ARRAY_BUFFER, size_of(type_of(iso_tile.line_buffer_vertices_data)), *iso_tile.line_buffer_vertices_data, GL_STATIC_DRAW);

  // Line buffers - colors
  glGenBuffers(1, *iso_tile.line_buffer_colors);
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.line_buffer_colors);
  glBufferData(GL_ARRAY_BUFFER, size_of(type_of(iso_tile.line_buffer_colors_data)), *iso_tile.line_buffer_colors_data, GL_STATIC_DRAW);
}

populate_iso_tile :: (iso_tile: *IsoTile, id: int, color: Color, outline_color: Color, center_pos: Vector3) {
  half_tile_width := ISO_TILE_WIDTH / 2.0;
  half_tile_height := ISO_TILE_HEIGHT / 2.0;
  
  // -x - left, x - right, -z - top, +z - bottom
  iso_tile_nw : Vector3 = .{center_pos.x - half_tile_width, 0.0, center_pos.z - half_tile_height};
  iso_tile_ne : Vector3 = .{center_pos.x + half_tile_width, 0.0, center_pos.z - half_tile_height};
  iso_tile_se : Vector3 = .{center_pos.x - half_tile_width, 0.0, center_pos.z + half_tile_height};
  iso_tile_sw : Vector3 = .{center_pos.x + half_tile_width, 0.0, center_pos.z + half_tile_height};

  // print("NW: %, NE: %, SE: %, SW: %\n", iso_tile_nw, iso_tile_ne, iso_tile_se, iso_tile_sw);

  // Populate data
  iso_tile.vertex_buffer_vertices_data[0]  = iso_tile_nw.x;
  iso_tile.vertex_buffer_vertices_data[1]  = iso_tile_nw.y;
  iso_tile.vertex_buffer_vertices_data[2]  = iso_tile_nw.z;

  iso_tile.vertex_buffer_vertices_data[3]  = iso_tile_ne.x;
  iso_tile.vertex_buffer_vertices_data[4]  = iso_tile_ne.y;
  iso_tile.vertex_buffer_vertices_data[5]  = iso_tile_ne.z;

  iso_tile.vertex_buffer_vertices_data[6]  = iso_tile_se.x;
  iso_tile.vertex_buffer_vertices_data[7]  = iso_tile_se.y;
  iso_tile.vertex_buffer_vertices_data[8]  = iso_tile_se.z;

  iso_tile.vertex_buffer_vertices_data[9]  = iso_tile_sw.x;
  iso_tile.vertex_buffer_vertices_data[10] = iso_tile_sw.y;
  iso_tile.vertex_buffer_vertices_data[11] = iso_tile_sw.z;

  iso_tile.vertex_buffer_colors_data[0]  = color.r;
  iso_tile.vertex_buffer_colors_data[1]  = color.g;
  iso_tile.vertex_buffer_colors_data[2]  = color.b;
  iso_tile.vertex_buffer_colors_data[3]  = color.r;
  iso_tile.vertex_buffer_colors_data[4]  = color.g;
  iso_tile.vertex_buffer_colors_data[5]  = color.b;
  iso_tile.vertex_buffer_colors_data[6]  = color.r;
  iso_tile.vertex_buffer_colors_data[7]  = color.g;
  iso_tile.vertex_buffer_colors_data[8]  = color.b;
  iso_tile.vertex_buffer_colors_data[9]  = color.r;
  iso_tile.vertex_buffer_colors_data[10] = color.g;
  iso_tile.vertex_buffer_colors_data[11] = color.b;

  // Line vertices
  iso_tile.line_buffer_vertices_data[0]  = iso_tile_nw.x;
  iso_tile.line_buffer_vertices_data[1]  = iso_tile_nw.y;
  iso_tile.line_buffer_vertices_data[2]  = iso_tile_nw.z;

  iso_tile.line_buffer_vertices_data[3]  = iso_tile_ne.x;
  iso_tile.line_buffer_vertices_data[4]  = iso_tile_ne.y;
  iso_tile.line_buffer_vertices_data[5]  = iso_tile_ne.z;

  iso_tile.line_buffer_vertices_data[6]  = iso_tile_sw.x;
  iso_tile.line_buffer_vertices_data[7]  = iso_tile_sw.y;
  iso_tile.line_buffer_vertices_data[8]  = iso_tile_sw.z;

  iso_tile.line_buffer_vertices_data[9]  = iso_tile_se.x;
  iso_tile.line_buffer_vertices_data[10] = iso_tile_se.y;
  iso_tile.line_buffer_vertices_data[11] = iso_tile_se.z;

  // Line colors
  iso_tile.line_buffer_colors_data[0]  = outline_color.r;
  iso_tile.line_buffer_colors_data[1]  = outline_color.g;
  iso_tile.line_buffer_colors_data[2]  = outline_color.b;
  iso_tile.line_buffer_colors_data[3]  = outline_color.r;
  iso_tile.line_buffer_colors_data[4]  = outline_color.g;
  iso_tile.line_buffer_colors_data[5]  = outline_color.b;
  iso_tile.line_buffer_colors_data[6]  = outline_color.r;
  iso_tile.line_buffer_colors_data[7]  = outline_color.g;
  iso_tile.line_buffer_colors_data[8]  = outline_color.b;
  iso_tile.line_buffer_colors_data[9]  = outline_color.r;
  iso_tile.line_buffer_colors_data[10] = outline_color.g;
  iso_tile.line_buffer_colors_data[11] = outline_color.b;

  create_iso_tile_buffers(iso_tile);
}

render_iso_tile :: (iso_tile: *IsoTile) {
  // Enabling attrib arrays
  glEnableVertexAttribArray(0);
  glEnableVertexAttribArray(1);

  // Binding buffers - REAL vertices
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_vertices);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)0);

  // Binding buffers - REAL colors
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_colors);
  glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)0);

  // Draw arrays call - first triangle
  glDrawArrays(GL_TRIANGLES, 0, 3);


  // Bind buffers - vertices - now with offset
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_vertices);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)(3 * size_of(GLfloat)));

  // Bind buffers - colors - now with offset
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_colors);
  glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)(3 * size_of(GLfloat)));

  // Draw arrays call - second triangle
  glDrawArrays(GL_TRIANGLES, 0, 3);
  
  // Draw lines - different primitive
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.line_buffer_vertices);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)0);

  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.line_buffer_colors);
  glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)0);

  glDrawArrays(GL_LINE_LOOP, 0, 4);

  // Disabling attrib arrays
  glDisableVertexAttribArray(0);
  glDisableVertexAttribArray(1);
}
