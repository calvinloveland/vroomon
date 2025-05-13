import pymunk
import random
from collections import namedtuple

from vroomon.car.powertrain.cylinder import Cylinder
from vroomon.car.powertrain.driveshaft import DriveShaft
from vroomon.car.powertrain.gearset import GearSet

from vroomon.car.frame.rectangle import Rectangle
from vroomon.car.frame.wheel import Wheel

Position = namedtuple("Position", ["x", "y"])

class Car:
    FRAME_OFFSET = 10

    def calculate_wheel_power(self,wheel_position):
        i = 0
        current_power = 0
        current_torque = 10000
        for powertrain_item in self.powertrain:
            print(f"Current power {current_power}, torque {current_torque}")
            if isinstance(powertrain_item, Cylinder):
                current_power += powertrain_item.power
            elif isinstance(powertrain_item, DriveShaft):
                current_power *= powertrain_item.efficiency
                current_torque *= powertrain_item.efficiency
            elif isinstance(powertrain_item, GearSet):
                current_power *= powertrain_item.input_ratio
                current_torque /= powertrain_item.input_ratio
                if i == wheel_position:
                    return (current_power * powertrain_item.wheel_proportion, current_torque * powertrain_item.wheel_proportion)
                current_power = current_power - (current_power * powertrain_item.wheel_proportion)
                current_torque = current_torque - (current_torque * powertrain_item.wheel_proportion)

                current_power *= powertrain_item.output_ratio
                current_torque /= powertrain_item.output_ratio
            else:
                raise ValueError(f"Unknown powertrain part: {powertrain_item}")
            if i == wheel_position:
                return (current_power, current_torque)
            i += 1

            
    def build_from_dna(self, dna):
        print(dna)
        self.frame = []
        self.powertrain = []
        self.joints = []
        self.motors = []
        self.body = pymunk.Body() # Main body
        self.body.position = (10,10)
        x = 0
        for powertrain_part in dna["powertrain"]:
            if powertrain_part == "C":
                self.powertrain.append(Cylinder.from_random())
            elif powertrain_part == "D":
                self.powertrain.append(DriveShaft.from_random())
            elif powertrain_part == "G":
                self.powertrain.append(GearSet.from_random())
            else:
                raise ValueError(f"Unknown powertrain part: {powertrain_part}")
        for frame_part in dna["frame"]:
            pos = Position(x, 0)
            if frame_part == "R":
                rectangle = Rectangle(self.body, pos)
                self.frame.append((rectangle.body, rectangle.polygon))
                x += self.FRAME_OFFSET
            elif frame_part == "W":
                wheel_power, wheel_torque = self.calculate_wheel_power(len(self.frame))
                wheel  = Wheel(self.body, pos, wheel_power, wheel_torque)
                wheel_body = wheel.wheel_body
                circle = wheel.circle
                pivot = wheel.pivot
                motor = wheel.motor
                self.frame.append((wheel_body, circle))
                self.joints.append(pivot)
                self.motors.append(motor)
            else:
                raise ValueError(f"Unknown frame part: {frame_part}")
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


