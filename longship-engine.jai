#import "Basic";

#import "Window_Creation";
#import "Input";
#import "Math";
#import "SDL";
#import "GL";

// Engine variables
QUIT := false;
MAIN_ENGINE_WINDOW : *void;

WINDOW_TITLE_BAR : *u8 = "Longship Engine";
WINDOW_WIDTH : s32 = 1024;
WINDOW_HEIGHT : s32 = 768;

X_LINE_COLOR : Vector3 = .{1.0, 0.0, 0.0};
Y_LINE_COLOR : Vector3 = .{0.0, 1.0, 0.0};
Z_LINE_COLOR : Vector3 = .{0.0, 0.0, 1.0};

CameraControls :: struct {
  move_input : Vector3;
  rotate_input : Vector2; // Only rotation around X and Y axis
}

Camera :: struct {
  view_matrix := Matrix4_Identity;
  eye : Vector3 = .{0.0, 0.0, 0.0};
}

CAMERA_CONTROLS : CameraControls;
MAIN_CAMERA : Camera;

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

// Helper function
print_mat4 :: (name: string, mat: Matrix4) {
  print("  [ % ]\n", name);
  print("[%, %, %, %]\n",   mat._11, mat._12, mat._13, mat._14); 
  print("[%, %, %, %]\n",   mat._21, mat._22, mat._23, mat._24); 
  print("[%, %, %, %]\n",   mat._31, mat._32, mat._33, mat._34); 
  print("[%, %, %, %]\n\n", mat._41, mat._42, mat._43, mat._44); 
}

print_vec3 :: (name: string, vec: Vector3) {
  print("  [ % ]\n", name);
  print("[% % %]\n", vec.x, vec.y, vec.z);
}

create_projection_matrix :: (fov: float, aspect_ratio: float, near: float, far: float, delta_time: float) -> Matrix4 {
  view_projection_matrix := Matrix4_Identity;
  projection_matrix := Matrix4_Identity;
  look_at_matrix := Matrix4_Identity;

  // Changing something in view matrix
  // view_matrix._14 = 0.0;
  // view_matrix._24 = 0.0; // Going up Y 10 @BUG Y axis goes down right now
  // view_matrix._34 = -10.0; // Going back Z 100

  MAIN_CAMERA.view_matrix._14 += CAMERA_CONTROLS.move_input.x * delta_time;
  MAIN_CAMERA.view_matrix._24 += CAMERA_CONTROLS.move_input.y * delta_time;
  MAIN_CAMERA.view_matrix._34 += CAMERA_CONTROLS.move_input.z * delta_time;

  /*
  MAIN_CAMERA.view_matrix._13 += CAMERA_CONTROLS.move_input.x * delta_time;
  MAIN_CAMERA.view_matrix._23 += CAMERA_CONTROLS.move_input.y * delta_time;
  MAIN_CAMERA.view_matrix._33 += CAMERA_CONTROLS.move_input.z * delta_time;

  MAIN_CAMERA.view_matrix._12 += CAMERA_CONTROLS.move_input.x * delta_time;
  MAIN_CAMERA.view_matrix._22 += CAMERA_CONTROLS.move_input.y * delta_time;
  MAIN_CAMERA.view_matrix._32 += CAMERA_CONTROLS.move_input.z * delta_time;
  */

  MAIN_CAMERA.eye.x += CAMERA_CONTROLS.move_input.x * delta_time;
  MAIN_CAMERA.eye.y += CAMERA_CONTROLS.move_input.y * delta_time;
  MAIN_CAMERA.eye.z += CAMERA_CONTROLS.move_input.z * delta_time;

  eye : Vector3 = .{MAIN_CAMERA.eye.x, MAIN_CAMERA.eye.y, MAIN_CAMERA.eye.z};
  center : Vector3 = .{0.0, 0.0, 0.0};
  up : Vector3 = .{0.0, 1.0, 0.0};

  // look_at_matrix = make_look_at_matrix(eye, center, up, true);

  // Rotate view matrix
  // euler_angles : Vector3;
  // euler_angles = .{CAMERA_CONTROLS.rotate_input.x * PI / 180, CAMERA_CONTROLS.rotate_input.y * PI / 180, 0.0};
  // view_rotate : Quaternion;

  zaxis : Vector3 = normalize(center - eye);
  xaxis : Vector3 = normalize(cross(zaxis, up));
  yaxis : Vector3 = cross(xaxis, zaxis);

  zaxis = -zaxis;

  // Is it column major or row major?
  // 1s column
  look_at_matrix._11 = xaxis.x;
  look_at_matrix._21 = yaxis.x;
  look_at_matrix._31 = zaxis.x;
  look_at_matrix._41 = 0;

  // 2nd column
  look_at_matrix._12 = xaxis.y;
  look_at_matrix._22 = yaxis.y;
  look_at_matrix._32 = zaxis.y;
  look_at_matrix._42 = 0;

  // 3rd column
  look_at_matrix._13 = xaxis.z;
  look_at_matrix._23 = yaxis.z;
  look_at_matrix._33 = zaxis.z;
  look_at_matrix._43 = 0;
  
  // 4th column
  look_at_matrix._14 = -dot(xaxis, eye);
  look_at_matrix._24 = -dot(yaxis, eye);
  look_at_matrix._34 = -dot(zaxis, eye);
  look_at_matrix._44 = 1;

  // Construction projection matrix
  projection_matrix._11 =  1 / (aspect_ratio * tan(fov / 2));
  projection_matrix._22 =  1 / (tan(fov / 2));
  projection_matrix._33 = -1 * ((far + near)     / (far - near));
  projection_matrix._34 = -1 * ((2 * far * near) / (far - near));
  projection_matrix._43 = -1;

  view_projection_matrix = projection_matrix * look_at_matrix;
  // view_projection_matrix = projection_matrix * MAIN_CAMERA.view_matrix;
  // view_projection_matrix = inverse(look_at_matrix) * projection_matrix;

  // print_mat4("View matrix", MAIN_CAMERA.view_matrix);
  // print_mat4("Projection matrix", projection_matrix);
  print_mat4("View projection matrix", view_projection_matrix);
  // print_mat4("Lookat", look_at_matrix);

  return view_projection_matrix;
}

building_mvp_matrix :: (delta_time: float) -> Matrix4 {
  mvp_matrix := Matrix4_Identity;
  look_at_matrix := Matrix4_Identity;
  projection_matrix := Matrix4_Identity;

  // SOME VALUES FOR NOW
  aspect_ratio := WINDOW_WIDTH / cast(float) WINDOW_HEIGHT;
  fov := 60.0;
  near := 0.1;
  far := 1000.0;

  // Ortho
  left := -10.0;
  right := 10.0;
  top := 10.0;
  bottom := -10.0;

  // Build look-at matrix
  // Up-vector (0, 1.0, 0)
  up : Vector3 = .{0.0, 1.0, 0.0};
  center : Vector3 = .{0.0, 0.0, 0.0};
  eye : Vector3 = .{-10.0, 10.0, 10.0};

  // LookAt RH - maybe use LH if it doesn't work?
  f : Vector3 = normalize(center - eye);
  s : Vector3 = normalize(cross(f, up));
  u : Vector3 = cross(s, f);

  print_vec3("f", f);
  print_vec3("s", s);
  print_vec3("u", u);

  look_at_matrix._11 = s.x;
  look_at_matrix._21 = s.y;
  look_at_matrix._31 = s.z;
  look_at_matrix._12 = u.x;
  look_at_matrix._22 = u.y;
  look_at_matrix._32 = u.z;
  look_at_matrix._13 = -f.x;
  look_at_matrix._23 = -f.y;
  look_at_matrix._33 = -f.z;
  look_at_matrix._14 = -dot(s, eye);
  look_at_matrix._24 = -dot(u, eye);
  look_at_matrix._34 =  dot(f, eye);

  // Projection matrix
  // projection_matrix._11 =  1 / (aspect_ratio * tan(fov / 2));
  // projection_matrix._22 =  1 / (tan(fov / 2));
  // projection_matrix._33 = -1 * ((far + near)     / (far - near));
  // projection_matrix._34 = -1 * ((2 * far * near) / (far - near));
  // projection_matrix._43 = -1;

  tanHalfFovy := tan(fov / 2);

  /*
  projection_matrix._11 = 1 / (aspect_ratio * tanHalfFovy);
  projection_matrix._22 = 1 / tanHalfFovy;
  projection_matrix._33 = far / (near - far);
  projection_matrix._34 = -1;
  projection_matrix._43 = - (far * near) / (far - near);
  projection_matrix._44 = 0;
  */

  /*
  projection_matrix._11 = 1 / (aspect_ratio * tanHalfFovy);
  projection_matrix._22 = 1 /  tanHalfFovy;
  projection_matrix._33 =    -(far + near) / (far - near);
  projection_matrix._34 = -1;
  projection_matrix._43 = (-2 * far * near) / (far - near);
  projection_matrix._44 = 0;
  */

  projection_matrix._11 = 2 / (right - left);
  projection_matrix._22 = 2 / (top - bottom);
  projection_matrix._33 = -2 / (far - near);
  projection_matrix._41 = - (right + left) / (right - left);
  projection_matrix._42 = - (top + bottom) / (top - bottom);
  projection_matrix._43 = - (far + near) / (far - near);

  print_mat4("Look at matrix", look_at_matrix);
  print_mat4("Projection matrix", projection_matrix);
  mvp_matrix = projection_matrix * look_at_matrix;
  // mvp_matrix = look_at_matrix * projection_matrix;

  return mvp_matrix;
}

main :: () {
  // Welcoming messages
  print("Hello, longship-engine!\n");

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
  matrix_id := glGetUniformLocation(program_id, "MVP");

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

  line_spacing := 10.0;

  // X plane lines
  line_spacing_start := -100.0;
  for line, i: x_lines_view {
    populate_line(*x_lines_view[i], .{-100.0, 5.0, line_spacing_start}, .{100.0, 5.0, line_spacing_start}, X_LINE_COLOR, X_LINE_COLOR);
    line_spacing_start += line_spacing;
  }

  line_spacing_start = -100.0;
  for line, i: x_lines_parallel_view {
    populate_line(*x_lines_parallel_view[i], .{line_spacing_start, 0.0, -100.0}, .{line_spacing_start, 0.0, 100.0}, X_LINE_COLOR, X_LINE_COLOR);
    line_spacing_start += line_spacing;
  }

  // Y plane lines
  line_spacing_start = -100.0;
  for line, i: y_lines_view {
    populate_line(*y_lines_view[i], .{line_spacing_start, -100.0, 0.0}, .{line_spacing_start, 100.0, 0.0}, Y_LINE_COLOR, Y_LINE_COLOR);
    line_spacing_start += line_spacing;
  }

  line_spacing_start = -100.0;
  for line, i: y_lines_parallel_view {
    populate_line(*y_lines_parallel_view[i], .{-100.0, line_spacing_start, 0.0}, .{100.0, line_spacing_start, 0.0}, Y_LINE_COLOR, Y_LINE_COLOR);
    line_spacing_start += line_spacing;
  }

  // Z plane lines
  line_spacing_start = -100.0;
  for line, i: z_lines_view {
    populate_line(*z_lines_view[i], .{line_spacing_start, 0.0, -100.0}, .{line_spacing_start, 0.0, 100.0}, Z_LINE_COLOR, Z_LINE_COLOR);
    line_spacing_start += line_spacing;
  }

  line_spacing_start = -100.0;
  for line, i: z_lines_parallel_view {
    populate_line(*z_lines_parallel_view[i], .{0.0, -100.0, line_spacing_start}, .{0.0, 100.0, line_spacing_start}, Z_LINE_COLOR, Z_LINE_COLOR);
    line_spacing_start += line_spacing;
  }

  // Create view projection matrix
  ASPECT_RATIO := WINDOW_WIDTH / cast(float) WINDOW_HEIGHT;

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
        case SDL_KEYUP;
          if event.key.keysym.sym == SDLK_ESCAPE QUIT = true;

          if event.key.keysym.sym == SDLK_a CAMERA_CONTROLS.move_input.x = 0;
          if event.key.keysym.sym == SDLK_s CAMERA_CONTROLS.move_input.y = 0;
          if event.key.keysym.sym == SDLK_d CAMERA_CONTROLS.move_input.x = 0;
          if event.key.keysym.sym == SDLK_q CAMERA_CONTROLS.move_input.z = 0;
          if event.key.keysym.sym == SDLK_w CAMERA_CONTROLS.move_input.y = 0;
          if event.key.keysym.sym == SDLK_e CAMERA_CONTROLS.move_input.z = 0;

        case SDL_KEYDOWN;

          if event.key.keysym.sym == SDLK_a CAMERA_CONTROLS.move_input.x = -1;
          if event.key.keysym.sym == SDLK_s CAMERA_CONTROLS.move_input.y = -1;
          if event.key.keysym.sym == SDLK_d CAMERA_CONTROLS.move_input.x = 1;
          if event.key.keysym.sym == SDLK_q CAMERA_CONTROLS.move_input.z = -1;
          if event.key.keysym.sym == SDLK_w CAMERA_CONTROLS.move_input.y = 1;
          if event.key.keysym.sym == SDLK_e CAMERA_CONTROLS.move_input.z = 1;
      }
    }
    // End of event loop

    // Beggining of simulation/rendering loop
    glViewport(0, 0, xx WINDOW_WIDTH, xx WINDOW_HEIGHT);

    // Shader program
    glUseProgram(program_id);

    // Pass view_projection matrix
    // view_projection_matrix := create_projection_matrix(60.0, ASPECT_RATIO, 0.1, 1000.0, delta_time);
    view_projection_matrix := building_mvp_matrix(delta_time);
    print_mat4("View projection matrix", view_projection_matrix);
    glUniformMatrix4fv(matrix_id, 1, GL_FALSE, xx *view_projection_matrix);

    // Clear screen
    glClear(GL_COLOR_BUFFER_BIT);

    // Render lines
    // draw_line(x_line_debug);
    // draw_line(x_line_debug_z_plus);
    // draw_line(x_line_debug_z_minus);

    
    /*
    for line, i: x_lines_parallel_view {
      draw_line(*x_lines_parallel_view[i]);
    }
    */
    for line, i: y_lines_view {
      draw_line(*y_lines_view[i]);
    }
    for line, i: y_lines_parallel_view {
      draw_line(*y_lines_parallel_view[i]);
    }
    for line, i: x_lines_view {
      draw_line(*x_lines_view[i]);
    }
    /*
    for line, i: z_lines_view {
      draw_line(*z_lines_view[i]);
    }
    for line, i: z_lines_parallel_view {
      draw_line(*z_lines_parallel_view[i]);
    }
    */

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
