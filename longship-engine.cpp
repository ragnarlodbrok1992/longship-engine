#define SDL_MAIN_HANDLED


// Pragma workaround so we don't get errors from SDL headers
#pragma warning(push, 0)
#include <SDL2/SDL.h>
#pragma warning(pop)

#include <stdio.h>
#include <cstdint>

#define TILE_HEIGHT 40
#define TILE_WIDTH 40
#define TILESET_HEIGHT 10
#define TILESET_WIDTH 10
#define TILESET_X 100
#define TILESET_Y 100

typedef struct
{
  uint8_t R;
  uint8_t G;
  uint8_t B;
  uint8_t A;
} Color;

typedef struct
{
  int x;
  int y;
} Point;

typedef struct
{
  int id;

  Point nw;
  Point ne;
  Point se;
  Point sw;
} IsoTile;

void RenderLine(SDL_Renderer* renderer, Color color, Point start, Point end)
{
  SDL_SetRenderDrawColor(renderer, color.R, color.G, color.B, color.A);
  SDL_RenderDrawLine(renderer, start.x, start.y, end.x, end.y);
}

// void RenderIsoTile(SDL_Renderer* renderer, Color& color, Point& nw, Point& ne, Point& se, Point& sw)
void RenderIsoTile(SDL_Renderer* renderer, Color& color, IsoTile* iso_tile)
{

  RenderLine(renderer, color, iso_tile->nw, iso_tile->ne);
  RenderLine(renderer, color, iso_tile->ne, iso_tile->se);
  RenderLine(renderer, color, iso_tile->se, iso_tile->sw);
  RenderLine(renderer, color, iso_tile->sw, iso_tile->nw);
}

void RenderIsoTileGrid(SDL_Renderer* renderer, Color& color, IsoTile arr[][TILESET_WIDTH])
{
  for (int x = 0; x < TILESET_WIDTH; x++)
  {
    for (int y = 0; y < TILESET_HEIGHT; y++)
    {
      IsoTile* curr_tile = &arr[x][y];
      RenderIsoTile(renderer, color, curr_tile);
    }
  }
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
  main_window = SDL_CreateWindow("Longship Engine", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 800, 600, SDL_WINDOW_SHOWN);
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
  // static Point start_point = {100, 100};
  // static Point end_point = {200, 200};
  static Color green = {0x00, 0xFF, 0x00, 0xFF};
  static IsoTile iso_tiles[TILESET_HEIGHT][TILESET_WIDTH];

  // Events
  SDL_Event main_event;
  bool quit_engine = false;

  // Engine variables
  const uint32_t frame_rate = 60;
  const uint32_t frame_time = 1000 / frame_rate;

  // Engine stuff initialization
  // Initialize iso_tiles with zeros
  for (int x = 0; x < TILESET_HEIGHT; x++)
  {
    for (int y = 0; y < TILESET_WIDTH; y++)
      {
        IsoTile* curr_tile = &iso_tiles[x][y];
        // printf("x: %d, y: %d\n", x, y);
        // printf("%p\n", curr_tile);

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

  while (!quit_engine)
  {
    // Measure time at beginning of the frame
    uint32_t start_time = SDL_GetTicks();

    while (SDL_PollEvent(&main_event))
    {
      switch (main_event.type)
      {
        case SDL_QUIT:
          {
            quit_engine = true;
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

    // Clear the screen
    SDL_SetRenderDrawColor(main_renderer, 0, 0, 0, 255);
    SDL_RenderClear(main_renderer);
    
    // Render stuff
    RenderIsoTileGrid(main_renderer, green, iso_tiles);

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

