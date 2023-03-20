#import "Basic";
#import "GL";

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

