#import "GL";

Triangle :: struct {
  vertices_data : [9]GLfloat = GLfloat.[-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0];
  color_data : [9]GLfloat = GLfloat.[1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0];

  vbo_vert : GLuint;
  vbo_color : GLuint;
}

render_triangle :: (using triangle: *Triangle) {
  glEnableVertexAttribArray(0);
  glEnableVertexAttribArray(1);

  glBindBuffer(GL_ARRAY_BUFFER, vbo_vert);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)0);

  glBindBuffer(GL_ARRAY_BUFFER, vbo_color);
  glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)0);

  glDrawArrays(GL_TRIANGLES, 0, 3);
  
  glDisableVertexAttribArray(0);
  glDisableVertexAttribArray(1);
  
}

create_buffers :: (using triangle: *Triangle) {
  glGenBuffers(1, *vbo_vert);
  glBindBuffer(GL_ARRAY_BUFFER, vbo_vert);
  glBufferData(GL_ARRAY_BUFFER, size_of(type_of(vertices_data)), vertices_data.data, GL_STATIC_DRAW);

  glGenBuffers(1, *vbo_color);
  glBindBuffer(GL_ARRAY_BUFFER, vbo_color);
  glBufferData(GL_ARRAY_BUFFER, size_of(type_of(color_data)), color_data.data, GL_STATIC_DRAW);

  print("Vbo vert: %\n", vbo_vert);
  print("Vbo color: %\n", vbo_color);
}

