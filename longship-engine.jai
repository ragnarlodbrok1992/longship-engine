// Basic JAI import
#import "Basic";

// Global JAI imports
#import "Window_Creation";
#import "Input";
#import "Math";
#import "SDL";
#import "GL";

// Local engine imports


// Engine variables
QUIT := false;
MAIN_ENGINE_WINDOW : *void;

WINDOW_TITLE_BAR : *u8 = "Longship Engine";
WINDOW_WIDTH : s32 = 1024;
WINDOW_HEIGHT : s32 = 768;

CONTROL_CAMERA : bool = true;

X_LINE_COLOR : Vector3 = .{1.0, 0.0, 0.0};
Y_LINE_COLOR : Vector3 = .{0.0, 1.0, 0.0};
Z_LINE_COLOR : Vector3 = .{0.0, 0.0, 1.0};

ISO_TILESET_WIDTH := 100;
ISO_TILESET_HEIGHT := 100;
ISO_TILE_WIDTH := 1.0;
ISO_TILE_HEIGHT := 1.0;
ISO_TILESET_X := -50.0;
ISO_TILESET_Z := -50.0;

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

Camera :: struct
{
	FLY_SPEED :: 10.0;
	ROTATION_SPEED :: 0.3;
	ROTATION_SMOOTHING :: 0.3;

  move_input_keyboard : Vector3;
  mouse_delta_input : Vector2;

	position : Vector3;
	euler_angles : Vector3;
	rotation : Quaternion;
	rotation_input : Vector2;
	fov := 60.0;
	transform := Matrix4_Identity;
	view_matrix := Matrix4_Identity;
	projection_matrix := Matrix4_Identity;
	view_projection_matrix := Matrix4_Identity;
}

update_flying_camera :: (using camera : *Camera, delta_time : float)
{
	move_speed : float;
        move_input := move_input_keyboard;
        mouse_delta := mouse_delta_input;

	if CONTROL_CAMERA {
		move_speed = FLY_SPEED;
		move_speed *= delta_time;
		move_input = rotate (unit_vector (move_input), rotation);
	}
	position += move_input * move_speed;

	rotation_input = lerp (rotation_input, mouse_delta, ROTATION_SMOOTHING);
	delta := rotation_input * ROTATION_SPEED;
	euler_angles.x += delta.x * PI / 180.0;
	euler_angles.y += delta.y * PI / 180.0;
	euler_angles.y = clamp (euler_angles.y, -80.0  * PI / 180.0, 80.0 * PI / 180.0);
	yaw : Quaternion;
	// I am not sure why I need to invert the axis of rotation...
	set_from_axis_and_angle (*yaw, 0, -1, 0, euler_angles.x);
	pitch : Quaternion;
	set_from_axis_and_angle (*pitch, -1, 0, 0, euler_angles.y);
	rotation = yaw * pitch;

	transform = make_translation_matrix4 (position) * rotation_matrix (Matrix4, rotation);
	view_matrix = inverse (transform);
	// vx, vy, vw, vh := get_dimensions (g_window, false);
	aspect_ratio := WINDOW_WIDTH / cast (float) WINDOW_HEIGHT;
	projection_matrix = make_projection_matrix (fov * PI / 180.0, aspect_ratio, 0.1, 1000.0);
	view_projection_matrix = projection_matrix * view_matrix;
}

Cube :: struct {
  vertices_data : [6 * 3 * 6]GLfloat = GLfloat.[
    -0.5, -0.5, -0.5,
     0.5, -0.5, -0.5,
     0.5,  0.5, -0.5,
     0.5,  0.5, -0.5,
    -0.5,  0.5, -0.5,
    -0.5, -0.5, -0.5,

    -0.5, -0.5,  0.5,
     0.5, -0.5,  0.5,
     0.5,  0.5,  0.5,
     0.5,  0.5,  0.5,
    -0.5,  0.5,  0.5,
    -0.5, -0.5,  0.5,

    -0.5,  0.5,  0.5,
    -0.5,  0.5, -0.5,
    -0.5, -0.5, -0.5,
    -0.5, -0.5, -0.5,
    -0.5, -0.5,  0.5,
    -0.5,  0.5,  0.5,

     0.5,  0.5,  0.5,
     0.5,  0.5, -0.5,
     0.5, -0.5, -0.5,
     0.5, -0.5, -0.5,
     0.5, -0.5,  0.5,
     0.5,  0.5,  0.5,

    -0.5, -0.5, -0.5,
     0.5, -0.5, -0.5,
     0.5, -0.5,  0.5,
     0.5, -0.5,  0.5,
    -0.5, -0.5,  0.5,
    -0.5, -0.5, -0.5,

    -0.5,  0.5, -0.5,
     0.5,  0.5, -0.5,
     0.5,  0.5,  0.5,
     0.5,  0.5,  0.5,
    -0.5,  0.5,  0.5,
    -0.5,  0.5, -0.5,
  ];
  color_data : [6 * 3 * 6]GLfloat = GLfloat.[
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,

    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,

    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,

    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,

    // Bottom
    1.0, 0.0, 0.0,
    1.0, 0.0, 0.0,
    1.0, 0.0, 0.0,
    1.0, 0.0, 0.0,
    1.0, 0.0, 0.0,
    1.0, 0.0, 0.0,

    // Top
    0.0, 1.0, 0.0,
    0.0, 1.0, 0.0,
    0.0, 1.0, 0.0,
    0.0, 1.0, 0.0,
    0.0, 1.0, 0.0,
    0.0, 1.0, 0.0,
  ];

  vbo_vert : GLuint;
  vbo_color : GLuint;
}

Triangle :: struct {
  vertices_data : [9]GLfloat = GLfloat.[-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0];
  color_data : [9]GLfloat = GLfloat.[1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0];

  vbo_vert : GLuint;
  vbo_color : GLuint;
}

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

// Shaders - for now here
VERTEX_SHADER :: #string GLSL
  #version 460 core
  layout(location = 0) in vec3 vertexPosition_modelspace;
  layout(location = 1) in vec3 vertexColor;

  out vec3 fragmentColor;
  
  uniform mat4 u_view_projection;

  void main() {
      gl_Position = u_view_projection * vec4(vertexPosition_modelspace, 1);

      fragmentColor = vertexColor;
  }
GLSL

FRAGMENT_SHADER :: #string GLSL
  #version 460 core

  in vec3 fragmentColor;

  out vec3 color;

  void main() {
    color = fragmentColor;
  }
GLSL

load_shaders :: () -> GLuint {
  // Right now loading shaders from local strings
  // No error path if something goes wrong
  // Just prints

  program_id : GLuint;
  shader_program : GLuint;
  vertex_shader_id : GLuint;
  fragment_shader_id : GLuint;
  result_vertex : GLint;
  result_fragment : GLint;
  result_program : GLint;
  info_log_length_vertex : s32;
  info_log_length_fragment : s32;
  info_log_length_program : s32;

  shader_program = glCreateProgram();
  vertex_shader_id = glCreateShader(GL_VERTEX_SHADER);
  fragment_shader_id = glCreateShader(GL_FRAGMENT_SHADER);

  glShaderSource(vertex_shader_id, 1, *to_c_string(VERTEX_SHADER), null);
  glCompileShader(vertex_shader_id);

  glGetShaderiv(vertex_shader_id, GL_COMPILE_STATUS, *result_vertex);
  glGetShaderiv(vertex_shader_id, GL_INFO_LOG_LENGTH, *info_log_length_vertex);

  // @TODO ragnar: add checking for errors
  if (info_log_length_vertex > 0) {
    vertex_shader_error_log : [512]u8;
    glGetShaderInfoLog(vertex_shader_id, cast(u32)info_log_length_vertex, null, cast(*GLchar) *vertex_shader_error_log);
    print("%\n", cast(string) vertex_shader_error_log);
  }

  glShaderSource(fragment_shader_id, 1, *to_c_string(FRAGMENT_SHADER), null);
  glCompileShader(fragment_shader_id);

  glGetShaderiv(fragment_shader_id, GL_COMPILE_STATUS, *result_fragment);
  glGetShaderiv(fragment_shader_id, GL_INFO_LOG_LENGTH, *info_log_length_fragment);

  // @TODO ragnar: add checking for errors
  if (info_log_length_fragment > 0) {
    fragment_shader_error_log : [512]u8;
    glGetShaderInfoLog(fragment_shader_id, cast(u32)info_log_length_fragment, null, cast(*GLchar) *fragment_shader_error_log);
    print("%\n", cast(string) fragment_shader_error_log);
  }

  // Creating and attaching compiled shaders to program
  program_id = glCreateProgram();
  glAttachShader(program_id, vertex_shader_id);
  glAttachShader(program_id, fragment_shader_id);
  glLinkProgram(program_id);

  glGetProgramiv(program_id, GL_LINK_STATUS, *result_program);
  glGetProgramiv(program_id, GL_INFO_LOG_LENGTH, *info_log_length_program);

  // @TODO ragnar: add checking for errors
  if (info_log_length_program > 0) {
    program_error_log : string;
    glGetProgramInfoLog(program_id, cast(u32)info_log_length_fragment, null, to_c_string(program_error_log));
    print("%\n", program_error_log);
  }

  // Now we can detach and delete shaders
  glDetachShader(program_id, vertex_shader_id);
  glDetachShader(program_id, fragment_shader_id);

  glDeleteShader(vertex_shader_id);
  glDeleteShader(fragment_shader_id);

  return program_id;
}

// Helper function
print_mat4 :: (name: string, mat: Matrix4) {
  print("  [ % ]\n", name);
  print("[%, %, %, %]\n",   mat._11, mat._12, mat._13, mat._14); 
  print("[%, %, %, %]\n",   mat._21, mat._22, mat._23, mat._24); 
  print("[%, %, %, %]\n",   mat._31, mat._32, mat._33, mat._34); 
  print("[%, %, %, %]\n\n", mat._41, mat._42, mat._43, mat._44); 
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

render_cube :: (using cube: *Cube) {
  glEnableVertexAttribArray(0);
  glEnableVertexAttribArray(1);

  glBindBuffer(GL_ARRAY_BUFFER, vbo_vert);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)0);

  glBindBuffer(GL_ARRAY_BUFFER, vbo_color);
  glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)0);

  glDrawArrays(GL_TRIANGLES, 0, 3 * 6 * 6);
  
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

create_buffers :: (using cube: *Cube) {
  glGenBuffers(1, *vbo_vert);
  glBindBuffer(GL_ARRAY_BUFFER, vbo_vert);
  glBufferData(GL_ARRAY_BUFFER, size_of(type_of(vertices_data)), vertices_data.data, GL_STATIC_DRAW);

  glGenBuffers(1, *vbo_color);
  glBindBuffer(GL_ARRAY_BUFFER, vbo_color);
  glBufferData(GL_ARRAY_BUFFER, size_of(type_of(color_data)), color_data.data, GL_STATIC_DRAW);

  print("Vbo vert: %\n", vbo_vert);
  print("Vbo color: %\n", vbo_color);
}


main :: () {
  print("Longship engine - CUBE test.\n");
  
  // Debug prints - import path
  // DEBUG - filepath?
  // print("import path: %\n", import_path);
  print("Filepath: %\n", #filepath);

  // Some start stuff
  #if OS == .WINDOWS {
    win32 :: #import "Windows";
    win32.SetProcessDPIAware();
  }

  // Getting command line arguments
  args := get_command_line_arguments();
  if (args.count > 1) {
    for args {
      if (it_index == 0) continue;
      // @TODO ragnar: add switch for program arguments
      // @TODO ragnar: add struct for program control variables
      print("Additional argument: %\n", it);
    }
  }

  // Engine initialization
  SDL_Init(SDL_INIT_VIDEO);

  MAIN_ENGINE_WINDOW := SDL_CreateWindow(WINDOW_TITLE_BAR, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, xx WINDOW_WIDTH, xx WINDOW_HEIGHT, SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE);
  print("Main engine window: %, type_of: %\n", MAIN_ENGINE_WINDOW, type_of(MAIN_ENGINE_WINDOW));
  if MAIN_ENGINE_WINDOW == null {
    print("Could not create window: %\n", to_string(SDL_GetError()));
    return;
  }

  SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);

  gl_context := SDL_GL_CreateContext(MAIN_ENGINE_WINDOW);

  if !gl_context {
    print("Could not create OpenGL context: %\n", to_string(SDL_GetError()));
    return;
  }

  gl_load(*gl, SDL_GL_GetProcAddress);
  using gl;
  
  print("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
  print("GL Version = %\n", to_string(glGetString(GL_VERSION)));

  // Setting up OpenGL
  glEnable(GL_DEPTH_TEST);

  // Defering stuff
  defer SDL_DestroyWindow(MAIN_ENGINE_WINDOW);
  defer SDL_Quit();

  // Time variables
  delta_time := 0.01667; // Assuming 60 FPS

  // Create vao for lines and cube
  vao : GLuint;
  glGenVertexArrays(1, *vao);
  glBindVertexArray(vao);

  // Create shader program
  program_id := load_shaders();

  // Get uniform location
  view_projection_matrix_id := glGetUniformLocation(program_id, "u_view_projection");

  // Create camera
  flying_camera : Camera;
  space_pushed := false;
  mouse_delta : Vector2;

  flying_camera.position = xyz (1, 1.3, 2.3);
  flying_camera.euler_angles.x = 0 * PI / 180.0;
  flying_camera.euler_angles.y = 0 * PI / 180.0;

  // Create test cube
  test_cube := New(Cube);

  // Create test triangle buffers
  create_buffers(test_cube);

  // Create lines (x y and z axis)
  x_lines          := New([21]Line);
  x_lines_parallel := New([21]Line);
  y_lines          := New([21]Line);
  y_lines_parallel := New([21]Line);
  z_lines          := New([21]Line);
  z_lines_parallel := New([21]Line);
  
  x_line_debug := New(Line);
  populate_line(x_line_debug, .{-100.0, 5.0, 0.0}, .{100.0, 5.0, 0.0}, X_LINE_COLOR, X_LINE_COLOR);
  x_line_debug_z_plus := New(Line);
  populate_line(x_line_debug_z_plus, .{-100.0, 5.0, 10.0}, .{100.0, 5.0, 10.0}, X_LINE_COLOR, X_LINE_COLOR);
  x_line_debug_z_minus := New(Line);
  populate_line(x_line_debug_z_minus, .{-100.0, 5.0, -5.0}, .{100.0, 5.0, -5.0}, X_LINE_COLOR, X_LINE_COLOR);

  x_lines_view : []Line;
  x_lines_parallel_view : []Line;
  y_lines_view : []Line;
  y_lines_parallel_view : []Line;
  z_lines_view : []Line;
  z_lines_parallel_view : []Line;

  x_lines_view = <<x_lines;
  x_lines_parallel_view = <<x_lines_parallel;
  y_lines_view = <<y_lines;
  y_lines_parallel_view = <<y_lines_parallel;
  z_lines_view = <<z_lines;
  z_lines_parallel_view = <<z_lines_parallel;

  line_spacing := 1.0;

  // X plane lines
  line_spacing_start := -10.0;
  for line, i: x_lines_view {
    populate_line(*x_lines_view[i], .{-10.0, 0.0, line_spacing_start}, .{10.0, 0.0, line_spacing_start}, X_LINE_COLOR, X_LINE_COLOR);
    line_spacing_start += line_spacing;
  }

  line_spacing_start = -10.0;
  for line, i: x_lines_parallel_view {
    populate_line(*x_lines_parallel_view[i], .{line_spacing_start, 0.0, -10.0}, .{line_spacing_start, 0.0, 10.0}, X_LINE_COLOR, X_LINE_COLOR);
    line_spacing_start += line_spacing;
  }

  // Y plane lines
  line_spacing_start = -10.0;
  for line, i: y_lines_view {
    populate_line(*y_lines_view[i], .{line_spacing_start, -10.0, 0.0}, .{line_spacing_start, 10.0, 0.0}, Y_LINE_COLOR, Y_LINE_COLOR);
    line_spacing_start += line_spacing;
  }

  line_spacing_start = -10.0;
  for line, i: y_lines_parallel_view {
    populate_line(*y_lines_parallel_view[i], .{-10.0, line_spacing_start, 0.0}, .{10.0, line_spacing_start, 0.0}, Y_LINE_COLOR, Y_LINE_COLOR);
    line_spacing_start += line_spacing;
  }

  // Z plane lines
  line_spacing_start = -10.0;
  for line, i: z_lines_view {
    populate_line(*z_lines_view[i], .{0.0, line_spacing_start, -10.0}, .{0.0, line_spacing_start, 10.0}, Z_LINE_COLOR, Z_LINE_COLOR);
    line_spacing_start += line_spacing;
  }

  line_spacing_start = -10.0;
  for line, i: z_lines_parallel_view {
    populate_line(*z_lines_parallel_view[i], .{0.0, -10.0, line_spacing_start}, .{0.0, 10.0, line_spacing_start}, Z_LINE_COLOR, Z_LINE_COLOR);
    line_spacing_start += line_spacing;
  }

  // Create test iso tiles
  /*
  test_iso_tile := New(IsoTile);

  print("Test iso tile: %\n", test_iso_tile);
  print("Test iso tile dereference: %\n", <<test_iso_tile);

  populate_iso_tile(test_iso_tile, 0, .{0.3, 0.4, 0.5}, .{1.0, 1.0, 1.0}, .{2.0, 0.0, 0.0});

  print("Test iso tile dereference: %\n", <<test_iso_tile);
  */

  // Create test iso tiles
  test_iso_tiles_array := New([..]IsoTile);
  // print("Test iso tiles array: %\n", test_iso_tiles_array);

  id := 0;
  for i: 0..ISO_TILESET_WIDTH - 1 {
    for j: 0..ISO_TILESET_HEIGHT - 1 {
      // print("Adding array with indexes: i - % j - %\n", i, j);
      iso_tile := New(IsoTile);
      populate_iso_tile(iso_tile,
                        id,
                        .{i / 100.0, j / 100.0, 0.8},
                        .{1.0, 1.0, 1.0},
                        .{cast(float)ISO_TILESET_X + i * ISO_TILE_WIDTH , 0.0, cast(float)ISO_TILESET_Z + j * ISO_TILE_HEIGHT});
      id += 1;

      array_add(test_iso_tiles_array, iso_tile);
    }
  }

  // TEST - iterating over created IsoTiles
  /*
  for iso_tile, index: <<test_iso_tiles_array {
    print("Iso tile: % - index: %\n", iso_tile, index);
  }
  */
  
  while !QUIT {
    frame_start := current_time_monotonic();

    event : SDL_Event;
    while SDL_PollEvent(*event) {
      if event.type == {
        case SDL_QUIT;
          QUIT = true;
        case SDL_WINDOWEVENT;
          if event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED {
            WINDOW_WIDTH = event.window.data1;
            WINDOW_HEIGHT = event.window.data2;
          }
        case SDL_MOUSEMOTION;
          if space_pushed {
            mouse_delta_x = event.motion.xrel;
            mouse_delta_y = event.motion.yrel;
          }
        case SDL_KEYUP;
          if event.key.keysym.sym == SDLK_ESCAPE QUIT = true;

          if event.key.keysym.sym == SDLK_a then flying_camera.move_input_keyboard.x = 0.0;
          if event.key.keysym.sym == SDLK_d then flying_camera.move_input_keyboard.x = 0.0;
          if event.key.keysym.sym == SDLK_s then flying_camera.move_input_keyboard.y = 0.0;
          if event.key.keysym.sym == SDLK_w then flying_camera.move_input_keyboard.y = 0.0;
          if event.key.keysym.sym == SDLK_q then flying_camera.move_input_keyboard.z = 0.0;
          if event.key.keysym.sym == SDLK_e then flying_camera.move_input_keyboard.z = 0.0;

          if event.key.keysym.sym == SDLK_SPACE {
            space_pushed = false;
            mouse_delta_x = 0;
            mouse_delta_y = 0;
          }

        case SDL_KEYDOWN;
          if event.key.keysym.sym == SDLK_a then flying_camera.move_input_keyboard.x = -1.0;
          if event.key.keysym.sym == SDLK_d then flying_camera.move_input_keyboard.x = 1.0;
          if event.key.keysym.sym == SDLK_s then flying_camera.move_input_keyboard.y = -1.0;
          if event.key.keysym.sym == SDLK_w then flying_camera.move_input_keyboard.y = 1.0;
          if event.key.keysym.sym == SDLK_q then flying_camera.move_input_keyboard.z = -1.0;
          if event.key.keysym.sym == SDLK_e then flying_camera.move_input_keyboard.z = 1.0;

          if event.key.keysym.sym == SDLK_SPACE space_pushed = true;
      }

    }
    // Mouse
    mouse_delta = xy(xx mouse_delta_x, xx mouse_delta_y);
    // print("Mouse delta: %\n", mouse_delta);

    // Beggining of simulation/rendering loop
    glViewport(0, 0, xx WINDOW_WIDTH, xx WINDOW_HEIGHT);

    // Shader program
    glUseProgram(program_id);

    // MVP matrix
    // put view_projection_matrix from flying_camera here
    flying_camera.mouse_delta_input = mouse_delta;
    update_flying_camera(*flying_camera, delta_time);

    glUniformMatrix4fv(view_projection_matrix_id, 1, GL_TRUE, xx *flying_camera.view_projection_matrix.coef[0][0]);

    // Clear screen
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // Render test triangle
    for line, i: x_lines_parallel_view {
      draw_line(*x_lines_parallel_view[i]);
    }
    for line, i: y_lines_view {
      draw_line(*y_lines_view[i]);
    }
    for line, i: y_lines_parallel_view {
      draw_line(*y_lines_parallel_view[i]);
    }
    for line, i: x_lines_view {
      draw_line(*x_lines_view[i]);
    }
    for line, i: z_lines_view {
      draw_line(*z_lines_view[i]);
    }
    for line, i: z_lines_parallel_view {
      draw_line(*z_lines_parallel_view[i]);
    }

    // Test cube render
    render_cube(test_cube);

    // Test isotile render
    // render_iso_tile(test_iso_tile);

    for iso_tile: <<test_iso_tiles_array {
      render_iso_tile(*iso_tile);
    }

    // Swap window - end of drawing stuff
    SDL_GL_SwapWindow(MAIN_ENGINE_WINDOW);

    // Time stuff
    frame_end := current_time_monotonic();
    delta_time = cast(float) to_float64_seconds(frame_end - frame_start);
  }
  // Deleting stuff
  glDeleteProgram(program_id);
  glDeleteVertexArrays(1, *vao);
}
