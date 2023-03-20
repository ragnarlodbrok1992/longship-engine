#import "Math";
#import "Basic";

#import,file "variables.jai";

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

update_flying_camera :: (using camera : *Camera, enable_camera_control: bool, delta_time : float)
{
	move_speed : float;
        move_input := move_input_keyboard;
        mouse_delta := mouse_delta_input;

	if enable_camera_control {
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
