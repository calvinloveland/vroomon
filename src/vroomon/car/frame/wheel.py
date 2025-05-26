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
        # Ensure wheel size is always positive to prevent NaN physics
        size = abs(random.normalvariate(10, 5))
        # Add minimum size constraint to prevent extremely small wheels
        size = max(size, 1.0)
        return cls(car_body, pos, power, torque, size)

    def mutate(self):
        """Mutate the wheel by changing its size and power."""
        # Ensure wheel size is always positive to prevent NaN physics
        self.size = abs(random.normalvariate(10, 5))
        # Add minimum size constraint to prevent extremely small wheels
        self.size = max(self.size, 1.0)
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

        # Fix NaN physics: Ensure wheel body has valid mass and moment
        # Calculate mass based on circle area and density
        area = 3.14159 * self.size * self.size  # π * r²
        mass = area * circle.density
        moment = pymunk.moment_for_circle(mass, 0, self.size)

        # Set the body's mass and moment to prevent NaN physics
        wheel_body.mass = mass
        wheel_body.moment = moment

        pivot = pymunk.PivotJoint(
            self.body, wheel_body, (self.pos.x, self.pos.y), (0, 0)
        )
        pivot.collide_bodies = False

        rate = -self.power / self.size
        logger.debug(f"Rate: {rate}")

        # Fix NaN physics issue: ensure minimal torque for zero/low power wheels
        if self.torque <= 0:
            self.torque = 0.01

        # Prevent NaN values by handling zero-power wheels specially
        # The root cause is motors with rate=0 but max_force>0 create unstable physics
        if abs(self.power) < 0.001:  # Essentially zero power
            # For zero-power wheels, don't create a motor at all to prevent NaN physics
            logger.debug(f"Zero-power wheel detected, disabling motor to prevent NaN physics")
            motor = pymunk.SimpleMotor(self.body, wheel_body, 0.0)
            motor.max_force = 0.0  # No force applied
        else:
            # Normal powered wheel
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
