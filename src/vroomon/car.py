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



class Car:

    def build_from_dna(self, dna):
        print(dna)
        self.frame = []
        self.powertrain = []
        x = 0
        for frame_part in dna["frame"]:
            if frame_part == "R":
                body = pymunk.Body()
                body.position = (10, 5+x)
                polygon = pymunk.Poly.create_box(body, (5, 10))
                polygon.density = 1
                polygon.color = (0, 0, 255, 200)
                self.frame.append((body, polygon))
            elif frame_part == "W":
                body = pymunk.Body(1, 1)
                body.position = (0, 0)
                circle = pymunk.Circle(body, 1)
                circle.mass = 1
                self.frame.append((body, circle))
            else:
                raise ValueError(f"Unknown frame part: {frame_part}")
            x += 5
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
            space.add(body, shape)

    def get_y_position(self):
        print(self.frame)
        return self.frame[0][0].position.y


