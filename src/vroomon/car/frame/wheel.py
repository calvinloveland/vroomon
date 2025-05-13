import pymunk

class Wheel:
    def __init__(self, body, pos, power, torque):
        self.wheel_body = pymunk.Body()
        self.wheel_body.position = (pos.x, 10)
        self.circle = pymunk.Circle(self.wheel_body, 10)
        self.circle.density = 1
        # Assign the same filter group to avoid collision with the main body
        self.circle.filter = pymunk.ShapeFilter(group=1)
        self.circle.friction = 0.5
        # Add pivot joint to the main body
        self.pivot = pymunk.PivotJoint(body, self.wheel_body, (pos.x, pos.y), (0, 0))
        self.pivot.collide_bodies = False
        # Add a motor to the pivot joint
        rate = -power / 1
        print(f"Rate:{rate}")
        if torque <= 0:
            torque = 0.01
        self.motor = pymunk.SimpleMotor(body, self.wheel_body, rate)
        self.motor.max_force = torque