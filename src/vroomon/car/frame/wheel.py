import pymunk
import random
from loguru import logger


class Wheel:
    def __init__(self, body, pos, power, torque, size):
        self.power = power
        self.torque = torque
        self.size = size
        self.body = body
        self.pos = pos
        self.build_wheel()

    @classmethod
    def from_random(cls, car_body, pos, power, torque):
        size = random.normalvariate(10, 5)
        return cls(car_body, pos, power, torque, size)

    def mutate(self):
        self.size = random.normalvariate(10, 5)
        self.build_wheel()

    def build_wheel(self):
        self.wheel_body = pymunk.Body()
        self.wheel_body.position = (self.pos.x, 10)
        self.circle = pymunk.Circle(self.wheel_body, self.size)
        self.circle.density = 1
        # Assign the same filter group to avoid collision with the main body
        self.circle.filter = pymunk.ShapeFilter(group=1)
        self.circle.friction = 0.5
        # Add pivot joint to the main body
        self.pivot = pymunk.PivotJoint(
            self.body, self.wheel_body, (self.pos.x, self.pos.y), (0, 0)
        )
        self.pivot.collide_bodies = False
        # Add a motor to the pivot joint
        # Calculate the rate of the motor given the power and size of the wheel
        rate = -self.power / self.size
        logger.debug(f"Rate: {rate}")
        if self.torque <= 0:
            self.torque = 0.01
        self.motor = pymunk.SimpleMotor(self.body, self.wheel_body, rate)
        self.motor.max_force = self.torque

    def to_dna(self):
        return {
            "type": "W",
            "power": self.power,
            "torque": self.torque,
            "size": self.size,
        }

    @classmethod
    def from_dna(cls, body, pos, dna):
        return cls(body, pos, dna["power"], dna["torque"], dna["size"])
