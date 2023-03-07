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

MAIN_ENGINE_WINDOW : *void;

// Shaders - for now here
VERTEX_SHADER :: #string GLSL
  #version 330 core
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
  #version 330 core

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
ISO_TILE_WIDTH := 100;
ISO_TILE_HEIGHT := 100;
ISO_TILESET_X := 0;
ISO_TILESET_Y := 0;

// @DEBUG
DEGREES := 0;

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

Line :: struct {
  start: Point;
  end: Point;
}

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
  FLY_SPEED :: 1.0;
  ROTATION_SPEED :: 0.3;
  ROTATION_SMOOTHING :: 0.3;

  position : Vector3;
  euler_angles : Vector3;
  rotation : Quaternion;
  rotation_input : Vector2; // I think yaw and pitch - we do not roll here
  fov := 45.0; // For now we stick with normal projection - switching to orthogonal after camera will finally work
  transform := Matrix4_Identity;
  view_matrix := Matrix4_Identity;
  projection_matrix := Matrix4_Identity;
  view_projection_matrix := Matrix4_Identity;
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

update_camera ::(using camera: *Camera, delta_time: float) {
  mouse_delta : Vector2;
  move_input  : Vector3;
  move_speed  : float;

  yaw   : Quaternion;
  pitch : Quaternion;

  if is_camera_active {
    move_speed = FLY_SPEED;
    mouse_delta = xy(xx mouse_delta_x, xx mouse_delta_y); // How mouse delta ends up here?
    // print("Mouse delta: %\n", mouse_delta);

    // Key down
    move_speed *= delta_time;

    // Checking camera controls
    move_input.x = camera_controls.move_input_x;
    move_input.y = camera_controls.move_input_y;
    move_input.z = camera_controls.move_input_z;
  }

  position += move_input * move_speed;

  rotation_input = lerp(rotation_input, mouse_delta, ROTATION_SMOOTHING);
  delta := rotation_input * ROTATION_SPEED;

  euler_angles.x += delta.x * PI / 180.0;
  euler_angles.y += delta.y * PI / 180.0;

  euler_angles.y = clamp(euler_angles.y, -80.0 * PI / 180.0, 80.0 * PI / 180.0);

  set_from_axis_and_angle(*yaw,    0, -1, 0, euler_angles.x);
  set_from_axis_and_angle(*pitch, -1,  0, 0, euler_angles.y);

  rotation = yaw * pitch;

  // Transformers are here
  transform = make_translation_matrix4(position) * rotation_matrix(Matrix4, rotation);
  view_matrix = inverse(transform);
  vx, vy, vw, vh := get_dimensions(MAIN_ENGINE_WINDOW, false);
  aspect_ratio := vw / cast(float) vh;
  projection_matrix = make_projection_matrix(fov * PI / 180.0, aspect_ratio, 0.1, 1000.0);
  view_projection_matrix = projection_matrix * view_matrix;
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

  // Loading shaders
  program_id := load_shaders();

  // Getting MatrixID for MVP
  matrix_id := glGetUniformLocation(program_id, "MVP");

  // Camera
  main_camera : Camera;
  // print("%\n", main_camera);

  // @NOTE checking out if projection is correct
  opm_left   := cast(float) -(WINDOW_WIDTH  / 2);
  opm_right  := cast(float)  (WINDOW_WIDTH  / 2);
  opm_bottom := cast(float) -(WINDOW_HEIGHT / 2);
  opm_top    := cast(float)  (WINDOW_HEIGHT / 2);
  opm_near   := 0.0;
  opm_far    := 10000.0;

  ref_up_x := 0.0;
  ref_up_y := 0.0;
  ref_up_z := 1.0;

  // Time variables
  delta_time := 0.01667;

  // DEBUG
  translate_x := 0.0;
  translate_y := 0.0;
  translate_z := 0.0;

  // Main LongshipEngine loop

  while !QUIT {
    // @TODO adding frame delta time
    frame_start := current_time_monotonic();

    event : SDL_Event;
    while SDL_PollEvent(*event) {
      if event.type == {
        // Mouse events
        case SDL_MOUSEMOTION;
          // print("xrel: %, yrel: %\n", event.motion.xrel, event.motion.yrel);
          mouse_delta_x = event.motion.xrel;
          mouse_delta_y = event.motion.yrel;
        case SDL_QUIT;
          QUIT = true;
        case SDL_KEYUP;
          if event.key.keysym.sym == SDLK_ESCAPE QUIT = true;
          if event.key.keysym.sym == SDLK_a camera_controls.move_input_x = 0.0;
          if event.key.keysym.sym == SDLK_s camera_controls.move_input_z = 0.0;
          if event.key.keysym.sym == SDLK_d camera_controls.move_input_x = 0.0;
          if event.key.keysym.sym == SDLK_q camera_controls.move_input_y = 0.0;
          if event.key.keysym.sym == SDLK_w camera_controls.move_input_z = 0.0;
          if event.key.keysym.sym == SDLK_e camera_controls.move_input_y = 0.0;
        case SDL_KEYDOWN;
          shift_modifier := 1;

          if event.key.keysym.mod == KMOD_LSHIFT then shift_modifier = -1;
          if event.key.keysym.mod == KMOD_RSHIFT then shift_modifier = -1;

          if event.key.keysym.sym == SDLK_a {
            translate_x += 0.01 * shift_modifier;
            print("Translating x!\n");

            if is_camera_active camera_controls.move_input_x = 1.0;
          }
          if event.key.keysym.sym == SDLK_s {
            translate_y += 0.01 * shift_modifier;
            print("Translating y!\n");

            if is_camera_active camera_controls.move_input_z = -1.0;
          }
          if event.key.keysym.sym == SDLK_d {
            translate_z += 0.01 * shift_modifier;
            print("Translating z!\n");

            if is_camera_active camera_controls.move_input_x = -1.0;
          }
          if event.key.keysym.sym == SDLK_q {
            DEGREES += 1 * shift_modifier;
            print("Changing DEGREES!\n");

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
          }

        case SDL_WINDOWEVENT;
          if event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED {
            WINDOW_WIDTH = event.window.data1;
            WINDOW_HEIGHT = event.window.data2;
          }
      }
    }

    // Mouse @TEST
    mouse_delta := xy(xx mouse_delta_x, xx mouse_delta_y);
    // print("Mouse delta %\n", mouse_delta);

    // Rendering shit
    glViewport(0, 0, xx WINDOW_WIDTH, xx WINDOW_HEIGHT);

    // Shader program
    glUseProgram(program_id);

    // Set up camera
    // @TODO check this call where it is in skeletal animation source
    // @TODO steal whole camera structure and maybe update_flying_camera function
    // @NOTE for now leave projections and translation, rest is commented out

    // Old projection code
    op_projection_matrix := orthographic_projection_matrix(opm_left, opm_right, opm_bottom, opm_top, opm_near, opm_far);

    op_model_matrix := Matrix4_Identity;
    op_model_matrix._41 = translate_x;
    op_model_matrix._42 = translate_y;
    op_model_matrix._43 = translate_z;

    mvp_matrix := op_projection_matrix * op_model_matrix;

    // Camera code goes here
    update_camera(*main_camera, delta_time);
    // print("Main camera: %\n", main_camera);


    glUniformMatrix4fv(matrix_id, 1, GL_FALSE, xx *mvp_matrix);
    // glUniformMatrix4fv(matrix_id, 1, GL_FALSE, *main_camera.view_projection_matrix.coef[0][0]);

    // End of checking input events
    glClear(GL_COLOR_BUFFER_BIT);

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
}
