#import "Basic";

#import "Window_Creation";
#import "Input";
#import "Math";
#import "SDL";
#import "GL";

// Engine structs
CameraControls :: struct {
  move_input_x: float;
  move_input_y: float;
  move_input_z: float;
}

// Engine variables
is_camera_active : bool;
camera_controls : CameraControls;
mouse_delta : Vector2;

//  line_vao : GLuint;

MAIN_ENGINE_WINDOW : *void;

// Shaders - for now here
VERTEX_SHADER :: #string GLSL
  #version 460 core
  layout(location = 0) in vec3 vertexPosition_modelspace;
  layout(location = 1) in vec3 vertexColor;

  out vec3 fragmentColor;
  
  uniform mat4 MVP;

  void main() {
      gl_Position = MVP * vec4(vertexPosition_modelspace, 1);

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

// Engine internal variables
QUIT := false;

WINDOW_TITLE_BAR : *u8 = "Longship Engine";
WINDOW_WIDTH : s32 = 1024;
WINDOW_HEIGHT : s32 = 768;

// @TODO ragnar: create a grid of isotiles
ISO_TILESET_WIDTH := 1000;
ISO_TILESET_HEIGHT := 1000;
ISO_TILE_WIDTH := 10;
ISO_TILE_HEIGHT := 10;
ISO_TILESET_X := 0;
ISO_TILESET_Y := 0;

// @DEBUG
// DEGREES := 0;

// Define structs
Color :: struct {
  r: u8;
  g: u8;
  b: u8;
  a: u8;
}

Point :: struct {
  x: int;
  y: int;
}

PointF :: struct {
  x: float;
  y: float;
}

/*
Line :: struct {
  start: Point;
  end: Point;
}
*/

OGLColor :: struct {
  r: GLfloat;
  g: GLfloat;
  b: GLfloat;
}

OGLPoint :: struct {
  x: GLfloat;
  y: GLfloat;
  z: GLfloat; // Sticking to one plane for now
}

// @NOTE stolen code from skeletal-animation (or inspiration, whatever)
Camera :: struct {
  FLY_SPEED :: 10.0;
  ROTATION_SPEED :: 0.003;
  ROTATION_SMOOTHING :: 0.3;
  FOV := 60.0; // For now we stick with normal projection - switching to orthogonal after camera will finally work
  // ASPECT_RATIO :: WINDOW_WIDTH / WINDOW_HEIGHT;

  model_matrix := Matrix4_Identity;
  model_yaw : Quaternion;
  model_pitch : Quaternion;
  model_roll : Quaternion;
  // model_rotation_quat : Quaternion;
  model_rotation : Quaternion;

  model_translate_vector : Vector3 = .{0.0, 0.0, 0.0}; // Not translating right now anything
  model_scale_vector : Vector3 = .{1.0, 1.0, 1.0}; // Not scaling right now anything
  model_euler_angles : Vector3 = .{1 * PI / 180, 1 * PI / 180, 1 * PI / 180} ;

  // view_translate_vector : Vector3;
  // view_rotation_input : Vector2; // I think yaw and pitch - we do not roll here
  // view_euler_angles : Vector2; // We are rotating around two axis x and y. We do not roll on z.
  // view_rotation_quat : Quaternion;

  view_matrix := Matrix4_Identity;
  view_yaw : Quaternion;
  view_pitch : Quaternion;
  view_roll : Quaternion;
  view_rotation : Quaternion;

  view_translate_vector : Vector3 = .{0.0, 0.0, -10.0}; // Moving back with z
  // view_scale_vector : Vector3 = .{
  view_euler_angles : Vector3 = .{0 * PI / 180, 0 * PI / 180, 0 * PI / 180};

  projection_matrix := Matrix4_Identity;

  // This matrix goes to shader - it's output from updating camera
  model_view_projection_matrix := Matrix4_Identity;
}
  
IsoTile :: struct {
  id: int;

  // OpenGL stuff
  nw: OGLPoint;
  ne: OGLPoint;
  se: OGLPoint;
  sw: OGLPoint;

  // Colors - one color for each point to keep things simple for now
  color_nw: OGLColor;
  color_ne: OGLColor;
  color_se: OGLColor;
  color_sw: OGLColor;

  // OpenGL Buffers - ids
  // Final version - only 4 points required
  // @improvement we will just offset second triangle
  // and be fine about it
  vertex_buffer_vertices : GLuint;
  vertex_buffer_colors   : GLuint;
  line_buffer_vertices   : GLuint;
  line_buffer_colors     : GLuint;

  // OpenGL Buffers - containers
  // Final version - only 4 points required
  // @improvement we will just offset second triangle
  // and be fine about it
  vertex_buffer_vertices_data : [12]GLfloat;
  vertex_buffer_colors_data   : [12]GLfloat;
  line_buffer_colors_data     : [12]GLfloat;
  line_buffer_vertices_data   : [12]GLfloat;
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

  print("Buffers - vertices: %, colors: %, line colors: %\n", iso_tile.vertex_buffer_vertices, iso_tile.vertex_buffer_colors, iso_tile.line_buffer_colors);
}

populate_iso_tile :: (iso_tile: *IsoTile) {
  // @TODO ragnar: parametrize, rn hardcoded
  iso_tile.id = 0;

  // @hardcore - vertices
  iso_tile.nw = .{cast(float) -ISO_TILE_WIDTH, cast(float)  ISO_TILE_HEIGHT, 0};
  iso_tile.ne = .{cast(float)  ISO_TILE_WIDTH, cast(float)  ISO_TILE_HEIGHT, 0};
  iso_tile.se = .{cast(float)  ISO_TILE_WIDTH, cast(float) -ISO_TILE_HEIGHT, 0};
  iso_tile.sw = .{cast(float) -ISO_TILE_WIDTH, cast(float) -ISO_TILE_HEIGHT, 0};

  // iso_tile.nw = .{10.0, 1.0, 0.0};
  // iso_tile.ne = .{10.0, 10.0, 0.0};
  // iso_tile.se = .{1.0, 10.0, 0.0};
  // iso_tile.sw = .{1.0, 1.0, 0.0};

  print("iso tile nw: %\n", iso_tile.nw);
  print("iso tile ne: %\n", iso_tile.ne);
  print("iso tile se: %\n", iso_tile.se);
  print("iso tile sw: %\n", iso_tile.sw);

  // @hardcode - colors
  iso_tile.color_nw = .{1.0,   0,   0};
  iso_tile.color_ne = .{  0, 1.0,   0};
  iso_tile.color_se = .{1.0, 1.0, 1.0};
  iso_tile.color_sw = .{  0,   0, 1.0};

  // Putting vertices and color data in correct order
  iso_tile.vertex_buffer_vertices_data[0]  = iso_tile.nw.x;
  iso_tile.vertex_buffer_vertices_data[1]  = iso_tile.nw.y;
  iso_tile.vertex_buffer_vertices_data[2]  = iso_tile.nw.z;
  iso_tile.vertex_buffer_vertices_data[3]  = iso_tile.sw.x;
  iso_tile.vertex_buffer_vertices_data[4]  = iso_tile.sw.y;
  iso_tile.vertex_buffer_vertices_data[5]  = iso_tile.sw.z;
  iso_tile.vertex_buffer_vertices_data[6]  = iso_tile.ne.x;
  iso_tile.vertex_buffer_vertices_data[7]  = iso_tile.ne.y;
  iso_tile.vertex_buffer_vertices_data[8]  = iso_tile.ne.z;
  iso_tile.vertex_buffer_vertices_data[9]  = iso_tile.se.x;
  iso_tile.vertex_buffer_vertices_data[10] = iso_tile.se.y;
  iso_tile.vertex_buffer_vertices_data[11] = iso_tile.se.z;

  iso_tile.vertex_buffer_colors_data[0]  = iso_tile.color_nw.r;
  iso_tile.vertex_buffer_colors_data[1]  = iso_tile.color_nw.g;
  iso_tile.vertex_buffer_colors_data[2]  = iso_tile.color_nw.b;
  iso_tile.vertex_buffer_colors_data[3]  = iso_tile.color_sw.r;
  iso_tile.vertex_buffer_colors_data[4]  = iso_tile.color_sw.g;
  iso_tile.vertex_buffer_colors_data[5]  = iso_tile.color_sw.b;
  iso_tile.vertex_buffer_colors_data[6]  = iso_tile.color_ne.r;
  iso_tile.vertex_buffer_colors_data[7]  = iso_tile.color_ne.g;
  iso_tile.vertex_buffer_colors_data[8]  = iso_tile.color_ne.b;
  iso_tile.vertex_buffer_colors_data[9]  = iso_tile.color_se.r;
  iso_tile.vertex_buffer_colors_data[10] = iso_tile.color_se.g;
  iso_tile.vertex_buffer_colors_data[11] = iso_tile.color_se.b;

  // Line vertices
  iso_tile.line_buffer_vertices_data[0]  = iso_tile.nw.x;
  iso_tile.line_buffer_vertices_data[1]  = iso_tile.nw.y;
  iso_tile.line_buffer_vertices_data[2]  = iso_tile.nw.z;
  iso_tile.line_buffer_vertices_data[3]  = iso_tile.ne.x;
  iso_tile.line_buffer_vertices_data[4]  = iso_tile.ne.y;
  iso_tile.line_buffer_vertices_data[5]  = iso_tile.ne.z;
  iso_tile.line_buffer_vertices_data[6]  = iso_tile.se.x;
  iso_tile.line_buffer_vertices_data[7]  = iso_tile.se.y;
  iso_tile.line_buffer_vertices_data[8]  = iso_tile.se.z;
  iso_tile.line_buffer_vertices_data[9]  = iso_tile.sw.x;
  iso_tile.line_buffer_vertices_data[10] = iso_tile.sw.y;
  iso_tile.line_buffer_vertices_data[11] = iso_tile.sw.z;

  // Line colors
  iso_tile.line_buffer_colors_data[0]  = 1.0;
  iso_tile.line_buffer_colors_data[1]  = 1.0;
  iso_tile.line_buffer_colors_data[2]  = 1.0;
  iso_tile.line_buffer_colors_data[3]  = 1.0;
  iso_tile.line_buffer_colors_data[4]  = 1.0;
  iso_tile.line_buffer_colors_data[5]  = 1.0;
  iso_tile.line_buffer_colors_data[6]  = 1.0;
  iso_tile.line_buffer_colors_data[7]  = 1.0;
  iso_tile.line_buffer_colors_data[8]  = 1.0;
  iso_tile.line_buffer_colors_data[9]  = 1.0;
  iso_tile.line_buffer_colors_data[10] = 1.0;
  iso_tile.line_buffer_colors_data[11] = 1.0;

  // In the end - create buffers
  create_iso_tile_buffers(iso_tile);

}

modify_vertex_buffer :: (iso_tile: *IsoTile) {
  glBindBuffer(GL_ARRAY_BUFFER, iso_tile.vertex_buffer_vertices);
  glBufferSubData(GL_ARRAY_BUFFER, 2 * size_of(GLfloat), size_of(GLfloat), *iso_tile.vertex_buffer_vertices_data[2]);
  print("Buffer vertices data: %\n", iso_tile.vertex_buffer_vertices_data);
}

move_corner_up_or_down :: (iso_tile: *IsoTile, adding: GLfloat) {
  // iso_tile.nw.z += adding;
  iso_tile.vertex_buffer_vertices_data[2] += adding;

  // Calling creating buffers
  // create_iso_tile_buffers(iso_tile);
  // @TODO: how to modify current buffer?
  modify_vertex_buffer(iso_tile);
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

// Define some colors
BLACK : OGLColor = .{0, 0, 0};
RED : OGLColor = .{1.0, 0, 0};
GREEN : OGLColor = .{0, 1.0, 0};
BLUE : OGLColor = .{0, 0, 1.0};
KHAKI : OGLColor = .{0.941, 0.901, 0.549};
DARK_KHAKI : OGLColor = .{0.741, 0.7176, 0.419};

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

create_projection_matrix :: (angle_of_view: float, aspect_ratio: float, near: float, far: float) -> Matrix4 {
  return_matrix := Matrix4_Identity;

  print("tan(angle_of_view / 2): %\n", tan(angle_of_view / 2));
  print("aspect_ratio: %\n", aspect_ratio);

  return_matrix._11 = 1 / (aspect_ratio * tan(angle_of_view / 2));

  return_matrix._22 = 1 / tan(angle_of_view / 2);

  return_matrix._33 = -((far + near) / (far - near));

  return_matrix._34 = -((2 * far * near) / (far - near));

  return_matrix._43 = -1;
  return_matrix._44 = 0;

  return return_matrix;
}

/*
create_projection_matrix :: (angle_of_view: float, aspect_ratio: float, near: float, far: float) -> Matrix4 {
  return_matrix := Matrix4_Identity;
  r, l, t, b: float;

  scale := tan(angle_of_view * 0.5 * PI / 180) * near;
  r = aspect_ratio * scale;
  l = -r;
  t = scale;
  b = -t;

  return_matrix._11 = 2 * near / (r - l);
  return_matrix._12 = 0;
  return_matrix._13 = 0;
  return_matrix._14 = 0;

  return_matrix._21 = 0;
  return_matrix._22 = 2 * near / (t - b);
  return_matrix._23 = 0;
  return_matrix._24 = 0;

  return_matrix._31 = (r + l) / (r - l);
  return_matrix._32 = (t + b) / (t - b);
  return_matrix._33 = -(far + near) / (far - near);
  return_matrix._34 = -1;

  return_matrix._41 = 0;
  return_matrix._42 = 0;
  return_matrix._43 = -2 * far * near / (far - near); 
  return_matrix._44 = 0;

  return return_matrix;
}
*/

update_camera :: (using camera: *Camera, camera_controls: *CameraControls, delta_time: float) {
  // Check inputs
  // print("Camera controls: %\n", <<camera_controls);
  // print("Mouse delta: %\n", mouse_delta);
  // Inputs are ok

  // @NOTES let's think about it
  // How it is done in OpenGL and in graphics general.
  // Lets start with path that matrices need to follow in order
  // to achieve what we see in games today.
  // Translation -> Rotation -> Scale
  // Or should it be Scale -> Translate -> Rotate?
  // Let's try that
  // Model Coordinates - our input from OpenGL <- We just push MVP matrix there
  // Model Matrix <- Scale, transform and rotation of objects
  // After this we have object in world coordinates
  // Object is scaled, rotated and moved.
  // Now we proceed to View Matrix.
  // After that we have Camera Coordinates - object in relation to camera.
  // Last thing is to apply Projection Matrix to whole thing.

  // In GLM function lookAt generates specific View matrix

  // @TODO stuff that needs to be done
  // 1. Create model matrix
  //   a. Create scaling
  //   b. Create translation
  //   c. Create rotation of objects

  // @NOTE OpenGL tutorial 

  // 1a.
  model_matrix._11 = model_scale_vector.x;
  model_matrix._22 = model_scale_vector.y;
  model_matrix._33 = model_scale_vector.z;

  // print_mat4("Model", model);
  // 1b. Translation moves object in space - it's different than moving camera away from (0, 0, 0)
  // center of our OpenGL universe
  model_matrix._14 = model_translate_vector.x;
  model_matrix._24 = model_translate_vector.y;
  model_matrix._34 = model_translate_vector.z;

  // print_mat4("Model", model);
  // set_from_axis_and_angle(*model_pitch, -1, 0, 0, model_euler_angles.x);
  // set_from_axis_and_angle(*model_yaw, 0, -1, 0, model_euler_angles.y);
  // set_from_axis_and_angle(*model_roll, 0, 0, -1, model_euler_angles.z);
  
  model_rotation = model_roll * model_yaw * model_pitch;

  model_matrix = model_matrix * rotation_matrix(Matrix4, model_rotation);

  // print_mat4("Model", model);
  
  view_matrix._14 = view_translate_vector.x;
  view_matrix._24 = view_translate_vector.y;
  view_matrix._34 = view_translate_vector.z;

  set_from_axis_and_angle(*view_pitch, 0, -1, 0, view_euler_angles.x);
  set_from_axis_and_angle(*view_yaw, -1, 0, 0, view_euler_angles.y);
  set_from_axis_and_angle(*view_roll, 0, 0, -1, view_euler_angles.z);

  view_rotation = view_roll * view_yaw * view_pitch;
  // view_rotation = view_yaw * view_pitch;
  print("View rotation: %\n", view_rotation);

  // view_matrix = model_matrix * rotation_matrix(Matrix4, view_rotation);
  view_matrix = view_matrix * rotation_matrix(Matrix4, view_rotation);
  // view_matrix = inverse(transform);

  // print_mat4("view", view_matrix);

  // Now we need to generate projection matrix
  aspect_ratio := WINDOW_WIDTH / cast(float) WINDOW_HEIGHT;
  projection_matrix = create_projection_matrix(FOV, cast(float) aspect_ratio, 0.1, 1000.0); // @BUG for fucks sake...

  print_mat4("Projection matrix", projection_matrix);

  model_view_projection_matrix = projection_matrix * view_matrix * model_matrix;
  
  print_mat4("MVP", model_view_projection_matrix);
}

// @FIXME 
/*
update_camera :: (using camera: *Camera, delta_time: float) {
  mouse_delta : Vector2;
  move_input  : Vector3;
  move_speed  : float;


  if is_camera_active {
    move_speed = FLY_SPEED;
    mouse_delta = xy(xx mouse_delta_x, xx mouse_delta_y); // How mouse delta ends up here?
    // print("Mouse delta: %\n", mouse_delta);
    move_speed *= delta_time;

    // Checking camera controls
    move_input.x = camera_controls.move_input_x;
    move_input.y = camera_controls.move_input_y;
    move_input.z = camera_controls.move_input_z;

    move_input = rotate(unit_vector(move_input), rotation);
  }
  position += move_input * move_speed;

  rotation_input = lerp(rotation_input, mouse_delta, ROTATION_SMOOTHING);
  delta := rotation_input * ROTATION_SPEED;

  euler_angles.x += delta.x * PI / 180.0;
  euler_angles.y += delta.y * PI / 180.0;

  // @NOTE keeping angles at zero to get transforms right
  // euler_angles.x = 0.0;
  // euler_angles.y = 0.0;

  euler_angles.y = clamp(euler_angles.y, -80.0 * PI / 180.0, 80.0 * PI / 180.0);

  // @TEST - correct stuff here (or correct?)
  yaw   : Quaternion;
  set_from_axis_and_angle(*yaw,    0, -1, 0, euler_angles.x);
  pitch : Quaternion;
  set_from_axis_and_angle(*pitch, -1,  0, 0, euler_angles.y);

  rotation = yaw * pitch;

  // Transformers are here
  // @NOTE position and rotation matrices might be fucked
  // print("Position: %\n", position);
  // print("Rotation: %\n", rotation);
  // @NOTE I think they look ok
  
  translation_matrix := make_translation_matrix4(position);
  transform = translation_matrix * rotation_matrix(Matrix4, rotation);


  view_matrix = inverse(transform);

  // print("Position: %\n", position);
  // print("Translation matrix: %\n", translation_matrix);
  // print("Transform: %\n", transform);
  // print("View matrix: %\n", view_matrix);
  print_mat4("translation_matrix", translation_matrix);
  print_mat4("transform", transform);
  print("position: %\n", position);

  vw := WINDOW_WIDTH;
  vh := WINDOW_HEIGHT;

  aspect_ratio := vw / cast(float) vh;

  // @TODO @FIXME - this projection is weird
  // lets make our own projection matrix
  projection_matrix = make_projection_matrix(fov * PI / 180.0, aspect_ratio, 0.1, 1000.0);

  // print_mat4("projection_matrix", projection_matrix);
  print_mat4("view_matrix", view_matrix);

  view_projection_matrix = projection_matrix * view_matrix;

  // view_projection_matrix = inverse(view_projection_matrix);
  
  // print_mat4("view_projection_matrix", view_projection_matrix);

  print("DEBUG END========================\n");

  //@TODO @FIXME moving camera is like rotating but with clamping - we cannot turn around
  // there are some bugs here
  // print("Move input: %\n", move_input);
  // print("Position: %\n", position);
}
*/

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

  // print("Line.line_vbo_vertex: %\n", line.line_vbo_vertex);
  // print("Line.line_vbo_colors: %\n", line.line_vbo_colors);

  // print("Drawing line: %, vbo_vertex: %\n", line, line.line_vbo_vertex);

  glBindBuffer(GL_ARRAY_BUFFER, line.line_vbo_vertex);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)0);

  glBindBuffer(GL_ARRAY_BUFFER, line.line_vbo_colors);
  glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, cast(*void)0);

  glDrawArrays(GL_LINES, 0, 2);
  
  glDisableVertexAttribArray(0);
  glDisableVertexAttribArray(1);
}

// Helper function
print_mat4 :: (name: string, mat: Matrix4) {
  print("  [ % ]\n", name);
  print("[%, %, %, %]\n",   mat._11, mat._12, mat._13, mat._14); 
  print("[%, %, %, %]\n",   mat._21, mat._22, mat._23, mat._24); 
  print("[%, %, %, %]\n",   mat._31, mat._32, mat._33, mat._34); 
  print("[%, %, %, %]\n\n", mat._41, mat._42, mat._43, mat._44); 
}

main :: () {
  // Welcoming messages
  print("Hello, longship-engine!\n");

  // Some start stuff
  #if OS == .WINDOWS {
    win32 :: #import "Windows";
    win32.SetProcessDPIAware();
  }

  // @TODO (6-3-2023) Just steal (learn and use here) some code from skeletal animation example program
  // especially transforms and cameras
  // since OpenGL is just AAAAAAAAAAAAAAAAAAAAAHHHHHHHHHHHHHHHHHHHH

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
  
  // DEBUG prints
  print("GLfloat size_of: %\n", size_of(GLfloat));

  // Defering stuff
  defer SDL_DestroyWindow(MAIN_ENGINE_WINDOW);
  defer SDL_Quit();

  // DEBUG variables - those are creating with OpenGL initialized
  // so it must be done after gl_load
  debug_iso_tile := New(IsoTile);
  populate_iso_tile(debug_iso_tile);

  // Create VAO - one per program for now - all isotiles will go there
  vertex_array_id : GLuint;
  glGenVertexArrays(1, *vertex_array_id);
  glBindVertexArray(vertex_array_id);
  
  // VAO for lines
  // glGenVertexArrays(1, *line_vao);
  // glBindVertexArray(line_vao);

  // Loading shaders
  program_id := load_shaders();

  // Getting MatrixID for MVP
  matrix_id := glGetUniformLocation(program_id, "MVP");

  // Create line buffers
  debug_line_x := New(Line);
  debug_line_y := New(Line);
  debug_line_z := New(Line);

  x_line_color : Vector3 = .{1.0, 0.0, 0.0};
  y_line_color : Vector3 =  .{0.0, 0.0, 1.0};
  z_line_color : Vector3 = .{0.0, 1.0, 0.0}; 

  populate_line(debug_line_x, .{-100.0, -10.0,     0.0}, .{100.0,  -10.0,   0.0}, x_line_color, x_line_color);
  populate_line(debug_line_y, .{0.0,    -100.0,    0.0}, .{0.0,    100.0,   0.0}, y_line_color, y_line_color);
  populate_line(debug_line_z, .{0.0,    -10.0,  -100.0}, .{0.0,    -10.0, 100.0}, z_line_color, z_line_color);

  // @TODO create array of 10 lines on X axis (-10.0 on Y) side by side
  x_lines := New([10]Line);

  // @TODO create array of 10 lines on Z axis (-10.0 on Y) side by side
  z_lines := New([10]Line);

  x_lines_view : []Line;
  x_lines_view = <<x_lines;
  z_lines_view : []Line;
  z_lines_view = <<z_lines;

  line_spacing := 10.0;
  line_spacing_start := -50.0;

  for line, i: x_lines_view {
    populate_line(*x_lines_view[i], .{-100.0, -10.0, line_spacing_start}, .{100.0, -10.0, line_spacing_start}, x_line_color, x_line_color);
    
    line_spacing_start += line_spacing;
  } 

  line_spacing_start = -50.0;

  for line, i: z_lines_view {
    populate_line(*z_lines_view[i], .{line_spacing_start, -10.0, -100.0}, .{line_spacing_start, -10.0, 100.0}, z_line_color, z_line_color);
    // populate_line(*z_lines_view[i], .{0.0, line_spacing_start, -100.0}, .{0.0, line_spacing_start, 100.0}, z_line_color, z_line_color);
    
    line_spacing_start += line_spacing;
  } 

  // Camera
  is_camera_active = true;
  main_camera : Camera;
  // main_camera.position = .{10.0, 10.0, 10.0};
  // print("%\n", main_camera);

  // Position camera in a nice way
  // main_camera.position = xyz(0.0, 0.0, 100.0);
  // main_camera.euler_angles.x = 0 * PI / 180.0;
  // main_camera.euler_angles.y = 0 * PI / 180.0;

  // @NOTE checking out if projection is correct
  // opm_left   := cast(float) -(WINDOW_WIDTH  / 2);
  // opm_right  := cast(float)  (WINDOW_WIDTH  / 2);
  // opm_bottom := cast(float) -(WINDOW_HEIGHT / 2);
  // opm_top    := cast(float)  (WINDOW_HEIGHT / 2);
  // opm_near   := 0.0;
  // opm_far    := 10000.0;

  // ref_up_x := 0.0;
  // ref_up_y := 0.0;
  // ref_up_z := 1.0;

  // Time variables
  delta_time := 0.01667;

  // Control variables
  space_pushed := false;

  // Main LongshipEngine loop
  while !QUIT {
    frame_start := current_time_monotonic();

    event : SDL_Event;
    while SDL_PollEvent(*event) {
      if event.type == {
        // Mouse events
        case SDL_MOUSEMOTION;
          // @TODO make changing of mouse only if button is pushed
          // print("Event.key.keysym.sym: %\n", event.key.keysym.sym);
          if space_pushed {
            mouse_delta_x = event.motion.xrel;
            mouse_delta_y = event.motion.yrel;
          }
        case SDL_QUIT;
          QUIT = true;
        case SDL_KEYUP;
          if event.key.keysym.sym == SDLK_SPACE {
            space_pushed = false;
            mouse_delta_x = 0;
            mouse_delta_y = 0;
          }
          if event.key.keysym.sym == SDLK_ESCAPE QUIT = true;
          if event.key.keysym.sym == SDLK_a camera_controls.move_input_x = 0.0;
          if event.key.keysym.sym == SDLK_s camera_controls.move_input_z = 0.0;
          if event.key.keysym.sym == SDLK_d camera_controls.move_input_x = 0.0;
          if event.key.keysym.sym == SDLK_q camera_controls.move_input_y = 0.0;
          if event.key.keysym.sym == SDLK_w camera_controls.move_input_z = 0.0;
          if event.key.keysym.sym == SDLK_e camera_controls.move_input_y = 0.0;
        case SDL_KEYDOWN;
          shift_modifier := 1;

          if event.key.keysym.sym == SDLK_SPACE space_pushed = true;

          if event.key.keysym.mod == KMOD_LSHIFT then shift_modifier = -1;
          if event.key.keysym.mod == KMOD_RSHIFT then shift_modifier = -1;

          if event.key.keysym.sym == SDLK_a {
            if is_camera_active camera_controls.move_input_x = 1.0;
          }
          if event.key.keysym.sym == SDLK_s {
            // translate_y += 0.01 * shift_modifier;
            // print("Translating y!\n");

            if is_camera_active camera_controls.move_input_z = -1.0;
          }
          if event.key.keysym.sym == SDLK_d {
            // translate_z += 0.01 * shift_modifier;
            // print("Translating z!\n");

            if is_camera_active camera_controls.move_input_x = -1.0;
          }
          if event.key.keysym.sym == SDLK_q {
            // DEGREES += 1 * shift_modifier;
            // print("Changing DEGREES!\n");

            if is_camera_active camera_controls.move_input_y = 1.0;
          }
          if event.key.keysym.sym == SDLK_w {
            if is_camera_active camera_controls.move_input_z = 1.0;
          }
          if event.key.keysym.sym == SDLK_e {
            if is_camera_active camera_controls.move_input_y = -1.0;
          }
          if event.key.keysym.sym == SDLK_f {
            print("Pressing f.\n");
            // print("Main camera position: %\n", main_camera.position);
            // print("Mouse delta: %\n", mouse_delta);
            // print("Main camera rotation: %\n", main_camera.rotation);
          }

        case SDL_WINDOWEVENT;
          if event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED {
            WINDOW_WIDTH = event.window.data1;
            WINDOW_HEIGHT = event.window.data2;
          }
      }
    }

    // Mouse @TEST
    mouse_delta = xy(xx mouse_delta_x, xx mouse_delta_y);
    // print("Mouse delta %\n", mouse_delta);
    // print("Mouse delta type_of: %\n", type_of(mouse_delta));

    // Rendering shit
    glViewport(0, 0, xx WINDOW_WIDTH, xx WINDOW_HEIGHT);

    // Shader program
    glUseProgram(program_id);

    // Set up camera
    // @TODO check this call where it is in skeletal animation source
    // @TODO steal whole camera structure and maybe update_flying_camera function
    // @NOTE for now leave projections and translation, rest is commented out

    // Old projection code
    // op_projection_matrix := orthographic_projection_matrix(opm_left, opm_right, opm_bottom, opm_top, opm_near, opm_far);

    // op_model_matrix := Matrix4_Identity;
    // op_model_matrix._41 = translate_x;
    // op_model_matrix._42 = translate_y;
    // op_model_matrix._43 = translate_z;

    // mvp_matrix := op_projection_matrix * op_model_matrix;

    // Camera code goes here
    update_camera(*main_camera, *camera_controls, delta_time);
    // print("Main camera: %\n", main_camera);
    // print("Main camera position: %\n", main_camera);

    // glUniformMatrix4fv(matrix_id, 1, GL_FALSE, xx *mvp_matrix);
    // glUniformMatrix4fv(matrix_id, 1, GL_FALSE, xx *main_camera.model_view_projection_matrix); // @FIXME mega bug - something is drawing but I don't know what and why
    glUniformMatrix4fv(matrix_id, 1, GL_TRUE, xx *main_camera.model_view_projection_matrix); // @FIXME mega bug - something is drawing but I don't know what and why
    // glUniformMatrix4fv(matrix_id, 1, GL_FALSE, *main_camera.view_projection_matrix.coef[0][0]);

    // End of checking input events
    glClear(GL_COLOR_BUFFER_BIT);

    // Draw two lines
    // @FIXME this is FUCKED UP
    // draw_line(debug_line_x); // This is RED
    // draw_line(debug_line_y); // This is BLUE
    // draw_line(debug_line_z); // This is GREEN

    // @FIXME this loop doesn't work
    // Create array view on x_lines
    // @NOTE It seems like Z axis is squished?
    for line, i: x_lines_view {
      print("Drawing line % nr %\n", line, i);
      draw_line(*x_lines_view[i]);
    }

    for line, i: z_lines_view {
      draw_line(*z_lines_view[i]);
    }

    // Render iso tile
    render_iso_tile(debug_iso_tile);

    SDL_GL_SwapWindow(MAIN_ENGINE_WINDOW);

    frame_end := current_time_monotonic();
    delta_time = cast(float) to_float64_seconds(frame_end - frame_start);

    // DEBUG print
    // print("Delta time: %\n", delta_time);
  }

  // Delete OpenGL stuff
  glDeleteProgram(program_id);
  glDeleteVertexArrays(1, *vertex_array_id);
  // glDeleteVertexArray(1, *line_vao);
}
