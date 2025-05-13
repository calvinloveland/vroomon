import random
import pymunk

def create_box_with_offset(body, size, offset):
    width, height = size
    hw, hh = width / 2, height / 2
    # Create vertices relative to the center, then add the offset.
    vertices = [
        (-hw + offset[0], -hh + offset[1]),
        ( hw + offset[0], -hh + offset[1]),
        ( hw + offset[0],  hh + offset[1]),
        (-hw + offset[0],  hh + offset[1]),
    ]
    return pymunk.Poly(body, vertices)

class Rectangle:
    def __init__(self, body, pos):
        self.body = body
        self.polygon = create_box_with_offset(body, (10, 5), (pos.x, pos.y))
        self.polygon.density = 1
        self.polygon.color = (random.randrange(256), random.randrange(256), 255, 200)
        self.polygon.filter = pymunk.ShapeFilter(group=1)