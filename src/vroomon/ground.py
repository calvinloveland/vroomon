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

    def add_to_space(self,space):
        for point in self.points:
            floor = space.
            floor.setFriction(0.5)
            floor.setElasticity(0.5)
            floor.setMass(0)
            floor.setColor((0.5, 0.5, 0.5))
