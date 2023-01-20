#define SDL_MAIN_HANDLED

// Pragma workaround so we don't get errors from SDL headers
#pragma warning(push, 0)
#include <SDL2/SDL.h>
#pragma warning(pop)

#include <stdio.h>

int main(int argc, char* argv[])
{
  // Suppres warning for now - we are not going to use argc/argv for now.
  (void) argc;
  (void) argv;

  printf("Hello, Longship Engine!\n");
  printf("Version: pre-alpha\n");

  // Create objects for SDL
  SDL_Window*  main_window  = NULL;
  SDL_Surface* main_surface = NULL;

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

  // Proto main loop :3
  SDL_FillRect(main_surface, NULL, SDL_MapRGB(main_surface->format, 0xFF, 0xFF, 0xFF));
  SDL_UpdateWindowSurface(main_window);

  // Events
  SDL_Event e;
  bool quit_engine = false;
  while (!quit_engine)
  {
    while (SDL_PollEvent(&e))
    {
      if (e.type == SDL_QUIT)
      {
        quit_engine = true;
      }
    }
  }

  // Deinitialize stuff
  SDL_DestroyWindow(main_window);
  SDL_Quit();

  return 0;
}

