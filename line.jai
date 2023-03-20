#import "GL";
#import "Math";

Line :: struct {
  start       : Vector3;
  end         : Vector3;
  start_color : Vector3;
  end_color   : Vector3;

  line_vbo_vertex : GLuint;
  line_vbo_colors : GLuint;

  line_data_vertex : [2]Vector3;
  line_data_colors : [2]Vector3;
}

create_line_buffers :: (line: *Line) {

  glGenBuffers(1, *line.line_vbo_vertex);
  glBindBuffer(GL_ARRAY_BUFFER, line.line_vbo_vertex);
  glBufferData(GL_ARRAY_BUFFER, size_of(type_of(line.line_data_vertex)), *line.line_data_vertex, GL_DYNAMIC_DRAW);

  glGenBuffers(1, *line.line_vbo_colors);
  glBindBuffer(GL_ARRAY_BUFFER, line.line_vbo_colors);
  glBufferData(GL_ARRAY_BUFFER, size_of(type_of(line.line_data_colors)), *line.line_data_colors, GL_DYNAMIC_DRAW);
}

populate_line :: (line: *Line, start: Vector3, end: Vector3, start_color: Vector3, end_color: Vector3) {
  line.start       = start;
  line.end         = end;
  line.start_color = start_color;
  line.end_color   = end_color;

  line.line_data_vertex[0] = start;
  line.line_data_vertex[1] = end;

  line.line_data_colors[0] = start_color;
  line.line_data_colors[1] = end_color;

  create_line_buffers(line);
}

draw_line :: (line: *Line) {
  glEnableVertexAttribArray(0);
  glEnableVertexAttribArray(1);

  glBindBuffer(GL_ARRAY_BUFFER, line.line_vbo_vertex);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)0);

  glBindBuffer(GL_ARRAY_BUFFER, line.line_vbo_colors);
  glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)0);

  glDrawArrays(GL_LINES, 0, 2);
  
  glDisableVertexAttribArray(0);
  glDisableVertexAttribArray(1);
}

