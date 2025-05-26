"""Wheel class for Vroomon car frame parts."""

import random
from dataclasses import dataclass

import pymunk
from loguru import logger


@dataclass
class _WheelPhysics:
    """Physics properties of the wheel."""

    body: pymunk.Body
    circle: pymunk.Circle
    pivot: pymunk.PivotJoint
    motor: pymunk.SimpleMotor


class Wheel:
    """Wheel frame part of the car."""

    SEQUENCE_LENGTH = 3

    def __init__(self, body, pos, power, torque, size):
        """Initialize a wheel frame part."""
        self.power = power
        self.torque = torque
        self.size = size
        self.body = body
        self.pos = pos
        self.build_wheel()

    @classmethod
    def from_random(cls, car_body, pos, power, torque):
        """Create a wheel with a random size."""
        size = random.normalvariate(10, 5)
        return cls(car_body, pos, power, torque, size)

    def mutate(self):
        """Mutate the wheel by changing its size and power."""
        self.size = random.normalvariate(10, 5)
        self.build_wheel()

    def build_wheel(self):
        """Build the wheel body and shape."""
        # build them locally
        wheel_body = pymunk.Body()
        wheel_body.position = (self.pos.x, 10)

        circle = pymunk.Circle(wheel_body, self.size)
        circle.density = 1
        circle.filter = pymunk.ShapeFilter(group=1)
        circle.friction = 0.5

        pivot = pymunk.PivotJoint(
            self.body, wheel_body, (self.pos.x, self.pos.y), (0, 0)
        )
        pivot.collide_bodies = False

        rate = -self.power / self.size
        logger.debug(f"Rate: {rate}")
        if self.torque <= 0:
            self.torque = 0.01

        motor = pymunk.SimpleMotor(self.body, wheel_body, rate)
        motor.max_force = self.torque

        # collapse into one field
        self.physics = _WheelPhysics(wheel_body, circle, pivot, motor)

    # expose the old names as properties
    @property
    def wheel_body(self):
        return self.physics.body

    @property
    def circle(self):
        return self.physics.circle

    @property
    def pivot(self):
        return self.physics.pivot

    @property
    def motor(self):
        return self.physics.motor

    def to_dna(self):
        """Convert the wheel to DNA format."""
        return {
            "type": "W",
            "power": self.power,
            "torque": self.torque,
            "size": self.size,
        }

    @classmethod
    def from_dna(cls, body, pos, dna):
        """Create a wheel from DNA."""
        return cls(body, pos, dna["power"], dna["torque"], dna["size"])
