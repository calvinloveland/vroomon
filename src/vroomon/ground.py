import pymunk
import random


class Ground:

    def __init__(self):
        def generate_points():
            points = []
            previous = 0
            for i in range(100):
                variation = random.normalvariate(0, 10)
                previous = previous + variation
                points.append((i * 5, previous))
            return points

        self.points = generate_points()

    def add_to_space(self, space):
        # Create a static ground as a line segment.
        static_body = space.static_body
        ground_shape = pymunk.Segment(static_body, (0, 500), (600, 500), 5)
        ground_shape.friction = 1.0
        space.add(ground_shape)
