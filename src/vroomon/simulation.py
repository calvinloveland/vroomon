import pymunk
import pygame
import pymunk.pygame_util


class Simulation:
    def __init__(self):
        self.space = pymunk.Space()
        self.space.gravity = (0, -1000)

    def score_car(self, car, ground, visualize=False):
        if visualize:
            pygame.init()
            screen = pygame.display.set_mode((600, 600))
            clock = pygame.time.Clock()
            draw_options = pymunk.pygame_util.DrawOptions(screen)
        # Add the car and ground to the simulation
        car.add_to_space(self.space)
        ground.add_ground(self.space)

        # Run the simulation for a few steps
        for _ in range(10):
            self.space.step(0.01)

        if visualize:
            # Draw the simulation
            screen.fill((255, 255, 255))
            self.space.debug_draw(draw_options)
            pygame.display.flip()
            clock.tick(60)
        # Calculate score based on car's position and velocity
        score = car.get_position()[1]  # Y position

        return score
