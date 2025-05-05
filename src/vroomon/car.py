import pymunk
import random


POSSIBLE_FRAME_PARTS = []


class PowertrainPart:
    pass


class Cylinder(PowertrainPart):
    def __init__(self,power):
        self.power = power

    @classmethod
    def from_random(cls,power_mu=1,power_sigma=.25):
        return cls(random.normalvariate(power_mu, power_sigma))



class DriveShaft(PowertrainPart):
    def __init__(self,efficiency):
        self.efficiency = efficiency

    @classmethod
    def from_random(cls, efficiency_mu=.9, efficiency_sigma=.1):
        return cls(random.normalvariate(efficiency_mu, efficiency_sigma))



class GearSet(PowertrainPart):
    def __init__(self, input_ratio, wheel_ratio, output_ratio):
        self.input_ratio = input_ratio
        self.wheel_ratio = wheel_ratio
        self.output_ratio = output_ratio

    @classmethod
    def from_random(cls,inout_mu=1,input_sigma=1,wheel_mu=0.5,wheel_sigma=0.1,output_mu=1,output_sigma=1):
        return cls(
            random.normalvariate(inout_mu, input_sigma),
            random.normalvariate(wheel_mu, wheel_sigma),
            random.normalvariate(output_mu, output_sigma)
        )


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


class Car:
    FRAME_OFFSET = 10
    def build_from_dna(self, dna):
        print(dna)
        self.frame = []
        self.powertrain = []
        self.joints = []
        self.motors = []
        self.body = pymunk.Body() # Main body
        self.body.position = (10,10)
        x = 0
        for frame_part in dna["frame"]:
            if frame_part == "R":
                polygon = create_box_with_offset(self.body, (10, 5), (x, 0))
                polygon.density = 1
                polygon.color = (random.randrange(256), random.randrange(256), 255, 200)
                polygon.filter = pymunk.ShapeFilter(group=1)
                self.frame.append((self.body,polygon))
                x += self.FRAME_OFFSET
            elif frame_part == "W":
                wheel_body = pymunk.Body()
                wheel_body.position = (x, 10)
                circle = pymunk.Circle(wheel_body, 10)
                circle.density = 1
                self.frame.append((wheel_body, circle))
                # Assign the same filter group to avoid collision with the main body
                circle.filter = pymunk.ShapeFilter(group=1)
                circle.friction = 0.5
                # Add pivot joint to the main body
                pivot = pymunk.PivotJoint(self.body, wheel_body, (x, 0), (0, 0))
                pivot.collide_bodies = False
                self.joints.append(pivot)
                # Add a motor to the pivot joint
                motor = pymunk.SimpleMotor(self.body, wheel_body, -5)
                self.motors.append(motor)
            else:
                raise ValueError(f"Unknown frame part: {frame_part}")
        for powertrain_part in dna["powertrain"]:
            if powertrain_part == "C":
                self.powertrain.append(Cylinder.from_random())
            elif powertrain_part == "D":
                self.powertrain.append(DriveShaft.from_random())
            elif powertrain_part == "G":
                self.powertrain.append(GearSet.from_random())
            else:
                raise ValueError(f"Unknown powertrain part: {powertrain_part}")
        if len(self.frame) == 0:
            raise ValueError("Frame must have at least one part")
        if len(self.powertrain) == 0:
            raise ValueError("Powertrain must have at least one part")
        if len(self.frame) != len(self.powertrain):
            raise ValueError("Frame and powertrain must have the same number of parts")

    def __init__(self, dna=None):
        self.frame = []
        self.powertrain = []
        if dna is not None:
            self.build_from_dna(dna)

    def add_to_space(self,space):
        for body, shape in self.frame:
            if body not in space._bodies:
                space.add(body)
            space.add(shape)
        for joint in self.joints:
            space.add(joint)
        for motor in self.motors:
            space.add(motor)

    def get_y_position(self):
        print(self.frame)
        return self.frame[0][0].position.y


