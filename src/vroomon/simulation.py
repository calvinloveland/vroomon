# pylint: disable=no-member
"""Simulation module: run physics-based simulation for cars on ground."""

import pygame
import pymunk
import pymunk.pygame_util


class Simulation:
    """Run physics simulation and score cars."""

    def __init__(self):
        """Initialize the physics space with gravity."""
        self.space = pymunk.Space()
        self.space.gravity = (0, 9.8)

    def score_car(self, car, ground, visualize=False):
        """Simulate a single car and return its vertical score."""
        # handle empty car DNA: no parts
        if not car.frame or not car.powertrain:
            return 0
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
            if visualize:
                for event in pygame.event.get():
                    if event.type == pygame.QUIT:
                        running = False
                if not running:
                    break

            for _ in range(10):
                self.space.step(0.01)

            if visualize:
                screen.fill((255, 255, 255))
                self.space.debug_draw(draw_options)
                pygame.display.flip()
                clock.tick(60)
        # Calculate score based on car's position and velocity
        score = car.get_y_position()  # Y position

        return score

    def score_population(self, cars, ground, visualize=False):
        """Simulate multiple cars and return list of (car, score)."""
        if not cars:
            return []
        # Reset space for this batch simulation
        self.space = pymunk.Space()
        self.space.gravity = (0, 9.8)
        if visualize:
            pygame.init()
            screen = pygame.display.set_mode((600, 600))
            clock = pygame.time.Clock()
            draw_options = pymunk.pygame_util.DrawOptions(screen)
        # Add ground first
        ground.add_to_space(self.space)
        # Add all cars
        for car in cars:
            car.add_to_space(self.space)
        running = True
        # Run simulation steps
        for _ in range(10000):
            if visualize:
                for event in pygame.event.get():
                    if event.type == pygame.QUIT:
                        running = False
                if not running:
                    break
            for _ in range(10):
                self.space.step(0.01)
            if visualize:
                screen.fill((255, 255, 255))
                self.space.debug_draw(draw_options)
                pygame.display.flip()
                clock.tick(60)
        # Collect scores: vertical position of each car
        return [(car, car.get_y_position()) for car in cars]
