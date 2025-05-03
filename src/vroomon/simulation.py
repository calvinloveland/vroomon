import pymunk
import pygame
import pymunk.pygame_util


class Simulation:
    def __init__(self):
        self.space = pymunk.Space()
        self.space.gravity = (0, 9.8)

    def score_car(self, car, ground, visualize=False):
        if visualize:
            pygame.init()
            screen = pygame.display.set_mode((600, 600))
            clock = pygame.time.Clock()
            draw_options = pymunk.pygame_util.DrawOptions(screen)
        # Add the car and ground to the simulation
        car.add_to_space(self.space)
        ground.add_to_space(self.space)

        # Run the simulation for a few steps
        running = True
        for _ in range(10000):
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
            if not running:
                break
            
            for i in range(10):
                self.space.step(0.01)

            if visualize:
                screen.fill((255, 255, 255))
                self.space.debug_draw(draw_options)
                pygame.display.flip()
                clock.tick(60)
        # Calculate score based on car's position and velocity
        score = car.get_y_position()  # Y position

        return score
