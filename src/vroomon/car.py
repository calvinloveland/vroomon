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
    def from_random(cls,inout_mu,input_sigma,wheel_mu,wheel_sigma,output_mu,output_sigma):
        return cls(
            random.normalvariate(inout_mu, input_sigma),
            random.normalvariate(wheel_mu, wheel_sigma),
            random.normalvariate(output_mu, output_sigma)
        )



class Car:

    def build_from_dna(self, dna):
        self.frame = []
        self.powertrain = []
        for frame_part in dna["frame"]:
            if frame_part is "PJ":
                self.frame.append(pymunk.PinJoint())
            elif frame_part is "GJ":
                self.frame.append(pymunk.GrooveJoint())
        for powertrain_part in dna["powertrain"]:
            if powertrain_part is "C":
                self.powertrain.append(Cylinder())
            elif powertrain_part is "DS":
                self.powertrain.append(DriveShaft())
            elif powertrain_part is "G":
                self.powertrain.append(GearSet())

    def __init__(self, dna=None):
        self.frame = []
        self.powertrain = []

    def add_to_space(self,space):

