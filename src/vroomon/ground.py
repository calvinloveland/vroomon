import pymunk
import random


class Ground:

    def __init__(self):
        def generate_points():
            points = []
            previous = 200
            for i in range(100):
                variation = random.normalvariate(0, 1+i)
                previous = previous + variation
                points.append((i * 50, previous))
            return points

        self.points = generate_points()

    def add_to_space(self, space):
        # Create a static ground as a line segment.
        static_body = space.static_body
        for i in range(len(self.points) - 1):
            start = self.points[i]
            end = self.points[i + 1]
            ground_shape = pymunk.Segment(static_body, start, end, 5)
            ground_shape.friction = 1.0
            space.add(ground_shape)
