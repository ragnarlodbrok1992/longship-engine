#define SDL_MAIN_HANDLED

// Pragma workaround so we don't get errors from SDL headers
#pragma warning(push, 0)
#include <SDL2/SDL.h>
#pragma warning(pop)

#include <stdio.h>


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

    // Update screen
    SDL_RenderPresent(main_renderer);

  }

  CleanUp(main_renderer, main_window);

  return 0;
}
