#define SDL_MAIN_HANDLED

// Pragma workaround so we don't get errors from SDL headers
#pragma warning(push, 0)
#include <SDL2/SDL.h>
#pragma warning(pop)

#include <stdio.h>
#include <cstdint>

#define RESOLUTION_WIDTH 1024
#define RESOLUTION_HEIGHT 768

#define TILE_HEIGHT 20
#define TILE_WIDTH 20
#define TILESET_HEIGHT 1000
#define TILESET_WIDTH 1000
#define TILESET_X 0
#define TILESET_Y 0

typedef struct
{
  uint8_t R;
  uint8_t G;
  uint8_t B;
  uint8_t A;
} Color;

Color BLACK = {0, 0, 0, 255};
Color RED = {255, 0, 0, 255};
Color GREEN = {0, 255, 0, 255};
Color BLUE = {0, 0, 255, 255};
Color KHAKI = {240, 230, 140, 255};
Color DARK_KHAKI = {189, 183, 107, 255};

typedef struct
{
  int x;
  int y;
} Point;

typedef struct
{
  Point start;
  Point end;
} Line;

typedef struct
{
  Point center;
  float zoom;
} Camera;

typedef struct
{
  int id;

  // Point nw; // In isometric it's at the top
  // Point ne;
  // Point se;
  // Point sw;
  // Color not_selected_color;
  // Color selected_color;
  SDL_Vertex  nw;
  SDL_Vertex  ne;
  SDL_Vertex  se;
  SDL_Vertex  sw;

  // New version - SDL_Vertxes - now with color attached!

} IsoTile;

typedef struct
{
  int id;

  Point top_left;
  int width, height, radius;
  bool state;
  const char* label;

  Color off_color;
  Color on_color;

} Button;

Button CreateButton(int id, const char* label, Point top_left, int width, int height)
{
  Button ret_button;

  ret_button.id = id;
  ret_button.label = label;
  ret_button.top_left = top_left;
  ret_button.width = width;
  ret_button.height = height;
  
  ret_button.radius = 10;
  ret_button.state = false;
  ret_button.off_color = RED;
  ret_button.on_color = BLUE;

  return ret_button;
}

void inline RenderButton(SDL_Renderer* renderer, Button& button)
{
  SDL_Rect rect = {button.top_left.x, button.top_left.y, button.width, button.height};
  // Render off_state for now
  SDL_SetRenderDrawColor(renderer, button.off_color.R, button.off_color.G, button.off_color.B, button.off_color.A);
  SDL_RenderFillRect(renderer, &rect);
}

// @note: This can be moved to a single function SDL_RenderDrawLines
// void inline RenderLine(SDL_Renderer* renderer, Camera& camera, Color color, Point start, Point end)
void inline RenderLine(SDL_Renderer* renderer, Camera& camera, SDL_Vertex& start, SDL_Vertex& end)
{
  // @note GREEN for now
  SDL_SetRenderDrawColor(renderer, GREEN.R, GREEN.G, GREEN.B, GREEN.A);
  SDL_RenderDrawLine(renderer,
    start.position.x + camera.center.x, start.position.y + camera.center.y,
    end.position.x + camera.center.x, end.position.y + camera.center.y);
}

void RenderIsoTile(SDL_Renderer* renderer, Camera& camera, IsoTile* iso_tile)
{

  RenderLine(renderer, camera, iso_tile->nw, iso_tile->ne);
  RenderLine(renderer, camera, iso_tile->ne, iso_tile->se);
  RenderLine(renderer, camera, iso_tile->se, iso_tile->sw);
  RenderLine(renderer, camera, iso_tile->sw, iso_tile->nw);


  // After rendering line render inside - one pixel off
  // Render inside polygon
  // some_vertices - pointer to SDL_Vertex
  // SDL_Point
  // @note casting here is implicit
  //SDL_Vertex curr_tile_sdl_vertex[] = {
  //  {{iso_tile->nw.x, iso_tile->nw.y}, {iso_tile->not_selected_color.R, iso_tile->not_selected_color.G, iso_tile->not_selected_color.B, iso_tile->not_selected_color.A}, {0, 0}},
  //  {{iso_tile->ne.x, iso_tile->ne.y}, {iso_tile->not_selected_color.R, iso_tile->not_selected_color.G, iso_tile->not_selected_color.B, iso_tile->not_selected_color.A}, {0, 0}},
  //  {{iso_tile->se.x, iso_tile->se.y}, {iso_tile->not_selected_color.R, iso_tile->not_selected_color.G, iso_tile->not_selected_color.B, iso_tile->not_selected_color.A}, {0, 0}},
  //  {{iso_tile->sw.x, iso_tile->sw.y}, {iso_tile->not_selected_color.R, iso_tile->not_selected_color.G, iso_tile->not_selected_color.B, iso_tile->not_selected_color.A}, {0, 0}}};

  // SDL_SetRenderDrawColor(renderer, iso_tile->not_selected_color.R, iso_tile->not_selected_color.G, iso_tile->not_selected_color.B, iso_tile->not_selected_color.A); // <-- This might not be needed 
  // TODO FIXME ragnar: here is a bug :)
  // @note this needs testing in a different file
  // SDL_RenderGeometry(renderer, NULL, curr_tile_sdl_vertex, 4, NULL, 0);
  
}

void RenderIsoTileGrid(SDL_Renderer* renderer, Camera& camera, Color& color, IsoTile arr[][TILESET_WIDTH])
{
  // @note: Keeping render count for now
  // size_t render_count = 0;
  for (int x = 0; x < TILESET_WIDTH; x++)
  {
    for (int y = 0; y < TILESET_HEIGHT; y++)
    {
      // TODO moliwa @improvement: check if this iso tile should be rendered
      // TODO moliwa: add rendered tiles counter
      IsoTile* curr_tile = &arr[x][y];
      
      int top_left_x = -camera.center.x;
      int top_left_y = -camera.center.y;
      int bottom_right_x = -camera.center.x + RESOLUTION_WIDTH;
      int bottom_right_y = -camera.center.y + RESOLUTION_HEIGHT;

      if ((curr_tile->nw.position.x > top_left_x) &&
          (curr_tile->nw.position.x < bottom_right_x) &&
          (curr_tile->nw.position.y > top_left_y) &&
          (curr_tile->nw.position.y < bottom_right_y)) {
        RenderIsoTile(renderer, camera, curr_tile);
        // render_count++;
      }
    }
  }
  // printf("Render count: %zd\n", render_count);
}

void PopulateIsoTileGrid(IsoTile arr[][TILESET_WIDTH])
{
  // Construct coordinates
  for (int x = 0; x < TILESET_WIDTH; x++)
  {
    for (int y = 0; y < TILESET_HEIGHT; y++)
    {
      IsoTile* curr_tile = &arr[x][y];

      curr_tile->nw.position.x = TILESET_X + (TILE_WIDTH * x);
      curr_tile->nw.position.y = TILESET_Y + (TILE_HEIGHT * y);

      curr_tile->ne.position.x = TILESET_X + (TILE_WIDTH * x) + TILE_WIDTH;
      curr_tile->ne.position.y = TILESET_Y + (TILE_HEIGHT * y);

      curr_tile->se.position.x = TILESET_X + (TILE_WIDTH * x) + TILE_WIDTH;
      curr_tile->se.position.y = TILESET_Y + (TILE_HEIGHT * y) + TILE_HEIGHT;

      curr_tile->sw.position.x = TILESET_X + (TILE_WIDTH * x);
      curr_tile->sw.position.y = TILESET_Y + (TILE_HEIGHT * y) + TILE_HEIGHT;

      // Setting colors - @note move this elsewhere
      // curr_tile->not_selected_color = KHAKI;
      // curr_tile->selected_color = DARK_KHAKI;
    }
  }
}

SDL_Vertex TransformGridToIsoPoint(SDL_Vertex& org)
{
  SDL_Vertex ret_vertex;
  org.position.x = org.position.x / TILE_WIDTH;
  org.position.y = org.position.y / TILE_HEIGHT;
  ret_vertex.position.x = org.position.x * TILE_WIDTH * 1 + org.position.y * TILE_HEIGHT * -1;
  ret_vertex.position.y = (int)(org.position.x * 0.5 * TILE_WIDTH) + (int)(org.position.y * 0.5 * TILE_HEIGHT);
  return ret_vertex;
}

Point GetClickedPosition(Camera& cam, int& click_x, int& click_y)
{
  Point ret_point;
  ret_point.x = click_x - cam.center.x;
  ret_point.y = click_y - cam.center.y;
  return ret_point;
}

Point GetIsoTileFromClicked(int& clicked_pos_x, int& clicked_pos_y)
{
  Point ret_point = {0, 0};

  ret_point.x = (int)((2 * clicked_pos_y + clicked_pos_x) / (2 * TILE_WIDTH));
  ret_point.y = (int)((2 * clicked_pos_y - clicked_pos_x) / (2 * TILE_HEIGHT));

  return ret_point;
}

Point GetIsoCoordsFromClicked(int& clicked_pos_x, int& clicked_pos_y)
{
  Point ret_point = {0, 0};

  ret_point.x = (int)((2 * clicked_pos_y + clicked_pos_x) / (2));
  ret_point.y = (int)((2 * clicked_pos_y - clicked_pos_x) / (2));

  return ret_point;

}

void MakeIsoTileGridIsometric(IsoTile arr[][TILESET_WIDTH])
{
  for (int x = 0; x < TILESET_WIDTH; x++)
  {
    for (int y = 0; y < TILESET_HEIGHT; y++)
    {
      IsoTile* curr_tile = &arr[x][y];
      (void)curr_tile;

      curr_tile->nw = TransformGridToIsoPoint(curr_tile->nw);
      curr_tile->ne = TransformGridToIsoPoint(curr_tile->ne);
      curr_tile->se = TransformGridToIsoPoint(curr_tile->se);
      curr_tile->sw = TransformGridToIsoPoint(curr_tile->sw);
    }
  }
}

int main(int argc, char* argv[])
{
  // Suppres warning for now - we are not going to use argc/argv for now.
  (void) argc;
  (void) argv;

  printf("Hello, Longship Engine!\n");
  printf("Version: pre-alpha\n");

  // Create objects for SDL
  SDL_Window*   main_window   = NULL;
  SDL_Surface*  main_surface  = NULL;
  SDL_Renderer* main_renderer = NULL;

  // Initialize SDL
  if (SDL_Init(SDL_INIT_VIDEO) < 0)
  {
    printf("SDL could not initialize! SDL_Error: %s\n", SDL_GetError());
    return 1;
  }

  // Create window
  main_window = SDL_CreateWindow("Longship Engine",
      SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
      RESOLUTION_WIDTH, RESOLUTION_HEIGHT,
      SDL_WINDOW_SHOWN);
  if (main_window == NULL)
  {
    printf("Could not initialize window! SDL_Error: %s\n", SDL_GetError());
    return 2;
  }

  // Get SDL version
  SDL_version compiled;
  SDL_version linked;

  SDL_VERSION(&compiled);
  SDL_GetVersion(&linked);

  printf("Compiled against SDL ver. %u.%u.%u\n", compiled.major, compiled.minor, compiled.patch);
  printf("Linked against SDL ver. %u.%u.%u\n", linked.major, linked.minor, linked.patch);

  // Initialize surface
  main_surface = SDL_GetWindowSurface(main_window);

  // Initialize renderer
  main_renderer = SDL_CreateRenderer(main_window, -1, SDL_RENDERER_ACCELERATED);

  // Some objects to check rendering
  static Color green = {0x00, 0xFF, 0x00, 0xFF};
  static IsoTile iso_tiles[TILESET_HEIGHT][TILESET_WIDTH];
  static Camera main_camera = { {0, 0}, 1.0};

  // Events
  SDL_Event main_event;
  bool quit_engine = false;

  // Engine variables
  const uint32_t frame_rate = 60;
  const uint32_t frame_time = 1000 / frame_rate;
  static bool mouse_dragging = false;
  static bool mouse_selection = true;

  // Engine stuff initialization
  // Initialize iso_tiles with zeros
  // @note: Maybe we don't have to do this?
  for (int x = 0; x < TILESET_HEIGHT; x++)
  {
    for (int y = 0; y < TILESET_WIDTH; y++)
      {
        IsoTile* curr_tile = &iso_tiles[x][y];

        curr_tile->nw.position.x = 0;
        curr_tile->nw.position.y = 0;

        curr_tile->ne.position.x = 0;
        curr_tile->ne.position.y = 0;

        curr_tile->se.position.x = 0;
        curr_tile->se.position.y = 0;

        curr_tile->sw.position.x = 0;
        curr_tile->sw.position.y = 0;
      }
  }

  // Initialize some debug buttons
  Button test_button = CreateButton(0, "Test button", {100, 100}, 100, 20);

  // IsoTile initialization
  PopulateIsoTileGrid(iso_tiles);
  MakeIsoTileGridIsometric(iso_tiles);

  while (!quit_engine)
  {
    // Measure time at beginning of the frame
    uint32_t start_time = SDL_GetTicks();

    // Event loop
    while (SDL_PollEvent(&main_event))
    {
      switch (main_event.type)
      {
        case SDL_QUIT:
          {
            quit_engine = true;
            break;
          }
        case SDL_MOUSEBUTTONDOWN:
          {
            mouse_dragging = true;
            break;
          }
        case SDL_MOUSEMOTION:
          {
            if (mouse_dragging)
            {
              // Modify camera values
              main_camera.center.x += main_event.motion.xrel;
              main_camera.center.y += main_event.motion.yrel;

              mouse_selection = false;
            }
            break;
          }
        case SDL_MOUSEBUTTONUP:
          {
            if (mouse_selection) {
              mouse_selection = false;

              int x, y;
              Point on_clicked;
              Point on_iso;
              Point on_iso_coords;

              SDL_GetMouseState(&x, &y);
              on_clicked = GetClickedPosition(main_camera, x, y);
              on_iso = GetIsoTileFromClicked(on_clicked.x, on_clicked.y);
              on_iso_coords = GetIsoCoordsFromClicked(on_clicked.x, on_clicked.y);
              printf("Clicked on_clicked here: (%d, %d)\n", on_clicked.x, on_clicked.y);
              printf("Clicked on_iso here: (%d, %d)\n", on_iso.x, on_iso.y);
              printf("Clicked on_iso_coords here: (%d, %d)\n", on_iso_coords.x, on_iso_coords.y);
            }
            mouse_dragging = false;
            mouse_selection = true;
            // printf("Camera is now: (%d, %d)\n", main_camera.center.x, main_camera.center.y);
            break;
          }
        case SDL_KEYDOWN:
          {
            switch (main_event.key.keysym.sym)
            {
              case SDLK_ESCAPE:
                {
                  quit_engine = true;
                  break;
                }
            }
            break;
          }
      }
    }
    // Event loop ends

    // Setting viewport and other stuff
    // SDL_Rect viewport;
    // viewport.x = main_camera.center.x;
    // viewport.y = main_camera.center.y;

    // TEST
    // viewport.w = RESOLUTION_WIDTH;
    // viewport.h = RESOLUTION_HEIGHT;

    // SDL_RenderSetViewport(main_renderer, &viewport);
    // TODO moliwa: viewport automatically selects what is going to be rendered based on top-left
    // of isotile grid @fix
    // Using viewport here is not really the solution

    // Clear the screen
    SDL_SetRenderDrawColor(main_renderer, BLACK.R, BLACK.G, BLACK.B, BLACK.A);
    SDL_RenderClear(main_renderer);
    
    // Render stuff
    RenderIsoTileGrid(main_renderer, main_camera, green, iso_tiles);
    
    // Render UI elements
    RenderButton(main_renderer, test_button);

    // Update screen
    SDL_RenderPresent(main_renderer);

    // Delay to control the frame rate
    // TODO ragnar @improvement: is this a good idea to do just that?
    // check how SDL_Delay works.
    // Better to use SDL_AddTimer @maybe
    // Measure time at the end of frame
    uint32_t end_time = SDL_GetTicks();
    uint32_t remaining_time = frame_time - (end_time - start_time);

    // If there is time - delay
    // TODO ragnar @improvement - some Spectre shit
    if (remaining_time > 0)
    {
      SDL_Delay(remaining_time);
    }
  }

  // Deinitialize stuff
  SDL_DestroyRenderer(main_renderer);
  SDL_DestroyWindow(main_window);
  SDL_Quit();

  return 0;
}

