#define SDL_MAIN_HANDLED

// Pragma workaround so we don't get errors from SDL headers
#pragma warning(push, 0)
#include <SDL2/SDL.h>
#pragma warning(pop)

#include <stdio.h>

const size_t ISO_TILE_VERTS = 3;


typedef struct {
  SDL_Window* window;
  SDL_Renderer* renderer;
  SDL_Surface* surface;
} Config;


// Figure out how to pass this stuff by reference or a pointer?
Config PrepareSDL()
{
  SDL_Window* window;
  SDL_Renderer* renderer;
  SDL_Surface* surface;

  // SDL Initialization
  if (SDL_Init(SDL_INIT_VIDEO) < 0)
  {
    printf("SDL could not initialize! SDL_Error: %s\n", SDL_GetError());
    // Handle errors in some way
  }

  // Creating window and renderer
  window = SDL_CreateWindow("Render Geometry test",
      SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
      800, 600,
      SDL_WINDOW_SHOWN);
  if (window == NULL)
  {
    printf("Could not initialize window! SDL_Error: %s\n", SDL_GetError());
    // Handle errors in some way
  }

  // Initialize surface
  surface = SDL_GetWindowSurface(window);

  // Initialize renderer
  renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

  // Prepare the config struct
  Config ret_conf;
  ret_conf.window = window;
  ret_conf.renderer = renderer;
  ret_conf.surface = surface;

  return ret_conf;
}

void CleanUp(SDL_Renderer* renderer, SDL_Window* window)
{
  SDL_DestroyRenderer(renderer);
  SDL_DestroyWindow(window);
  SDL_Quit();
}

int main(int argc, char* argv[])
{
  (void) argc;
  (void) argv;

  printf("Test binary for SDL_RenderGeometry function api\n");

  // Create objects for SDL
  Config init_conf;
  SDL_Window*   main_window   = NULL;
  SDL_Surface*  main_surface  = NULL;
  SDL_Renderer* main_renderer = NULL;

  // Some variables for test program
  bool quit = false;
  SDL_Event main_event;

  // DEBUG print
  // printf("Main_window %p\n", main_window);
  // printf("Main_surface %p\n", main_surface);
  // printf("Main_renderer %p\n", main_renderer);

  init_conf = PrepareSDL();
  main_window = init_conf.window;
  main_surface = init_conf.surface;
  main_renderer = init_conf.renderer;

  // Handle errors differently
  // if (prepare_return != 0)
  // {
  //   return prepare_return;
  // }

  printf("SDL initialized\n");

  // Render geometry variables
  SDL_Vertex iso_tile_top[ISO_TILE_VERTS];
  SDL_Vertex iso_tile_bottom[ISO_TILE_VERTS];

  // 1
  iso_tile_top[0].position.x = 200;
  iso_tile_top[0].position.y = 100;
  iso_tile_top[0].color.r = 189;
  iso_tile_top[0].color.g = 183;
  iso_tile_top[0].color.b = 107;
  iso_tile_top[0].color.a = 255;

  // 2 
  iso_tile_top[1].position.x = 300;
  iso_tile_top[1].position.y = 200;
  iso_tile_top[1].color.r = 189;
  iso_tile_top[1].color.g = 183;
  iso_tile_top[1].color.b = 107;
  iso_tile_top[1].color.a = 255;

  // 3 
  iso_tile_top[2].position.x = 100;
  iso_tile_top[2].position.y = 200;
  iso_tile_top[2].color.r = 189;
  iso_tile_top[2].color.g = 183;
  iso_tile_top[2].color.b = 107;
  iso_tile_top[2].color.a = 255;

  // 1
  iso_tile_bottom[0].position.x = 300;
  iso_tile_bottom[0].position.y = 200;
  iso_tile_bottom[0].color.r = 189;
  iso_tile_bottom[0].color.g = 183;
  iso_tile_bottom[0].color.b = 107;
  iso_tile_bottom[0].color.a = 255;

  // 2
  iso_tile_bottom[1].position.x = 100;
  iso_tile_bottom[1].position.y = 200;
  iso_tile_bottom[1].color.r = 189;
  iso_tile_bottom[1].color.g = 183;
  iso_tile_bottom[1].color.b = 107;
  iso_tile_bottom[1].color.a = 255;

  // 3
  iso_tile_bottom[2].position.x = 200;
  iso_tile_bottom[2].position.y = 300;
  iso_tile_bottom[2].color.r = 189;
  iso_tile_bottom[2].color.g = 183;
  iso_tile_bottom[2].color.b = 107;
  iso_tile_bottom[2].color.a = 255;
  
  while (!quit)
  {
    while(SDL_PollEvent(&main_event))
    {
      switch (main_event.type)
      {
        case SDL_QUIT:
          {
            quit = true;
            break;
          }
        case SDL_KEYDOWN:
          {
            if (main_event.key.keysym.sym == SDLK_ESCAPE)
            {
              quit = true;
              break;
            }
          }
      }
    }
    // After event loop - render stuff here
    SDL_SetRenderDrawColor(main_renderer, 0x00, 0x00, 0x00, 0xFF);
    SDL_RenderClear(main_renderer);

    // Test render
    SDL_SetRenderDrawColor(main_renderer, 0xFF, 0xFF, 0xFF, 0xFF);
    SDL_RenderDrawLine(main_renderer, 100, 100, 200, 200);

    // Render geometry here
    SDL_RenderGeometry(main_renderer, NULL, iso_tile_top, 3, NULL, 0);
    SDL_RenderGeometry(main_renderer, NULL, iso_tile_bottom, 3, NULL, 0);

    // Update screen
    SDL_RenderPresent(main_renderer);

  }

  CleanUp(main_renderer, main_window);

  return 0;
}
