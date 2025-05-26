"""Rectangle frame part for Vroomon car simulation."""

import random

import pymunk


def create_box_with_offset(body, size, offset):
    """Create a rectangle shape with a given size and offset from the body's position."""
    width, height = size
    hw, hh = width / 2, height / 2
    # Create vertices relative to the center, then add the offset.
    vertices = [
        (-hw + offset[0], -hh + offset[1]),
        (hw + offset[0], -hh + offset[1]),
        (hw + offset[0], hh + offset[1]),
        (-hw + offset[0], hh + offset[1]),
    ]
    return pymunk.Poly(body, vertices)


class Rectangle:
    """Rectangle frame part of the car."""

    def __init__(self, body, pos):
        """Initialize a rectangle frame part."""
        self.body = body
        self.polygon = create_box_with_offset(body, (10, 5), (pos.x, pos.y))
        self.polygon.density = 1
        self.polygon.color = (random.randrange(256), random.randrange(256), 255, 200)
        self.polygon.filter = pymunk.ShapeFilter(group=1)

    def mutate(self):
        """Mutate the rectangle by changing its color."""
        # Change the color of the rectangle
        self.polygon.color = (random.randrange(256), random.randrange(256), 255, 200)

    @classmethod
    def from_random(cls, body, pos):
        """Create a rectangle with a random position."""
        return cls(body, pos)

    def to_dna(self):
        """Convert the rectangle to DNA format."""
        return {"type": "R"}

    @classmethod
    def from_dna(cls, body, pos):
        """Create a rectangle from DNA."""
        # dna carries type only
        return cls(body, pos)
