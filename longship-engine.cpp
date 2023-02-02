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

  Point nw; // In isometric it's at the top
  Point ne;
  Point se;
  Point sw;
} IsoTile;

void inline RenderLine(SDL_Renderer* renderer, Camera& camera, Color color, Point start, Point end)
{
  SDL_SetRenderDrawColor(renderer, color.R, color.G, color.B, color.A);
  SDL_RenderDrawLine(renderer,
    start.x + camera.center.x, start.y + camera.center.y,
    end.x + camera.center.x, end.y + camera.center.y);
}

void RenderIsoTile(SDL_Renderer* renderer, Camera& camera, Color& color, IsoTile* iso_tile)
{

  RenderLine(renderer, camera, color, iso_tile->nw, iso_tile->ne);
  RenderLine(renderer, camera, color, iso_tile->ne, iso_tile->se);
  RenderLine(renderer, camera, color, iso_tile->se, iso_tile->sw);
  RenderLine(renderer, camera, color, iso_tile->sw, iso_tile->nw);
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

      if ((curr_tile->nw.x > top_left_x) &&
          (curr_tile->nw.x < bottom_right_x) &&
          (curr_tile->nw.y > top_left_y) &&
          (curr_tile->nw.y < bottom_right_y)) {
        RenderIsoTile(renderer, camera, color, curr_tile);
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

      curr_tile->nw.x = TILESET_X + (TILE_WIDTH * x);
      curr_tile->nw.y = TILESET_Y + (TILE_HEIGHT * y);

      curr_tile->ne.x = TILESET_X + (TILE_WIDTH * x) + TILE_WIDTH;
      curr_tile->ne.y = TILESET_Y + (TILE_HEIGHT * y);

      curr_tile->se.x = TILESET_X + (TILE_WIDTH * x) + TILE_WIDTH;
      curr_tile->se.y = TILESET_Y + (TILE_HEIGHT * y) + TILE_HEIGHT;

      curr_tile->sw.x = TILESET_X + (TILE_WIDTH * x);
      curr_tile->sw.y = TILESET_Y + (TILE_HEIGHT * y) + TILE_HEIGHT;
    }
  }
}

Point TransformGridToIsoPoint(Point& org)
{
  Point ret_point;
  org.x = org.x / TILE_WIDTH;
  org.y = org.y / TILE_HEIGHT;
  ret_point.x = org.x * TILE_WIDTH * 1 + org.y * TILE_HEIGHT * -1;
  ret_point.y = (int)(org.x * 0.5 * TILE_WIDTH) + (int)(org.y * 0.5 * TILE_HEIGHT);
  return ret_point;
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

  // Engine stuff initialization
  // Initialize iso_tiles with zeros
  for (int x = 0; x < TILESET_HEIGHT; x++)
  {
    for (int y = 0; y < TILESET_WIDTH; y++)
      {
        IsoTile* curr_tile = &iso_tiles[x][y];

        curr_tile->nw.x = 0;
        curr_tile->nw.y = 0;

        curr_tile->ne.x = 0;
        curr_tile->ne.y = 0;

        curr_tile->se.x = 0;
        curr_tile->se.y = 0;

        curr_tile->sw.x = 0;
        curr_tile->sw.y = 0;
      }
  }

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
            int x, y;
            Point on_clicked;
            Point on_iso;
            Point on_iso_coords;

            mouse_dragging = true;
            SDL_GetMouseState(&x, &y);
            on_clicked = GetClickedPosition(main_camera, x, y);
            on_iso = GetIsoTileFromClicked(on_clicked.x, on_clicked.y);
            on_iso_coords = GetIsoCoordsFromClicked(on_clicked.x, on_clicked.y);
            // printf("Clicked on_clicked here: (%d, %d)\n", on_clicked.x, on_clicked.y);
            // printf("Clicked on_iso here: (%d, %d)\n", on_iso.x, on_iso.y);
            // printf("Clicked on_iso_coords here: (%d, %d)\n", on_iso_coords.x, on_iso_coords.y);
            break;
          }
        case SDL_MOUSEMOTION:
          {
            if (mouse_dragging)
            {
              // Modify camera values
              main_camera.center.x += main_event.motion.xrel;
              main_camera.center.y += main_event.motion.yrel;
            }
            break;
          }
        case SDL_MOUSEBUTTONUP:
          {
            mouse_dragging = false;
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
  SDL_DestroyWindow(main_window);
  SDL_Quit();

  return 0;
}

